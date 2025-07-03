# Assignment 2 - 命令参考手册

## 快速命令索引

### 集群管理命令
```bash
# 创建Kind集群
kind create cluster --config=kind-config.yaml --name=clo835-cluster

# 删除Kind集群  
kind delete cluster --name=clo835-cluster

# 获取集群信息
kubectl cluster-info
kubectl cluster-info dump

# 获取节点信息
kubectl get nodes
kubectl get nodes -o wide
kubectl describe node <node-name>
```

### ECR认证命令
```bash
# 获取ECR登录token
aws ecr get-login-password --region us-east-1

# ECR登录
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 039444453392.dkr.ecr.us-east-1.amazonaws.com

# 创建ECR pull secret
kubectl create secret docker-registry ecr-secret \
  --docker-server=039444453392.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --namespace=<namespace>
```

### 命名空间管理
```bash
# 创建命名空间
kubectl create namespace <namespace-name>
kubectl apply -f namespaces.yaml

# 查看命名空间
kubectl get namespaces
kubectl get ns

# 删除命名空间
kubectl delete namespace <namespace-name>
```

### Pod管理命令
```bash
# 部署Pod
kubectl apply -f <pod-manifest.yaml>

# 查看Pod
kubectl get pods
kubectl get pods -n <namespace>
kubectl get pods -A
kubectl get pods -o wide
kubectl get pods --show-labels

# Pod详细信息
kubectl describe pod <pod-name> -n <namespace>

# Pod日志
kubectl logs <pod-name> -n <namespace>
kubectl logs -f <pod-name> -n <namespace>  # 实时日志
kubectl logs --previous <pod-name> -n <namespace>  # 前一个容器的日志

# 进入Pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash
kubectl exec -it <pod-name> -n <namespace> -- sh

# 端口转发
kubectl port-forward -n <namespace> pod/<pod-name> <local-port>:<pod-port>
kubectl port-forward -n <namespace> svc/<service-name> <local-port>:<service-port>

# 删除Pod
kubectl delete pod <pod-name> -n <namespace>
```

### ReplicaSet管理命令
```bash
# 部署ReplicaSet
kubectl apply -f <replicaset-manifest.yaml>

# 查看ReplicaSet
kubectl get rs
kubectl get rs -n <namespace>
kubectl get rs -A

# ReplicaSet详细信息
kubectl describe rs <replicaset-name> -n <namespace>

# 扩缩容ReplicaSet
kubectl scale rs <replicaset-name> --replicas=<number> -n <namespace>

# 删除ReplicaSet
kubectl delete rs <replicaset-name> -n <namespace>
```

### Deployment管理命令
```bash
# 部署Deployment
kubectl apply -f <deployment-manifest.yaml>

# 查看Deployment
kubectl get deployments
kubectl get deploy -n <namespace>
kubectl get deploy -A

# Deployment详细信息
kubectl describe deployment <deployment-name> -n <namespace>

# 扩缩容
kubectl scale deployment <deployment-name> --replicas=<number> -n <namespace>

# 滚动更新
kubectl set image deployment/<deployment-name> <container-name>=<new-image> -n <namespace>
kubectl apply -f <updated-deployment-manifest.yaml>

# 查看滚动更新状态
kubectl rollout status deployment/<deployment-name> -n <namespace>

# 滚动更新历史
kubectl rollout history deployment/<deployment-name> -n <namespace>

# 回滚
kubectl rollout undo deployment/<deployment-name> -n <namespace>
kubectl rollout undo deployment/<deployment-name> --to-revision=<revision-number> -n <namespace>

# 删除Deployment
kubectl delete deployment <deployment-name> -n <namespace>
```

