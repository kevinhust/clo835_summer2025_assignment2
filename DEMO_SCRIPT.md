# Assignment 2 - 演示录制脚本

## 录制前准备
- 确保Kind集群已运行
- 准备好所有K8s manifest文件
- 确认ECR镜像已推送
- 测试所有命令可正常执行

---

## 演示脚本 (按Assignment要求顺序)

### 开场白 (30秒)
"大家好，我是[姓名]，今天为大家演示Assignment 2 - 在Kind集群中部署容器化应用。我将按照要求逐步展示K8s资源的部署和管理过程。"

---

### 1. 演示K8s集群运行状态 (2分钟)

**[说明]**: "首先，让我展示本地Kind集群的运行状态，这是一个单节点集群运行在Amazon EC2实例上。"

```bash
# 1.1 显示集群信息
echo "=== 1. 检查K8s集群状态 ==="
kubectl cluster-info

# 1.2 显示节点信息
echo "=== 显示集群节点 - 这是一个单节点集群 ==="
kubectl get nodes -o wide

# 1.3 显示所有系统组件
echo "=== 显示K8s核心组件运行状态 ==="
kubectl get pods -A

# 1.4 获取API Server IP (用于报告)
echo "=== K8s API Server 信息 ==="
kubectl cluster-info | grep "control plane"
```

**[口述]**: "可以看到我们的Kind集群正在正常运行，这是一个单节点集群，所有K8s核心组件包括API Server、etcd、scheduler等都在运行中。API Server的IP地址是[读出显示的IP地址]，这个信息我会在报告中详细说明。"

---

### 2. 部署MySQL和Web应用Pod (3分钟)

**[说明]**: "现在我将在各自的namespace中部署MySQL和Web应用的Pod。"

```bash
# 2.1 创建命名空间
echo "=== 2. 创建命名空间 ==="
kubectl apply -f k8s-manifests/namespaces.yaml
kubectl get namespaces

# 2.2 创建ECR pull secrets
echo "=== 创建ECR认证secrets ==="
# 注意：实际演示时需要替换为真实的ECR token
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

# 2.3 部署MySQL Pod
echo "=== 部署MySQL Pod (标签: app=mysql) ==="
kubectl apply -f k8s-manifests/mysql-pod.yaml
kubectl get pods -n mysql -o wide

# 2.4 部署WebApp Pod  
echo "=== 部署WebApp Pod (标签: app=webapp) ==="
kubectl apply -f k8s-manifests/webapp-pod.yaml
kubectl get pods -n webapp -o wide

# 2.5 等待Pod启动
echo "=== 等待Pod启动完成 ==="
kubectl wait --for=condition=Ready pod/mysql-pod -n mysql --timeout=300s
kubectl wait --for=condition=Ready pod/webapp-pod -n webapp --timeout=300s

# 2.6 显示Pod详细信息
kubectl get pods -A -o wide --show-labels
```

**[口述]**: "我刚刚部署了两个Pod：MySQL pod使用标签'app: mysql'，WebApp pod使用标签'app: webapp'。关于端口问题，这两个应用完全可以在各自的容器内监听相同的端口，因为它们运行在不同的Pod中，拥有独立的网络命名空间，所以不会有端口冲突。"

---

### 3. 测试Pod连接性和日志 (2分钟)

```bash
# 3.1 通过port-forward连接WebApp
echo "=== 3. 测试应用连接性 ==="
kubectl port-forward -n webapp pod/webapp-pod 8080:8080 &
PORT_FORWARD_PID=$!

sleep 5

# 3.2 发送请求到应用
echo "=== 向Web应用发送请求 ==="
curl -s http://localhost:8080/ | head -20

# 3.3 检查应用日志
echo "=== 检查Web应用日志 - 验证请求被记录 ==="
kubectl logs -n webapp webapp-pod | tail -10

# 停止port-forward
kill $PORT_FORWARD_PID 2>/dev/null
```

**[口述]**: "我通过kubectl port-forward连接到Web应用Pod，发送了一个HTTP请求并获得了有效响应。同时可以在应用日志中看到这个请求被记录下来，证明应用正常运行。"

---

### 4. 部署ReplicaSet (3分钟)

**[说明]**: "现在部署ReplicaSet，每个应用3个副本。"

