# K8s Manifests for Assignment 2

This directory contains all the Kubernetes manifests required for Assignment 2.

## Files Structure

- `namespaces.yaml` - Creates webapp and mysql namespaces
- `secrets.yaml` - ECR pull secrets for both namespaces
- `mysql-pod.yaml` - MySQL pod manifest
- `webapp-pod.yaml` - WebApp pod manifest  
- `mysql-replicaset.yaml` - MySQL ReplicaSet with 3 replicas
- `webapp-replicaset.yaml` - WebApp ReplicaSet with 3 replicas
- `mysql-deployment.yaml` - MySQL Deployment
- `webapp-deployment.yaml` - WebApp Deployment
- `mysql-service.yaml` - MySQL ClusterIP service
- `webapp-service.yaml` - WebApp NodePort service (port 30000)
- `webapp-deployment-v2.yaml` - Updated WebApp deployment for rolling update

## Deployment Order

1. Create namespaces:
   ```bash
   kubectl apply -f namespaces.yaml
   ```

2. Create ECR secrets (update base64 encoded config first):
   ```bash
   kubectl apply -f secrets.yaml
   ```

3. Deploy pods:
   ```bash
   kubectl apply -f mysql-pod.yaml
   kubectl apply -f webapp-pod.yaml
   ```

4. Deploy ReplicaSets:
   ```bash
   kubectl apply -f mysql-replicaset.yaml
   kubectl apply -f webapp-replicaset.yaml
   ```

5. Deploy Deployments:
   ```bash
   kubectl apply -f mysql-deployment.yaml
   kubectl apply -f webapp-deployment.yaml
   ```

6. Deploy Services:
   ```bash
   kubectl apply -f mysql-service.yaml
   kubectl apply -f webapp-service.yaml
   ```

7. For rolling update:
   ```bash
   kubectl apply -f webapp-deployment-v2.yaml
   ```

## Key Configuration Details

- **WebApp**: Listens on port 8080, exposed via NodePort 30000
- **MySQL**: Listens on port 3306, exposed via ClusterIP only
- **Labels**: 
  - MySQL pods: `app: mysql`
  - WebApp pods: `app: webapp` (pods), `app: employees` (ReplicaSet/Deployment)
- **Environment Variables**: Configured for MySQL connection
- **Image Pull**: Uses ECR secrets for private repository access

## Notes

- The webapp pod uses label `app: webapp` while ReplicaSet/Deployment use `app: employees` as required by assignment
- MySQL password is set to "passwors" to match the app.py configuration
- Cross-namespace service communication is configured (webapp -> mysql)
- Rolling update changes image tag to :v2 and color to blue