### Service管理命令
```bash
# 部署Service
kubectl apply -f <service-manifest.yaml>

# 查看Service
kubectl get services
kubectl get svc -n <namespace>
kubectl get svc -A
kubectl get svc -o wide

# Service详细信息
kubectl describe svc <service-name> -n <namespace>

# 查看Service endpoints
kubectl get endpoints -n <namespace>
kubectl describe endpoints <service-name> -n <namespace>

# 删除Service
kubectl delete svc <service-name> -n <namespace>
```

### 网络测试命令
```bash
# DNS解析测试
kubectl exec -it <pod-name> -n <namespace> -- nslookup <service-name>
kubectl exec -it <pod-name> -n <namespace> -- nslookup <service-name>.<namespace>.svc.cluster.local

# 网络连通性测试
kubectl exec -it <pod-name> -n <namespace> -- ping <service-name>
kubectl exec -it <pod-name> -n <namespace> -- curl http://<service-name>:<port>

# 端口测试
kubectl exec -it <pod-name> -n <namespace> -- telnet <service-name> <port>
kubectl exec -it <pod-name> -n <namespace> -- nc -zv <service-name> <port>
```

### 故障排除命令
```bash
# 查看事件
kubectl get events
kubectl get events -n <namespace>
kubectl get events --sort-by=.metadata.creationTimestamp

# 查看资源状态
kubectl get all -n <namespace>
kubectl get all -A

# 查看资源使用情况
kubectl top nodes
kubectl top pods -n <namespace>

# 查看集群组件状态
kubectl get componentstatuses
kubectl get pods -n kube-system

# 检查资源配置
kubectl get <resource-type> <resource-name> -n <namespace> -o yaml
kubectl get <resource-type> <resource-name> -n <namespace> -o json

# 验证配置文件
kubectl apply --dry-run=client -f <manifest.yaml>
kubectl apply --dry-run=server -f <manifest.yaml>
```

### 标签和选择器
```bash
# 查看标签
kubectl get pods --show-labels -n <namespace>
kubectl get <resource-type> --show-labels

# 按标签筛选
kubectl get pods -l <label-key>=<label-value> -n <namespace>
kubectl get pods -l app=mysql -n mysql

# 添加标签
kubectl label pod <pod-name> <label-key>=<label-value> -n <namespace>

# 删除标签
kubectl label pod <pod-name> <label-key>- -n <namespace>
```

### 配置和Secret管理
```bash
# 查看Secret
kubectl get secrets -n <namespace>
kubectl describe secret <secret-name> -n <namespace>

# 创建Secret
kubectl create secret generic <secret-name> --from-literal=<key>=<value> -n <namespace>
kubectl create secret docker-registry <secret-name> --docker-server=<server> --docker-username=<username> --docker-password=<password> -n <namespace>

# 查看ConfigMap
kubectl get configmaps -n <namespace>
kubectl describe configmap <configmap-name> -n <namespace>
```

## 一键部署脚本

### 完整部署脚本
```bash
#!/bin/bash

echo "=== Assignment 2 一键部署脚本 ==="

# 1. 创建命名空间
echo "1. 创建命名空间..."
kubectl apply -f k8s-manifests/namespaces.yaml

# 2. 创建ECR secrets
echo "2. 创建ECR认证secrets..."
ECR_TOKEN=$(aws ecr get-login-password --region us-east-1)

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

# 3. 部署Pod
echo "3. 部署Pods..."
kubectl apply -f k8s-manifests/mysql-pod.yaml
kubectl apply -f k8s-manifests/webapp-pod.yaml

# 4. 等待Pod启动
echo "4. 等待Pod启动..."
kubectl wait --for=condition=Ready pod/mysql-pod -n mysql --timeout=300s
kubectl wait --for=condition=Ready pod/webapp-pod -n webapp --timeout=300s

# 5. 部署ReplicaSet
echo "5. 部署ReplicaSets..."
kubectl apply -f k8s-manifests/mysql-replicaset.yaml
kubectl apply -f k8s-manifests/webapp-replicaset.yaml

# 6. 部署Deployment
echo "6. 部署Deployments..."
kubectl apply -f k8s-manifests/mysql-deployment.yaml
kubectl apply -f k8s-manifests/webapp-deployment.yaml

# 7. 部署Service
echo "7. 部署Services..."
kubectl apply -f k8s-manifests/mysql-service.yaml
kubectl apply -f k8s-manifests/webapp-service.yaml

# 8. 显示最终状态
echo "8. 部署完成，显示状态..."
kubectl get all -A

echo "=== 部署完成！==="
echo "WebApp可通过NodePort 30000访问"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
echo "访问地址: http://$NODE_IP:30000"
```

