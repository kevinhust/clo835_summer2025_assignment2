# Assignment 2 - 详细部署计划

## 前期准备工作

### 1. 基础设施部署 (使用Terraform - 不包含在提交中)
- [ ] 部署Amazon EC2实例 (Amazon Linux)
- [ ] 配置VPC和安全组
- [ ] 创建ECR仓库

### 2. EC2实例配置
```bash
# 2.1 更新系统
sudo yum update -y

# 2.2 安装Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# 2.3 安装kubectl
curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.1/2023-04-19/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin

# 2.4 安装kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin

# 2.5 安装AWS CLI (如果需要)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### 3. ECR认证和镜像推送
```bash
# 3.1 ECR登录
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 039444453392.dkr.ecr.us-east-1.amazonaws.com

# 3.2 构建并推送镜像
# WebApp镜像
docker build -t clo835ecr-webapp .
docker tag clo835ecr-webapp:latest 039444453392.dkr.ecr.us-east-1.amazonaws.com/clo835ecr-webapp:latest
docker tag clo835ecr-webapp:latest 039444453392.dkr.ecr.us-east-1.amazonaws.com/clo835ecr-webapp:v2
docker push 039444453392.dkr.ecr.us-east-1.amazonaws.com/clo835ecr-webapp:latest
docker push 039444453392.dkr.ecr.us-east-1.amazonaws.com/clo835ecr-webapp:v2

# MySQL镜像
docker build -f Dockerfile_mysql -t clo835ecr-mysql .
docker tag clo835ecr-mysql:latest 039444453392.dkr.ecr.us-east-1.amazonaws.com/clo835ecr-mysql:latest
docker push 039444453392.dkr.ecr.us-east-1.amazonaws.com/clo835ecr-mysql:latest
```

## Kind集群部署

### 4. 创建Kind集群
```bash
# 4.1 创建集群配置文件
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
EOF

# 4.2 创建集群
kind create cluster --config=kind-config.yaml --name=clo835-cluster

# 4.3 验证集群状态
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```

### 5. 配置ECR认证Secret
```bash
# 5.1 获取ECR认证token
ECR_TOKEN=$(aws ecr get-login-password --region us-east-1)

# 5.2 创建Docker config JSON
kubectl create secret docker-registry ecr-secret \
  --docker-server=039444453392.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$ECR_TOKEN \
  --namespace=default

# 注意: 需要在创建namespace后为每个namespace创建secret
```

## Kubernetes资源部署

### 6. 分阶段部署序列

#### 第一阶段: 基础设置
```bash
# 6.1 创建命名空间
kubectl apply -f k8s-manifests/namespaces.yaml

# 6.2 为每个命名空间创建ECR secret
kubectl create secret docker-registry ecr-secret \
  --docker-server=039444453392.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$ECR_TOKEN \
  --namespace=webapp

kubectl create secret docker-registry ecr-secret \
  --docker-server=039444453392.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$ECR_TOKEN \
  --namespace=mysql
```

#### 第二阶段: Pod部署
```bash
# 6.3 部署MySQL Pod
kubectl apply -f k8s-manifests/mysql-pod.yaml

# 6.4 部署WebApp Pod  
kubectl apply -f k8s-manifests/webapp-pod.yaml

# 6.5 验证Pod状态
kubectl get pods -n mysql
kubectl get pods -n webapp
```

#### 第三阶段: ReplicaSet部署
```bash
# 6.6 部署MySQL ReplicaSet
kubectl apply -f k8s-manifests/mysql-replicaset.yaml

# 6.7 部署WebApp ReplicaSet
kubectl apply -f k8s-manifests/webapp-replicaset.yaml

# 6.8 验证ReplicaSet状态
kubectl get rs -n mysql
kubectl get rs -n webapp
kubectl get pods -n mysql --show-labels
kubectl get pods -n webapp --show-labels
```

#### 第四阶段: Deployment部署
```bash
# 6.9 部署MySQL Deployment
kubectl apply -f k8s-manifests/mysql-deployment.yaml

# 6.10 部署WebApp Deployment
kubectl apply -f k8s-manifests/webapp-deployment.yaml

# 6.11 验证Deployment状态
kubectl get deployments -n mysql
kubectl get deployments -n webapp
kubectl get rs -n mysql
kubectl get rs -n webapp
```

#### 第五阶段: Service部署
```bash
# 6.12 部署MySQL Service (ClusterIP)
kubectl apply -f k8s-manifests/mysql-service.yaml

# 6.13 部署WebApp Service (NodePort)
kubectl apply -f k8s-manifests/webapp-service.yaml

# 6.14 验证Service状态
kubectl get svc -n mysql
kubectl get svc -n webapp
kubectl get svc -n webapp -o wide
```

### 7. 应用更新 (Rolling Update)
```bash
# 7.1 执行滚动更新
kubectl apply -f k8s-manifests/webapp-deployment-v2.yaml

# 7.2 监控更新过程
kubectl rollout status deployment/webapp-deployment -n webapp
kubectl get pods -n webapp -w

# 7.3 验证新版本
kubectl describe deployment webapp-deployment -n webapp
kubectl get pods -n webapp -o jsonpath='{.items[*].spec.containers[*].image}'
```

## 验证和测试

### 8. 功能验证
```bash
# 8.1 检查应用连接性
kubectl port-forward -n webapp svc/webapp-service 8080:8080 &
curl http://localhost:8080

# 8.2 通过NodePort访问
curl http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'):30000

# 8.3 检查应用日志
kubectl logs -n webapp -l app=employees
kubectl logs -n mysql -l app=mysql

# 8.4 数据库连接测试
kubectl exec -it -n webapp deployment/webapp-deployment -- curl http://localhost:8080
```

### 9. 故障排除命令
```bash
# 9.1 诊断命令
kubectl get events -n webapp
kubectl get events -n mysql
kubectl describe pod <pod-name> -n <namespace>

# 9.2 网络测试
kubectl exec -it -n webapp <webapp-pod> -- ping mysql-service.mysql.svc.cluster.local
kubectl exec -it -n webapp <webapp-pod> -- nslookup mysql-service.mysql.svc.cluster.local

# 9.3 清理资源
kubectl delete -f k8s-manifests/
kind delete cluster --name=clo835-cluster
```

## 检查清单

### 部署前检查
- [ ] EC2实例运行正常
- [ ] Docker服务启动
- [ ] kubectl和kind已安装
- [ ] ECR仓库已创建并包含镜像
- [ ] AWS credentials配置正确

### 部署后验证
- [ ] Kind集群运行正常
- [ ] 所有命名空间已创建
- [ ] ECR secrets已配置
- [ ] 所有Pod处于Running状态
- [ ] ReplicaSet管理正确数量的Pod
- [ ] Deployment创建了ReplicaSet
- [ ] Service可以访问Pod
- [ ] NodePort 30000可以从外部访问
- [ ] 应用可以连接MySQL数据库
- [ ] 滚动更新成功完成

### 常见问题和解决方案
1. **ECR认证失败**: 检查AWS credentials和ECR token
2. **Pod启动失败**: 检查镜像名称和imagePullSecret
3. **数据库连接失败**: 验证环境变量和Service配置
4. **NodePort无法访问**: 检查Kind集群端口映射配置