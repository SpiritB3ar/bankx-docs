# Microservice Deployment Playbook

**Date:** 2026-07-16  
**Status:** Ready  
**Purpose:** Step-by-step guide to deploy any microservice to AKS

---

## Pre-Deployment Checklist

Before starting, ensure:
- [ ] AKS cluster is running (`aks-bankx`)
- [ ] ACR is attached to AKS
- [ ] CosmosDB is provisioned
- [ ] Kafka is deployed (if service needs it)
- [ ] Secrets exist in `bankx` namespace (acr-secret, cosmos-mongo-secret)

---

## Step-by-Step Deployment Guide

### Step 1: Prepare Source Code

#### 1.1 Remove Spring Cloud Dependencies

**File: `pom.xml`**

Remove these dependencies:
```xml
<!-- REMOVE -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-config</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

#### 1.2 Update Application Class

**File: `src/main/java/com/bank/*/[Service]Application.java`**

Remove annotations:
```java
// REMOVE
@RefreshScope
@EnableDiscoveryClient
```

Keep:
```java
@SpringBootApplication
@EnableCaching  // If using Redis
```

#### 1.3 Create application-prod.yml

**File: `src/main/resources/application-prod.yml`**

```yaml
server:
  address: 0.0.0.0
  port: ${SERVER_PORT:<PORT>}

spring:
  autoconfigure:
    exclude:
      - org.springframework.boot.autoconfigure.kafka.KafkaAutoConfiguration
      - org.springframework.kafka.core.KafkaAdminAutoConfiguration
  data:
    mongodb:
      uri: ${MONGODB_URI}
      database: ${SPRING_DATA_MONGODB_DATABASE:<DB_NAME>}
    redis:
      host: ${REDIS_HOST:localhost}
      port: ${REDIS_PORT:6379}
  cache:
    type: redis
    redis:
      time-to-live: 600000
      cache-null-values: false
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
    consumer:
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
      properties:
        spring.json.trusted.packages: "*"

springdoc:
  api-docs:
    path: /api-docs
  swagger-ui:
    path: /swagger-ui.html

management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: always

logging:
  level:
    com.bank.<service>: INFO
    org.springframework: WARN

resilience4j:
  circuitbreaker:
    instances:
      default:
        sliding-window-size: 10
        failure-rate-threshold: 50
        wait-duration-in-open-state: 10s
        permitted-number-of-calls-in-half-open-state: 5
  timelimiter:
    instances:
      default:
        timeout-duration: 2s
```

#### 1.4 Delete bootstrap.yml

```bash
rm src/main/resources/bootstrap.yml
```

#### 1.5 Update Test Files

**File: `src/test/java/**/*Test.java`**

Replace:
```java
@WebFluxTest(controllers = [Controller].class, excludeAutoConfiguration = {
    org.springframework.cloud.commons.config.CommonsConfigAutoConfiguration.class
})
@TestPropertySource(properties = {
    "spring.cloud.config.enabled=false",
    "spring.cloud.config.import-check.enabled=false",
    "eureka.client.enabled=false"
})
```

With:
```java
@WebFluxTest(controllers = [Controller].class)
@TestPropertySource(properties = {
    "spring.data.mongodb.uri=mongodb://localhost:27017/test"
})
```

---

### Step 2: Fix OpenAPI Spec Path

#### 2.1 Copy OpenAPI Spec

```bash
mkdir -p docs/openapi
cp ../docs/openapi/<service-name>-api.yaml docs/openapi/
```

#### 2.2 Update pom.xml

Find and replace inputSpec path:
```xml
<!-- BEFORE -->
<inputSpec>${project.basedir}/../docs/openapi/<service-name>-api.yaml</inputSpec>

<!-- AFTER -->
<inputSpec>${project.basedir}/docs/openapi/<service-name>-api.yaml</inputSpec>
```

---

### Step 3: Create Dockerfile

**File: `Dockerfile`**

```dockerfile
# Multi-stage build for <Service Name>
FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app
COPY pom.xml .
COPY docs ./docs
COPY src ./src
RUN apk add --no-cache maven && \
    mvn clean package -DskipTests -B

FROM eclipse-temurin:17-jre-alpine
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
USER appuser
EXPOSE <PORT>
HEALTHCHECK --interval=30s --timeout=3s \
    CMD wget -qO- http://localhost:<PORT>/actuator/health || exit 1
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Important:** Include `COPY docs ./docs` to make OpenAPI spec available during build.

---

### Step 4: Create Kubernetes Manifests

#### 4.1 Create configmap.yaml

