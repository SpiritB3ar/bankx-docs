# Account Service Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy account-service to Azure AKS with CI/CD pipeline, following the same pattern as transaction-service.

**Architecture:** Remove Spring Cloud Config Server and Eureka dependencies, use native K8s ConfigMaps and Services. Deploy via GitHub Actions to ACR and AKS.

**Tech Stack:** Java 17, Spring Boot 3.3.1, WebFlux, MongoDB, Redis, Kafka, Docker, Kubernetes, Azure AKS, GitHub Actions

## Global Constraints

- Java 17, Spring Boot 3.3.1
- Maven for dependency management
- MongoDB (CosmosDB) for data storage
- Reactive programming with WebFlux
- K8s namespace: `bankx`
- ACR: `acrbankx.azurecr.io`
- Resource limits: 128Mi-256Mi memory, 100m-250m CPU

---

## File Structure

### Files to Modify in account-service

| File | Change |
|------|--------|
| `account-service/pom.xml` | Remove Config Server and Eureka dependencies |
| `account-service/src/main/java/com/bank/account/AccountServiceApplication.java` | Remove @RefreshScope |
| `account-service/src/main/resources/application.yml` | Remove Config Server and Eureka config |
| `account-service/src/main/resources/bootstrap.yml` | Delete file |
| `account-service/src/test/java/com/bank/account/adapter/inbound/web/AccountControllerTest.java` | Remove Spring Cloud references |

### Files to Create in account-service

| File | Purpose |
|------|---------|
| `account-service/Dockerfile` | Multi-stage Docker build |
| `account-service/k8s/deployment.yaml` | K8s Deployment manifest |
| `account-service/k8s/service.yaml` | K8s Service manifest |
| `account-service/k8s/configmap.yaml` | Configuration variables |
| `account-service/.github/workflows/ci-cd.yml` | CI/CD pipeline |

---

## Task 1: Remove Spring Cloud Dependencies

**Files:**
- Modify: `account-service/pom.xml:55-65`

- [ ] **Step 1: Remove Config Server dependency**

Open `account-service/pom.xml` and remove lines 55-59:

```xml
        <!-- Spring Cloud Config Client -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-config</artifactId>
        </dependency>
```

- [ ] **Step 2: Remove Eureka Client dependency**

Remove lines 61-65:

```xml
        <!-- Spring Cloud Netflix Eureka Client -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>
```

- [ ] **Step 3: Commit changes**

```bash
cd account-service
git add pom.xml
git commit -m "refactor: remove Spring Cloud Config and Eureka dependencies"
```

---

## Task 2: Update Application Class

**Files:**
- Modify: `account-service/src/main/java/com/bank/account/AccountServiceApplication.java`

- [ ] **Step 1: Remove @RefreshScope annotation**

Replace the entire file with:

```java
package com.bank.account;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

/**
 * Spring Boot Application for Account Management Microservice.
 * 
 * This service manages bank accounts for the banking system,
 * including savings, checking, and fixed-term accounts.
 * 
 * Features:
 * - Hexagonal architecture (Ports & Adapters)
 * - Reactive programming with WebFlux
 * - MongoDB database
 * - MapStruct for object mapping
 * - Redis caching
 * - Kafka event publishing
 * 
 * @author Banking System Team
 * @version 1.0.0
 */
@SpringBootApplication
@EnableCaching
public class AccountServiceApplication {

    /**
     * Main entry point for the Account Service application.
     * 
     * @param args Command line arguments
     */
    public static void main(String[] args) {
        SpringApplication.run(AccountServiceApplication.class, args);
    }
}
```

- [ ] **Step 2: Commit changes**

```bash
git add src/main/java/com/bank/account/AccountServiceApplication.java
git commit -m "refactor: remove @RefreshScope annotation"
```

---

## Task 3: Update Application Configuration

**Files:**
- Modify: `account-service/src/main/resources/application.yml`
- Delete: `account-service/src/main/resources/bootstrap.yml`

- [ ] **Step 1: Create application-prod.yml**

Create new file `account-service/src/main/resources/application-prod.yml`:

```yaml
server:
  address: 0.0.0.0
  port: ${SERVER_PORT:8082}

spring:
  data:
    mongodb:
      uri: ${MONGODB_URI}
      database: ${SPRING_DATA_MONGODB_DATABASE:account_db}
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

# Springdoc OpenAPI
springdoc:
  api-docs:
    path: /api-docs
  swagger-ui:
    path: /swagger-ui.html
    operations-sorter: method

# Actuator endpoints
management:
  endpoints:
    web:
      exposure:
        include: health,info
  endpoint:
    health:
      show-details: always

# Logging configuration
logging:
  level:
    com.bank.account: INFO
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

- [ ] **Step 2: Delete bootstrap.yml**

```bash
rm src/main/resources/bootstrap.yml
```

- [ ] **Step 3: Commit changes**

```bash
git add src/main/resources/
git commit -m "refactor: migrate to application-prod.yml, remove bootstrap.yml"
```

---

## Task 4: Update Test Files

**Files:**
- Modify: `account-service/src/test/java/com/bank/account/adapter/inbound/web/AccountControllerTest.java`

- [ ] **Step 1: Update test annotations**

Replace lines 27-34 with:

```java
@WebFluxTest(controllers = AccountsApiController.class)
@TestPropertySource(properties = {
        "spring.data.mongodb.uri=mongodb://localhost:27017/test"
})
class AccountControllerTest {
```

- [ ] **Step 2: Commit changes**

```bash
git add src/test/java/com/bank/account/adapter/inbound/web/AccountControllerTest.java
git commit -m "fix: remove Spring Cloud references from tests"
```

---

## Task 5: Create Dockerfile

**Files:**
- Create: `account-service/Dockerfile`

- [ ] **Step 1: Create Dockerfile**

```dockerfile
# Multi-stage build for Account Service
FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN apk add --no-cache maven && \
    mvn clean package -DskipTests -B

FROM eclipse-temurin:17-jre-alpine
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
USER appuser
EXPOSE 8082
HEALTHCHECK --interval=30s --timeout=3s \
    CMD wget -qO- http://localhost:8082/actuator/health || exit 1
ENTRYPOINT ["java", "-jar", "app.jar"]
```

- [ ] **Step 2: Commit changes**

```bash
git add Dockerfile
git commit -m "feat: add Dockerfile for AKS deployment"
```

---

## Task 6: Create Kubernetes Manifests

**Files:**
- Create: `account-service/k8s/configmap.yaml`
- Create: `account-service/k8s/deployment.yaml`
- Create: `account-service/k8s/service.yaml`

- [ ] **Step 1: Create configmap.yaml**

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

- [ ] **Step 2: Create deployment.yaml**

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

- [ ] **Step 3: Create service.yaml**

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

- [ ] **Step 4: Commit changes**

```bash
mkdir -p k8s
git add k8s/
git commit -m "feat: add Kubernetes manifests for AKS deployment"
```

---

## Task 7: Create CI/CD Pipeline

**Files:**
- Create: `account-service/.github/workflows/ci-cd.yml`

- [ ] **Step 1: Create CI/CD workflow**

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - staging
          - prod

env:
  ACR_NAME: acrbankx
  ACR_LOGIN_SERVER: acrbankx.azurecr.io
  DOCKER_IMAGE: acrbankx.azurecr.io/${{ github.event.repository.name }}
  AKS_RESOURCE_GROUP: rg-bankx
  AKS_CLUSTER_NAME: aks-bankx
  K8S_NAMESPACE: bankx
  SERVICE_PORT: 8082

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
    environment: dev
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
          # Ensure namespace exists
          kubectl create namespace $K8S_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
          
          # Ensure ACR secret exists
          kubectl get secret acr-secret -n $K8S_NAMESPACE &>/dev/null || \
            kubectl create secret docker-registry acr-secret \
              --docker-server=$ACR_LOGIN_SERVER \
              --docker-username=${{ secrets.ACR_USERNAME }} \
              --docker-password=${{ secrets.ACR_PASSWORD }} \
              -n $K8S_NAMESPACE
          
          # Ensure CosmosDB secret exists
          kubectl get secret cosmos-mongo-secret -n $K8S_NAMESPACE &>/dev/null || \
            kubectl create secret generic cosmos-mongo-secret \
              --from-literal=mongo-uri="$(az cosmosdb keys list --name cosmos-bankx --resource-group ${{ env.AKS_RESOURCE_GROUP }} --type connection-strings --query 'connectionStrings[0].connectionString' -o tsv)" \
              -n $K8S_NAMESPACE
          
          export SERVICE_NAME=${{ github.event.repository.name }}
          export DOCKER_IMAGE=${{ env.DOCKER_IMAGE }}:${{ github.sha }}
          export SERVICE_PORT=${{ env.SERVICE_PORT }}
          export K8S_NAMESPACE=${{ env.K8S_NAMESPACE }}
          
          envsubst < k8s/configmap.yaml | kubectl apply -f -
          envsubst < k8s/deployment.yaml | kubectl apply -f -
          envsubst < k8s/service.yaml | kubectl apply -f -
          
          kubectl rollout status deployment/$SERVICE_NAME -n $K8S_NAMESPACE --timeout=300s
```

- [ ] **Step 2: Commit changes**

```bash
mkdir -p .github/workflows
git add .github/
git commit -m "feat: add CI/CD pipeline for AKS deployment"
```

---

## Task 8: Create GitHub Repository and Push

**Files:**
- All account-service files

- [ ] **Step 1: Create GitHub repo**

```bash
gh repo create SpiritB3ar/account-service --private --source=. --push
```

- [ ] **Step 2: Configure secrets**

Add these secrets in GitHub repo settings:
- `AZURE_CREDENTIALS`: Azure service principal JSON
- `ACR_USERNAME`: ACR username
- `ACR_PASSWORD`: ACR password

- [ ] **Step 3: Push code**

```bash
git add .
git commit -m "feat: initial deployment setup for account-service"
git push origin main
```

---

## Task 9: Verify Deployment

- [ ] **Step 1: Check pipeline status**

```bash
gh run list --repo SpiritB3ar/account-service --limit 5
```

- [ ] **Step 2: Verify pod is running**

```bash
kubectl get pods -n bankx -l app=account-service
```

- [ ] **Step 3: Get external IP**

```bash
kubectl get svc account-service -n bankx
```

- [ ] **Step 4: Test health endpoint**

```bash
curl http://<EXTERNAL-IP>/actuator/health
```

---

## Self-Review Checklist

- [ ] All Spring Cloud dependencies removed from pom.xml
- [ ] @RefreshScope removed from Application class
- [ ] application-prod.yml created without Config Server/Eureka
- [ ] bootstrap.yml deleted
- [ ] Test files updated to remove Spring Cloud references
- [ ] Dockerfile created with multi-stage build
- [ ] K8s manifests created (deployment, service, configmap)
- [ ] CI/CD pipeline configured
- [ ] All files committed with proper messages

---

## Next Steps After Deployment

1. Verify all endpoints work
2. Test Redis caching connectivity
3. Test Kafka producer/consumer
4. Proceed to customer-service deployment
