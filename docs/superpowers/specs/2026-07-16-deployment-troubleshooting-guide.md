# Banking System - Deployment Troubleshooting Guide

**Date:** 2026-07-16  
**Status:** Active  
**Author:** Banking System Team

---

## Overview

This document captures all issues encountered during the deployment of microservices to Azure AKS and their solutions. Use this as a reference when deploying other services.

---

## Issue 1: Spring Cloud Config Server and Eureka Dependencies

### Problem
Services fail to start or have unnecessary dependencies on Config Server and Eureka.

### Symptoms
- Application tries to connect to `localhost:8888` (Config Server)
- Application tries to connect to `localhost:8761` (Eureka)
- Build warnings about missing Spring Cloud components

### Solution
Remove Spring Cloud dependencies and use native Kubernetes solutions.

**Files to modify:**
1. `pom.xml` - Remove:
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-config</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

2. `*Application.java` - Remove:
```java
@RefreshScope
@EnableDiscoveryClient
```

3. `application-prod.yml` - Remove:
```yaml
spring:
  config:
    import: optional:configserver:http://config-server:8888
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

4. Delete `bootstrap.yml`

5. Test files - Remove:
```java
excludeAutoConfiguration = {
    org.springframework.cloud.commons.config.CommonsConfigAutoConfiguration.class
}
@TestPropertySource(properties = {
    "spring.cloud.config.enabled=false",
    "eureka.client.enabled=false"
})
```

### Result
- Smaller Docker images
- Faster startup time
- No dependency on Config Server or Eureka pods

---

## Issue 2: OpenAPI Spec Path in Standalone Repos

### Problem
When migrating from monorepo to standalone repos, the OpenAPI spec path breaks.

### Symptoms
```
io.swagger.v3.parser.exception.ReadContentException: 
Unable to read location `/home/runner/work/account-service/account-service/../docs/openapi/account-service-api.yaml`
```

### Solution
1. Copy OpenAPI spec to standalone repo:
```bash
mkdir -p docs/openapi
cp ../docs/openapi/<service-name>-api.yaml docs/openapi/
```

2. Update `pom.xml` inputSpec path:
```xml
<!-- Before (monorepo) -->
<inputSpec>${project.basedir}/../docs/openapi/account-service-api.yaml</inputSpec>

<!-- After (standalone) -->
<inputSpec>${project.basedir}/docs/openapi/account-service-api.yaml</inputSpec>
```

3. Update Dockerfile to copy docs:
```dockerfile
COPY pom.xml .
COPY docs ./docs
COPY src ./src
```

### Result
- OpenAPI code generation works in standalone repos
- Docker builds succeed

---

## Issue 3: Missing Kubernetes Secrets

### Problem
Pods fail to start with `CreateContainerConfigError` because required secrets don't exist.

### Symptoms
```
container "transaction-service" in pod "transaction-service-xxx" is waiting to start: CreateContainerConfigError
```

### Solution
Create secrets before deployment:

```bash
# ACR Secret
kubectl create secret docker-registry acr-secret \
  --docker-server=acrbankx.azurecr.io \
  --docker-username=$(az acr credential show --name acrbankx --query "username" -o tsv) \
  --docker-password=$(az acr credential show --name acrbankx --query "passwords[0].value" -o tsv) \
  -n bankx

# CosmosDB Secret
MONGO_URI=$(az cosmosdb keys list --name cosmos-bankx --resource-group rg-bankx \
  --type connection-strings --query "connectionStrings[0].connectionString" -o tsv)
kubectl create secret generic cosmos-mongo-secret \
  --from-literal=mongo-uri="$MONGO_URI" \
  -n bankx
```

**Automate in CI/CD:**
```yaml
- name: Deploy to AKS
  run: |
    kubectl get secret acr-secret -n $K8S_NAMESPACE &>/dev/null || \
      kubectl create secret docker-registry acr-secret ...
    kubectl get secret cosmos-mongo-secret -n $K8S_NAMESPACE &>/dev/null || \
      kubectl create secret generic cosmos-mongo-secret ...
```

### Result
- Pods start successfully
- Secrets are created automatically if missing

---

## Issue 4: ImagePullBackOff (ACR Permission)

### Problem
AKS cannot pull Docker images from ACR.

### Symptoms
```
NAME                                   READY   STATUS             RESTARTS   AGE
transaction-service-xxx                 0/1     ImagePullBackOff   0          5m
```

### Solution
Option 1: Attach ACR to AKS (requires Owner role):
```bash
az aks update --resource-group rg-bankx --name aks-bankx --attach-acr acrbankx
```

Option 2: Use imagePullSecrets (works with Contributor role):
```bash
kubectl create secret docker-registry acr-secret \
  --docker-server=acrbankx.azurecr.io \
  --docker-username=... \
  --docker-password=... \
  -n bankx
```

Update deployment.yaml:
```yaml
spec:
  imagePullSecrets:
    - name: acr-secret
```

### Result
- AKS can pull images from ACR
- No need for Owner role on subscription

---

## Issue 5: Pod Not Scheduled (Resource Constraints)

### Problem
Pods remain in `Pending` state because the node doesn't have enough resources.

### Symptoms
```
NAME                                   READY   STATUS    RESTARTS   AGE
transaction-service-xxx                 0/1     Pending   0          10m
```

`kubectl describe pod` shows:
```
Conditions:
  Type           Status
  PodScheduled   False
```

### Solution
1. Reduce resource requests:
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "250m"
```

2. Scale up nodes:
```bash
az aks nodepool scale --resource-group rg-bankx --cluster-name aks-bankx --name nodepool1 --node-count 2
```