**File: `k8s/configmap.yaml`**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${SERVICE_NAME}-config
  namespace: ${K8S_NAMESPACE}
  labels:
    app: ${SERVICE_NAME}
data:
  SERVER_PORT: "${SERVICE_PORT}"
  SPRING_PROFILES_ACTIVE: "prod"
  REDIS_HOST: "redis"
  REDIS_PORT: "6379"
  KAFKA_BOOTSTRAP_SERVERS: "kafka:9092"
```

**Important:** Use `kafka:9092` (ExternalName service), NOT `kafka.kafka.svc.cluster.local:9092`.

#### 4.2 Create deployment.yaml

**File: `k8s/deployment.yaml`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${SERVICE_NAME}
  namespace: ${K8S_NAMESPACE}
  labels:
    app: ${SERVICE_NAME}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${SERVICE_NAME}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: ${SERVICE_NAME}
    spec:
      imagePullSecrets:
        - name: acr-secret
      containers:
        - name: ${SERVICE_NAME}
          image: ${DOCKER_IMAGE}
          imagePullPolicy: Always
          ports:
            - containerPort: ${SERVICE_PORT}
          envFrom:
            - configMapRef:
                name: ${SERVICE_NAME}-config
          env:
            - name: MONGODB_URI
              valueFrom:
                secretKeyRef:
                  name: cosmos-mongo-secret
                  key: mongo-uri
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "250m"
          livenessProbe:
            httpGet:
              path: /actuator/health
              port: ${SERVICE_PORT}
            initialDelaySeconds: 90
            periodSeconds: 15
          readinessProbe:
            httpGet:
              path: /actuator/health
              port: ${SERVICE_PORT}
            initialDelaySeconds: 60
            periodSeconds: 10
```

**Important:** Use `${DOCKER_IMAGE}` variable, not hardcoded image name.

#### 4.3 Create service.yaml

**File: `k8s/service.yaml`**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ${SERVICE_NAME}
  namespace: ${K8S_NAMESPACE}
  labels:
    app: ${SERVICE_NAME}
spec:
  type: LoadBalancer
  selector:
    app: ${SERVICE_NAME}
  ports:
    - name: http
      port: 80
      targetPort: ${SERVICE_PORT}
```

---

### Step 5: Create CI/CD Pipeline

**File: `.github/workflows/ci-cd.yml`**

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  ACR_NAME: acrbankx
  ACR_LOGIN_SERVER: acrbankx.azurecr.io
  DOCKER_IMAGE: acrbankx.azurecr.io/${{ github.event.repository.name }}
  AKS_RESOURCE_GROUP: rg-bankx
  AKS_CLUSTER_NAME: aks-bankx
  K8S_NAMESPACE: bankx
  SERVICE_PORT: <PORT>

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: maven

      - name: Build with Maven
        run: mvn clean package -DskipTests -B

      - name: Run Tests
        run: mvn test -B

      - name: Build Docker image
        run: |
          docker build -t $DOCKER_IMAGE:${{ github.sha }} .
          docker tag $DOCKER_IMAGE:${{ github.sha }} $DOCKER_IMAGE:latest

      - name: Login to ACR
        if: github.ref == 'refs/heads/main'
        uses: azure/docker-login@v1
        with:
          login-server: ${{ env.ACR_LOGIN_SERVER }}
          username: ${{ secrets.ACR_USERNAME }}
          password: ${{ secrets.ACR_PASSWORD }}

      - name: Push to ACR
        if: github.ref == 'refs/heads/main'
        run: |
          docker push $DOCKER_IMAGE:${{ github.sha }}
          docker push $DOCKER_IMAGE:latest

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Set AKS context
        uses: azure/aks-set-context@v3
        with:
          resource-group: ${{ env.AKS_RESOURCE_GROUP }}
          cluster-name: ${{ env.AKS_CLUSTER_NAME }}

      - name: Create/Update Cosmos DB Collection
        run: |
          az cosmosdb mongodb database create \
            --account-name cosmos-bankx \
            --resource-group ${{ env.AKS_RESOURCE_GROUP }} \
            --name ${{ github.event.repository.name }} \
            --throughput 400 || true

      - name: Deploy to AKS
        run: |
          kubectl create namespace $K8S_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
          
          kubectl get secret acr-secret -n $K8S_NAMESPACE &>/dev/null || \
            kubectl create secret docker-registry acr-secret \
              --docker-server=$ACR_LOGIN_SERVER \
              --docker-username=${{ secrets.ACR_USERNAME }} \
              --docker-password=${{ secrets.ACR_PASSWORD }} \
              -n $K8S_NAMESPACE
          
          kubectl get secret cosmos-mongo-secret -n $K8S_NAMESPACE &>/dev/null || \
            kubectl create secret generic cosmos-mongo-secret \
              --from-literal=mongo-uri="$(az cosmosdb keys list --name cosmos-bankx --resource-group ${{ env.AKS_RESOURCE_GROUP }} --type connection-strings --query 'connectionStrings[0].connectionString' -o tsv)" \
              -n $K8S_NAMESPACE
          
          export SERVICE_NAME=${{ github.event.repository.name }}
          export DOCKER_IMAGE=${{ env.DOCKER_IMAGE }}:latest
          export SERVICE_PORT=${{ env.SERVICE_PORT }}
          export K8S_NAMESPACE=${{ env.K8S_NAMESPACE }}
          
          envsubst < k8s/configmap.yaml | kubectl apply -f -
          envsubst < k8s/deployment.yaml | kubectl apply -f -
          envsubst < k8s/service.yaml | kubectl apply -f -
          
          kubectl rollout status deployment/$SERVICE_NAME -n $K8S_NAMESPACE --timeout=300s
```

