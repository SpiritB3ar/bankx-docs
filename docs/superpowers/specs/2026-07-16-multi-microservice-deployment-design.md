# Banking System - Multi-Microservice Deployment Design

**Date:** 2026-07-16  
**Status:** Approved  
**Author:** Banking System Team

---

## Executive Summary

This document outlines the design for deploying 6 additional microservices to Azure AKS, following the same pattern established with the successful `transaction-service` deployment. The approach eliminates Spring Cloud Config Server and Eureka in favor of native Kubernetes solutions (ConfigMaps and Services).

---

## Current State

### Deployed Services
| Service | Status | URL |
|---------|--------|-----|
| transaction-service | ✅ Running | http://128.203.214.190 |

### Services to Deploy
| Service | Port | Dependencies |
|---------|------|--------------|
| account-service | 8082 | Redis, Kafka |
| credit-service | 8083 | Redis, Kafka |
| fraud-detection-service | 8085 | Kafka, Spring AI |
| auth-service | 8086 | JWT, Security |
| customer-service | 8089 | Redis |
| yanki-service | 8088 | Kafka |

---

## Architecture Decisions

### Decision 1: Remove Spring Cloud Config Server

**Rationale:**
- Config Server requires running an additional pod
- Kubernetes ConfigMaps provide native configuration management
- ConfigMaps can be updated without restarting pods (via rollout)
- Reduces operational complexity and resource usage

**Implementation:**
- Remove `spring-cloud-starter-config` from `pom.xml`
- Remove `bootstrap.yml` files
- Create K8s ConfigMap for each service
- Use `envFrom` in Deployment to inject ConfigMap values

### Decision 2: Remove Eureka Service Discovery

**Rationale:**
- Kubernetes Services provide native service discovery
- Services can communicate using DNS names (e.g., `account-service:8082`)
- No need for client-side load balancing (K8s handles this)
- Reduces pod count and resource consumption

**Implementation:**
- Remove `spring-cloud-starter-netflix-eureka-client` from `pom.xml`
- Remove `@EnableDiscoveryClient` and `@RefreshScope` annotations
- Remove Eureka configuration from `application-prod.yml`

### Decision 3: Use LoadBalancer for External Access

**Rationale:**
- Simplest way to expose services externally during development
- Each service gets a unique public IP
- Can be upgraded to APIM or Ingress later

**Future:**
- APIM will be configured for production routing
- NGINX Ingress will handle internal routing

---

## Deployment Pattern

### For Each Microservice

#### Step 1: Prepare Source Code

| File | Change |
|------|--------|
| `pom.xml` | Remove `spring-cloud-starter-config` and `spring-cloud-starter-netflix-eureka-client` |
| `*Application.java` | Remove `@RefreshScope` and `@EnableDiscoveryClient` |
| `application-prod.yml` | Remove Config Server and Eureka sections |
| `bootstrap.yml` | Delete file |
| Test files | Remove Spring Cloud references |

#### Step 2: Create Kubernetes Manifests

**deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${SERVICE_NAME}
  namespace: ${K8S_NAMESPACE}
spec:
  replicas: 1
  template:
    spec:
      imagePullSecrets:
        - name: acr-secret
      containers:
        - name: ${SERVICE_NAME}
          image: ${DOCKER_IMAGE}
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
```

**configmap.yaml:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${SERVICE_NAME}-config
  namespace: ${K8S_NAMESPACE}
data:
  SERVER_PORT: "${SERVICE_PORT}"
  SPRING_PROFILES_ACTIVE: "prod"
  KAFKA_BOOTSTRAP_SERVERS: "kafka:9092"
```