### Result
- Pods scheduled successfully
- Minimal resource usage for bootcamp

---

## Issue 6: Kafka Connection Failure

### Problem
Service fails to start because Kafka is not available.

### Symptoms
```
ERROR 2309 --- [account-service] o.springframework.kafka.core.KafkaAdmin: 
Could not configure topics
org.springframework.kafka.KafkaException: Timed out waiting to get existing topics
```

### Solution
Option 1: Make Kafka optional (for bootcamp):
```yaml
spring:
  autoconfigure:
    exclude:
      - org.springframework.boot.autoconfigure.kafka.KafkaAutoConfiguration
      - org.springframework.kafka.core.KafkaAdminAutoConfiguration
```

Option 2: Deploy Kafka to AKS:
```bash
kubectl apply -f k8s/kafka.yaml
```

Update ConfigMap:
```yaml
KAFKA_BOOTSTRAP_SERVERS: "kafka.kafka.svc.cluster.local:9092"
```

### Result
- Service starts without Kafka (Option 1)
- Or Kafka is available in the cluster (Option 2)

---

## Issue 7: CI/CD Pipeline Using Old Code

### Problem
Pipeline `rerun` uses the old code, not the latest commit.

### Symptoms
- Error shows old path (e.g., `../docs/openapi/`)
- New commit with `[skip ci]` doesn't trigger pipeline

### Solution
1. Don't use `[skip ci]` in fix commits
2. Create empty commit to trigger pipeline:
```bash
git commit --allow-empty -m "chore: trigger CI/CD pipeline"
git push origin main
```

### Result
- Pipeline runs with latest code
- Fixes are deployed

---

## Issue 8: Namespace Not Found

### Problem
Deployment fails because the Kubernetes namespace doesn't exist.

### Symptoms
```
Error from server (NotFound): deployments.apps "transaction-service" not found
```

### Solution
Ensure namespace exists before deployment:
```bash
kubectl create namespace $K8S_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
```

Add namespace to all manifests:
```yaml
metadata:
  name: ${SERVICE_NAME}
  namespace: ${K8S_NAMESPACE}
```

### Result
- Deployments succeed in correct namespace
- All resources are properly scoped

---

## Issue 9: Wrong Image Name in Deployment

### Problem
Deployment uses incorrect image name (missing ACR prefix).

### Symptoms
```
Warning  Failed  failed to pull image "docker.io/library/account-service:latest": 
repository does not exist or may require authorization
```

### Solution
Ensure deployment.yaml uses the `DOCKER_IMAGE` variable:

```yaml
containers:
  - name: ${SERVICE_NAME}
    image: ${DOCKER_IMAGE}  # Must be acrbankx.azurecr.io/service-name:latest
```

CI/CD pipeline sets:
```yaml
export DOCKER_IMAGE=${{ env.DOCKER_IMAGE }}:latest
# Result: acrbankx.azurecr.io/account-service:latest
```

### Result
- AKS pulls from correct ACR registry
- ImagePullBackOff resolved

---

## Issue 10: Kafka Connection Timeout

### Problem
Kafka broker unreachable when using ExternalName service across namespaces.

### Symptoms
```
Connection to node -1 (kafka/10.0.200.240:9092) could not be established
```

### Solution
Deploy Kafka directly in the same namespace as the services:

```yaml
# kafka-bankx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kafka
  namespace: bankx  # Same namespace as services
```

### Result
- DNS resolution works correctly
- Services connect to Kafka directly

---

## Issue 11: Redis Not Found

### Problem
Redis not deployed in the cluster.

### Symptoms
```
Failed to resolve 'redis' [A(1)]
```

### Solution
Deploy Redis in the same namespace:

```yaml
# redis-bankx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: bankx
```

### Result
- Redis available at `redis:6379`
- Caching enabled

---

## Quick Reference: Deployment Checklist

For each microservice, ensure:

- [ ] Spring Cloud dependencies removed from `pom.xml`
- [ ] `@RefreshScope` removed from Application class
- [ ] `application-prod.yml` created (no Config Server/Eureka)
- [ ] `bootstrap.yml` deleted
- [ ] Test files updated (no Spring Cloud references)
- [ ] OpenAPI spec copied to `docs/openapi/`
- [ ] `pom.xml` inputSpec path updated
- [ ] Dockerfile copies `docs/` folder
- [ ] K8s manifests created (deployment, service, configmap)
- [ ] CI/CD pipeline configured
- [ ] GitHub repo created and secrets configured

---

## Service Configuration Reference

| Service | Port | Database | Kafka | Redis |
|---------|------|----------|-------|-------|
| account-service | 8082 | account_db | Yes | Yes |
| credit-service | 8083 | credit_db | Yes | Yes |
| transaction-service | 8084 | transaction_db | Yes | No |
| fraud-detection-service | 8085 | fraud_detection_db | Yes | No |
| auth-service | 8086 | auth_db | No | No |
| yanki-service | 8088 | yanki_db | Yes | No |
| customer-service | 8089 | customer_db | No | Yes |

---

## Infrastructure Components

| Component | Status | Namespace |
|-----------|--------|-----------|
| AKS Cluster | ✅ Deployed | - |
| ACR | ✅ Deployed | - |
| CosmosDB | ✅ Deployed | - |
| Kafka | ✅ Deployed | kafka |
| APIM | ❌ Not deployed | - |
| Config Server | ❌ Not needed | - |
| Eureka | ❌ Not needed | - |

---

## Next Steps

1. Deploy remaining microservices using this guide
2. Configure APIM for production routing
3. Set up monitoring and logging
4. Implement inter-service communication