**Important:** Use `latest` tag, not `${{ github.sha }}`.

---

### Step 6: Create GitHub Repository

```bash
# Login to GitHub CLI
gh auth login

# Create repository
gh repo create SpiritB3ar/<service-name> --private --source=. --push

# Set default branch to main
git branch -m master main
git push -u origin main
git push origin --delete master
```

---

### Step 7: Configure GitHub Secrets

Add these secrets in GitHub repo settings:
- `AZURE_CREDENTIALS`: Azure service principal JSON
- `ACR_USERNAME`: ACR username
- `ACR_PASSWORD`: ACR password

---

### Step 8: Verify Deployment

```bash
# Check pipeline status
gh run list --repo SpiritB3ar/<service-name> --limit 3

# Check pod status
kubectl get pods -n bankx -l app=<service-name>

# Get external IP
kubectl get svc <service-name> -n bankx

# Test health endpoint
curl http://<EXTERNAL-IP>/actuator/health
```

---

## Service Configuration Reference

| Service | Port | DB Name | Redis | Kafka |
|---------|------|---------|-------|-------|
| account-service | 8082 | account_db | Yes | Yes |
| credit-service | 8083 | credit_db | Yes | Yes |
| transaction-service | 8084 | transaction_db | No | Yes |
| fraud-detection-service | 8085 | fraud_detection_db | No | Yes |
| auth-service | 8086 | auth_db | No | No |
| yanki-service | 8088 | yanki_db | No | Yes |
| customer-service | 8089 | customer_db | Yes | No |

---

## Common Issues and Fixes

| Issue | Fix |
|-------|-----|
| ImagePullBackOff | Check ACR secret exists, verify image name has ACR prefix |
| CreateContainerConfigError | Create missing secrets (cosmos-mongo-secret) |
| Pod Pending | Reduce resource requests or scale up nodes |
| Kafka timeout | Use `kafka:9092` instead of full DNS name |
| OpenAPI spec not found | Copy docs/ folder, update pom.xml path |
| Pipeline not triggered | Remove `[skip ci]` from commit message |

---

## Quick Copy Commands

For each new service, run these commands:

```bash
# 1. Prepare code
cd <service-name>
rm src/main/resources/bootstrap.yml

# 2. Copy OpenAPI spec
mkdir -p docs/openapi
cp ../docs/openapi/<service-name>-api.yaml docs/openapi/

# 3. Update pom.xml inputSpec path (manual edit required)

# 4. Create K8s manifests
mkdir -p k8s
# Create configmap.yaml, deployment.yaml, service.yaml

# 5. Create CI/CD pipeline
mkdir -p .github/workflows
# Create ci-cd.yml

# 6. Create GitHub repo
gh repo create SpiritB3ar/<service-name> --private --source=. --push

# 7. Configure secrets in GitHub UI

# 8. Verify
gh run list --repo SpiritB3ar/<service-name> --limit 3
```

---

## Notes

- **Namespace:** All services deploy to `bankx`
- **Kafka:** Available at `kafka:9092` (ExternalName service in bankx namespace)
- **MongoDB:** Use `cosmos-mongo-secret` for connection string
- **Redis:** Available at `redis:6379` (if deployed)
- **Image Tag:** Always use `latest` for simplicity
- **Resources:** Minimal (100m CPU, 128Mi RAM) for bootcamp