**service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ${SERVICE_NAME}
  namespace: ${K8S_NAMESPACE}
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: ${SERVICE_PORT}
```

#### Step 3: Create CI/CD Pipeline

**.github/workflows/ci-cd.yml:**
- Build with Maven
- Run tests
- Build Docker image
- Push to ACR
- Create/apply K8s secrets
- Deploy ConfigMap
- Deploy to AKS
- Verify rollout

#### Step 4: Create Dockerfile

**Dockerfile:**
```dockerfile
FROM eclipse-temurin:17-jre-alpine
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY target/*.jar app.jar
USER appuser
EXPOSE ${SERVICE_PORT}
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:${SERVICE_PORT}/actuator/health || exit 1
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

## Infrastructure Requirements

### Already Provisioned
- ✅ AKS Cluster (aks-bankx)
- ✅ ACR (acrbankx)
- ✅ CosmosDB (cosmos-bankx)
- ✅ Namespace (bankx)
- ✅ ACR Secret (acr-secret)
- ✅ CosmosDB Secret (cosmos-mongo-secret)

### Additional Secrets per Service
Each service needs its own CosmosDB database:
- `account_db`
- `credit_db`
- `fraud_detection_db`
- `auth_db`
- `customer_db`
- `yanki_db`

---

## Deployment Order

| Order | Service | Rationale |
|-------|---------|-----------|
| 1 | transaction-service | ✅ Already deployed |
| 2 | account-service | Core business, required by many services |
| 3 | customer-service | Core business, required by many services |
| 4 | credit-service | Depends on account and customer |
| 5 | auth-service | Security layer |
| 6 | yanki-service | Depends on account and customer |
| 7 | fraud-detection-service | Monitors all transactions |

---

## Risk Mitigation

### Risk: Resource Constraints
**Mitigation:** 
- Use minimal resources (100m CPU, 128Mi RAM)
- Deploy one service at a time
- Monitor node resource usage

### Risk: Build Failures
**Mitigation:**
- Run tests before deployment
- Use `mvn clean package -DskipTests` for initial builds
- Verify Docker image builds locally

### Risk: Configuration Errors
**Mitigation:**
- Test locally with `application-prod.yml`
- Use `kubectl logs` to debug startup issues
- Verify ConfigMap values before deployment

---

## Success Criteria

- [ ] Each service builds successfully in CI/CD
- [ ] Docker images are pushed to ACR
- [ ] Pods are running in AKS
- [ ] Health endpoints respond correctly
- [ ] Services can communicate via K8s DNS
- [ ] MongoDB connections are established

---

## Next Steps

After account-service is successfully deployed:
1. Verify all endpoints work
2. Test inter-service communication
3. Proceed to customer-service deployment
4. Continue with remaining services

---

## OpenAPI Spec Fix for Standalone Repos

**Issue:** When migrating from monorepo to standalone repos, the OpenAPI spec path in `pom.xml` breaks.

**Original path (monorepo):**
```xml
<inputSpec>${project.basedir}/../docs/openapi/account-service-api.yaml</inputSpec>
```

**Fixed path (standalone repo):**
```xml
<inputSpec>${project.basedir}/docs/openapi/account-service-api.yaml</inputSpec>
```

**Steps to fix for each microservice:**

1. Copy OpenAPI spec from monorepo:
```bash
mkdir -p docs/openapi
cp ../docs/openapi/<service-name>-api.yaml docs/openapi/
```

2. Update `pom.xml`:
```xml
<inputSpec>${project.basedir}/docs/openapi/<service-name>-api.yaml</inputSpec>
```

3. Commit without `[skip ci]`:
```bash
git add docs/openapi/ pom.xml
git commit -m "fix: add OpenAPI spec and fix inputSpec path for standalone repo"
git push origin main
```

**Affected services:**
- [x] account-service (fixed)
- [ ] customer-service
- [ ] credit-service
- [ ] fraud-detection-service
- [ ] auth-service
- [ ] yanki-service

---

## Appendix: Service Configuration

### account-service
- **Port:** 8082
- **Database:** account_db
- **Extra Config:** Redis, Kafka

### credit-service
- **Port:** 8083
- **Database:** credit_db
- **Extra Config:** Redis, Kafka

### fraud-detection-service
- **Port:** 8085
- **Database:** fraud_detection_db
- **Extra Config:** Kafka, Spring AI

### auth-service
- **Port:** 8086
- **Database:** auth_db
- **Extra Config:** JWT, Security

### customer-service
- **Port:** 8089
- **Database:** customer_db
- **Extra Config:** Redis

### yanki-service
- **Port:** 8088
- **Database:** yanki_db
- **Extra Config:** Kafka