```bash
# 4.1 部署MySQL ReplicaSet
echo "=== 4. 部署MySQL ReplicaSet (标签: app=mysql) ==="
kubectl apply -f k8s-manifests/mysql-replicaset.yaml

# 4.2 部署WebApp ReplicaSet  
echo "=== 部署WebApp ReplicaSet (标签: app=employees) ==="
kubectl apply -f k8s-manifests/webapp-replicaset.yaml

# 4.3 查看ReplicaSet状态
echo "=== 查看ReplicaSet状态 ==="
kubectl get rs -n mysql
kubectl get rs -n webapp

# 4.4 查看Pod变化
echo "=== 查看Pod状态和标签 ==="
kubectl get pods -n mysql --show-labels
kubectl get pods -n webapp --show-labels

# 4.5 验证原始Pod是否被ReplicaSet管理
echo "=== 检查原始Pod是否被ReplicaSet管理 ==="
kubectl describe rs mysql-replicaset -n mysql
echo "---"
kubectl describe rs webapp-replicaset -n webapp
```

**[口述]**: "我部署了两个ReplicaSet：MySQL使用标签'app: mysql'，WebApp使用标签'app: employees'。注意步骤2中创建的原始MySQL pod会被ReplicaSet管理，因为它有匹配的标签'app: mysql'。但是WebApp的原始pod不会被ReplicaSet管理，因为原始pod标签是'app: webapp'而ReplicaSet选择器是'app: employees'，标签不匹配。"

---

### 5. 部署Deployment (2分钟)

```bash
# 5.1 部署MySQL Deployment
echo "=== 5. 部署MySQL Deployment ==="
kubectl apply -f k8s-manifests/mysql-deployment.yaml

# 5.2 部署WebApp Deployment
echo "=== 部署WebApp Deployment ==="
kubectl apply -f k8s-manifests/webapp-deployment.yaml

# 5.3 查看Deployment状态
echo "=== 查看Deployment状态 ==="
kubectl get deployments -A
kubectl get rs -A

# 5.4 检查ReplicaSet关系
echo "=== 检查Deployment创建的ReplicaSet ==="
kubectl get rs -n mysql -o wide
kubectl get rs -n webapp -o wide

# 5.5 描述Deployment详情
kubectl describe deployment mysql-deployment -n mysql | head -20
kubectl describe deployment webapp-deployment -n webapp | head -20
```

**[口述]**: "我部署了Deployment资源，它们使用与步骤3相同的标签选择器。步骤3创建的ReplicaSet不会成为这些Deployment的一部分，因为它们是独立创建的。Deployment会创建自己的ReplicaSet来管理Pod。"

---

### 6. 部署Services并测试访问 (3分钟)

```bash
# 6.1 部署MySQL Service (ClusterIP)
echo "=== 6. 部署MySQL ClusterIP Service ==="
kubectl apply -f k8s-manifests/mysql-service.yaml

# 6.2 部署WebApp Service (NodePort 30000)
echo "=== 部署WebApp NodePort Service (端口30000) ==="
kubectl apply -f k8s-manifests/webapp-service.yaml

# 6.3 查看Service状态
echo "=== 查看Service状态 ==="
kubectl get svc -A

# 6.4 从EC2实例测试NodePort访问
echo "=== 从EC2实例通过curl测试NodePort访问 ==="
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
echo "Node IP: $NODE_IP"
curl -s http://$NODE_IP:30000/ | head -10

# 6.5 在浏览器中演示
echo "=== 浏览器访问演示 ==="
echo "现在我将在浏览器中访问 http://$NODE_IP:30000"
# 这里需要实际在浏览器中演示
```

**[口述]**: "我部署了两个Service：MySQL使用ClusterIP类型，只能在集群内部访问；WebApp使用NodePort类型，在端口30000对外提供服务。现在可以看到通过curl可以成功访问应用，同时我也会在浏览器中演示访问效果。"

---

### 7. 应用版本更新 (2分钟)

