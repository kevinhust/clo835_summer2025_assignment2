# Assignment 2 - 详细部署计划

## 前期准备工作

### 1. 基础设施部署 (使用Terraform - 自动化)
```bash
# 1.1 进入terraform目录
cd terraform

# 1.2 初始化Terraform
terraform init

# 1.3 检查部署计划
terraform plan

# 1.4 部署基础设施
terraform apply
```

**Terraform自动创建的资源**:
- [ ] Amazon EC2实例 (Amazon Linux, 20GB存储)
- [ ] VPC和公有子网
- [ ] 安全组 (SSH, K8s NodePort, API Server)
- [ ] ECR仓库 (webapp, mysql)
- [ ] IAM实例配置文件关联

**EC2 User Data自动安装的组件**:
- [ ] Docker和docker-compose
- [ ] kubectl (最新稳定版)
- [ ] kind (v0.20.0)
- [ ] AWS CLI
- [ ] MySQL客户端
- [ ] Git

### 2. 容器镜像构建 (使用GitHub Actions - 自动化)

**自动触发方式**:
- 代码push到main分支
- Pull request到main分支

**手动触发方式**:
```bash
# 在GitHub网页上：
# 1. 进入Actions标签页
# 2. 选择"Build and Push WebApp and MySQL Docker Images"工作流
# 3. 点击"Run workflow"按钮
# 4. 可选择输入版本标签 (如: v2, latest)
# 5. 点击"Run workflow"开始构建
```

**GitHub Actions自动执行**:
- [ ] 检出代码
- [ ] 配置AWS认证
- [ ] 登录ECR
- [ ] 构建WebApp镜像
- [ ] 构建MySQL镜像  
- [ ] 推送镜像到ECR (latest + 指定版本标签)

## Kind集群部署

### 3. 创建Kind集群
```bash
# 3.1 创建集群配置文件
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