### 一键清理脚本
```bash
#!/bin/bash

echo "=== Assignment 2 一键清理脚本 ==="

# 删除所有资源
kubectl delete -f k8s-manifests/webapp-service.yaml
kubectl delete -f k8s-manifests/mysql-service.yaml
kubectl delete -f k8s-manifests/webapp-deployment.yaml
kubectl delete -f k8s-manifests/mysql-deployment.yaml
kubectl delete -f k8s-manifests/webapp-replicaset.yaml
kubectl delete -f k8s-manifests/mysql-replicaset.yaml
kubectl delete -f k8s-manifests/webapp-pod.yaml
kubectl delete -f k8s-manifests/mysql-pod.yaml

# 删除secrets
kubectl delete secret ecr-secret -n webapp
kubectl delete secret ecr-secret -n mysql

# 删除命名空间
kubectl delete -f k8s-manifests/namespaces.yaml

echo "=== 清理完成！==="
```

## 常用组合命令

### 快速状态检查
```bash
# 一键查看所有资源状态
kubectl get all -A

# 查看特定命名空间的所有资源
kubectl get all -n webapp
kubectl get all -n mysql

# 查看Pod状态和标签
kubectl get pods -A --show-labels

# 查看Service和EndPoint
kubectl get svc,ep -A
```

### 故障诊断组合
```bash
# 快速诊断Pod问题
kubectl get pods -A | grep -v Running
kubectl get events --sort-by=.metadata.creationTimestamp | tail -20

# 检查特定Pod的详细信息
POD_NAME="webapp-pod"
NAMESPACE="webapp"
kubectl describe pod $POD_NAME -n $NAMESPACE
kubectl logs $POD_NAME -n $NAMESPACE
kubectl get events -n $NAMESPACE --field-selector involvedObject.name=$POD_NAME
```

### 网络连通性测试组合
```bash
# 测试Service连接
kubectl run test-pod --image=busybox --rm -it --restart=Never -- /bin/sh
# 在test-pod中执行:
# nslookup mysql-service.mysql.svc.cluster.local
# wget -qO- http://webapp-service.webapp.svc.cluster.local:8080
```

## 演示常用命令序列

### 演示序列1: 基础部署
```bash
kubectl apply -f k8s-manifests/namespaces.yaml
kubectl get ns
kubectl apply -f k8s-manifests/mysql-pod.yaml
kubectl apply -f k8s-manifests/webapp-pod.yaml
kubectl get pods -A
```

### 演示序列2: 扩展部署
```bash
kubectl apply -f k8s-manifests/mysql-replicaset.yaml
kubectl apply -f k8s-manifests/webapp-replicaset.yaml
kubectl get rs -A
kubectl get pods -A --show-labels
```

### 演示序列3: 服务访问
```bash
kubectl apply -f k8s-manifests/mysql-service.yaml
kubectl apply -f k8s-manifests/webapp-service.yaml
kubectl get svc -A
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
curl http://$NODE_IP:30000
```

### 演示序列4: 滚动更新
```bash
kubectl get deployment webapp-deployment -n webapp -o jsonpath='{.spec.template.spec.containers[0].image}'
kubectl apply -f k8s-manifests/webapp-deployment-v2.yaml
kubectl rollout status deployment/webapp-deployment -n webapp
kubectl get pods -n webapp
```