```bash
# 7.1 执行滚动更新
echo "=== 7. 执行WebApp滚动更新 ==="
echo "当前镜像版本："
kubectl get deployment webapp-deployment -n webapp -o jsonpath='{.spec.template.spec.containers[0].image}'

echo -e "\n=== 应用新版本 ==="
kubectl apply -f k8s-manifests/webapp-deployment-v2.yaml

# 7.2 监控更新过程
echo "=== 监控滚动更新过程 ==="
kubectl rollout status deployment/webapp-deployment -n webapp

# 7.3 验证新版本
echo "=== 验证新版本部署 ==="
kubectl get deployment webapp-deployment -n webapp -o jsonpath='{.spec.template.spec.containers[0].image}'
echo -e "\n"

# 7.4 查看Pod状态
kubectl get pods -n webapp -o wide

# 7.5 验证新版本应用
echo "=== 测试新版本应用 ==="
curl -s http://$NODE_IP:30000/ | head -10
```

**[口述]**: "我刚刚执行了滚动更新，将WebApp镜像从latest更新到v2版本，同时改变了应用颜色。可以看到Kubernetes自动进行了滚动更新，逐步替换了旧的Pod，整个过程中服务保持可用。"

---

### 8. 服务类型解释 (1分钟)

```bash
# 8.1 显示服务类型差异
echo "=== 8. 不同Service类型的使用原因 ==="
kubectl get svc -A
echo -e "\n=== MySQL Service (ClusterIP) ==="
kubectl describe svc mysql-service -n mysql | head -10
echo -e "\n=== WebApp Service (NodePort) ==="
kubectl describe svc webapp-service -n webapp | head -10
```

**[口述]**: "我们为Web应用和MySQL使用不同的Service类型有明确的原因：MySQL使用ClusterIP类型，因为数据库应该只在集群内部访问，不应该暴露给外部用户，这是安全最佳实践。而Web应用使用NodePort类型，因为用户需要从外部访问Web界面。这种设计遵循了最小权限原则和网络安全原则。"

---

### 9. 总结和清理 (1分钟)

```bash
# 9.1 最终状态检查
echo "=== 9. 最终部署状态总结 ==="
kubectl get all -A

# 9.2 演示结束
echo "=== 演示完成 ==="
echo "所有Assignment 2要求的任务已经完成："
echo "✓ 单节点Kind集群运行正常"
echo "✓ Pod部署成功 (MySQL: app=mysql, WebApp: app=webapp)"  
echo "✓ ReplicaSet部署成功 (MySQL: app=mysql, WebApp: app=employees)"
echo "✓ Deployment部署成功"
echo "✓ Service部署成功 (MySQL: ClusterIP, WebApp: NodePort 30000)"
echo "✓ 应用滚动更新成功"
echo "✓ 应用连接性和日志验证完成"
```

**[口述]**: "演示到此结束。我已经完成了Assignment 2的所有要求：部署了单节点K8s集群，创建了各种K8s资源，演示了应用的连接性和日志记录，执行了滚动更新，并解释了不同Service类型的使用原因。所有的K8s manifest文件都已上传到GitHub仓库，感谢观看。"

---

## 录制要点提醒

### 录制前检查清单
- [ ] 确认所有manifest文件准备就绪
- [ ] 测试所有命令可正常执行
- [ ] 准备好ECR认证token
- [ ] 确认浏览器可以访问NodePort
- [ ] 检查麦克风和录屏软件设置

### 录制技巧
1. **语速适中**: 清晰解释每个步骤的目的
2. **屏幕清晰**: 确保命令和输出清晰可见
3. **时间控制**: 总时长控制在15分钟内
4. **错误处理**: 如果出错，冷静解释并重新执行
5. **关键信息**: 强调Assignment要求的关键点

### 需要重点说明的概念
1. 单节点集群的特点
2. Pod标签策略的差异原因
3. ReplicaSet与独立Pod的关系
4. Deployment与手动创建ReplicaSet的区别
5. Service类型选择的安全考虑
6. 滚动更新的优势

### 报告中需要回答的问题
1. K8s API Server的IP地址
2. 不同Pod是否可以监听相同端口（可以，因为网络命名空间隔离）
3. 原始Pod是否被ReplicaSet管理（MySQL: 是，WebApp: 否，因为标签不匹配）
4. 手动创建的ReplicaSet是否属于Deployment（否，它们是独立资源）
5. 不同Service类型的使用原因（安全性和访问需求）