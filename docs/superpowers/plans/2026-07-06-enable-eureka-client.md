# Enable Eureka Client Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable Eureka Client registration in all 5 existing microservices so they register with the Eureka Server at startup.

**Architecture:** Each service will add the `spring-cloud-starter-netflix-eureka-client` dependency and configure Eureka client properties in `application.yml`. The Spring Cloud BOM is already present in each service, so no version management changes are needed.

**Tech Stack:** Java 17, Spring Boot 3.3.1, Spring Cloud 2023.0.2, Netflix Eureka Client

## Global Constraints

- Spring Cloud version: 2023.0.2 (already in dependencyManagement)
- Java version: 17
- Eureka Server URL: http://localhost:8761/eureka/
- All services use reactive stack (WebFlux)

---

## File Structure

| Service | Files to Modify |
|---------|-----------------|
| customer-service | `pom.xml`, `src/main/resources/application.yml` |
| account-service | `pom.xml`, `src/main/resources/application.yml` |
| credit-service | `pom.xml`, `src/main/resources/application.yml` |
| transaction-service | `pom.xml`, `src/main/resources/application.yml` |
| fraud-detection-service | `pom.xml`, `src/main/resources/application.yml` |

---

### Task 1: Add Eureka Client dependency to customer-service pom.xml

**Files:**
- Modify: `customer-service/pom.xml:59-60` (after spring-cloud-starter-config dependency)

- [ ] **Step 1: Add Eureka Client dependency**

Add after the `spring-cloud-starter-config` dependency (line 59):

```xml
        <!-- Spring Cloud Netflix Eureka Client -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>
```

- [ ] **Step 2: Verify compilation**

Run: `mvn clean compile -q` in `customer-service/`
Expected: BUILD SUCCESS

---

### Task 2: Add Eureka Client dependency to account-service pom.xml

**Files:**
- Modify: `account-service/pom.xml:59-60` (after spring-cloud-starter-config dependency)

- [ ] **Step 1: Add Eureka Client dependency**

Add after the `spring-cloud-starter-config` dependency (line 59):

```xml
        <!-- Spring Cloud Netflix Eureka Client -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>
```

- [ ] **Step 2: Verify compilation**

Run: `mvn clean compile -q` in `account-service/`
Expected: BUILD SUCCESS

---

### Task 3: Add Eureka Client dependency to credit-service pom.xml

**Files:**
- Modify: `credit-service/pom.xml:59-60` (after spring-cloud-starter-config dependency)

- [ ] **Step 1: Add Eureka Client dependency**

Add after the `spring-cloud-starter-config` dependency (line 59):

```xml
        <!-- Spring Cloud Netflix Eureka Client -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>
```

- [ ] **Step 2: Verify compilation**

Run: `mvn clean compile -q` in `credit-service/`
Expected: BUILD SUCCESS

---

### Task 4: Add Eureka Client dependency to transaction-service pom.xml

**Files:**
- Modify: `transaction-service/pom.xml:43-44` (after spring-cloud-starter-config dependency)

- [ ] **Step 1: Add Eureka Client dependency**

Add after the `spring-cloud-starter-config` dependency (line 43):

```xml
        <!-- Spring Cloud Netflix Eureka Client -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>
```

- [ ] **Step 2: Verify compilation**

Run: `mvn clean compile -q` in `transaction-service/`
Expected: BUILD SUCCESS

---

### Task 5: Add Eureka Client dependency to fraud-detection-service pom.xml

**Files:**
- Modify: `fraud-detection-service/pom.xml:43-44` (after spring-cloud-starter-config dependency)

- [ ] **Step 1: Add Eureka Client dependency**

Add after the `spring-cloud-starter-config` dependency (line 43):

```xml
        <!-- Spring Cloud Netflix Eureka Client -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>
```

- [ ] **Step 2: Verify compilation**

Run: `mvn clean compile -q` in `fraud-detection-service/`
Expected: BUILD SUCCESS

---

### Task 6: Add Eureka config to customer-service application.yml

**Files:**
- Modify: `customer-service/src/main/resources/application.yml` (append at end)

- [ ] **Step 1: Add Eureka configuration**

Append to end of file:

```yaml

# Eureka Client Configuration
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
  instance:
    prefer-ip-address: true
```

---

### Task 7: Add Eureka config to account-service application.yml

**Files:**
- Modify: `account-service/src/main/resources/application.yml` (append at end)

- [ ] **Step 1: Add Eureka configuration**

Append to end of file:

```yaml

# Eureka Client Configuration
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
  instance:
    prefer-ip-address: true
```

---

### Task 8: Add Eureka config to credit-service application.yml

**Files:**
- Modify: `credit-service/src/main/resources/application.yml` (append at end)

- [ ] **Step 1: Add Eureka configuration**

Append to end of file:

```yaml

# Eureka Client Configuration
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
  instance:
    prefer-ip-address: true
```

---

### Task 9: Add Eureka config to transaction-service application.yml

**Files:**
- Modify: `transaction-service/src/main/resources/application.yml` (append at end)

- [ ] **Step 1: Add Eureka configuration**

Append to end of file:

```yaml

# Eureka Client Configuration
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
  instance:
    prefer-ip-address: true
```

---

### Task 10: Add Eureka config to fraud-detection-service application.yml

**Files:**
- Modify: `fraud-detection-service/src/main/resources/application.yml` (append at end)

- [ ] **Step 1: Add Eureka configuration**

Append to end of file:

```yaml

# Eureka Client Configuration
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
  instance:
    prefer-ip-address: true
```

---

### Task 11: Final compilation verification for all services

- [ ] **Step 1: Compile all 5 services**

Run sequentially:
```bash
mvn clean compile -q  # in customer-service/
mvn clean compile -q  # in account-service/
mvn clean compile -q  # in credit-service/
mvn clean compile -q  # in transaction-service/
mvn clean compile -q  # in fraud-detection-service/
```

Expected: All 5 BUILD SUCCESS

---

## Summary

| Service | pom.xml | application.yml | Compile |
|---------|---------|-----------------|---------|
| customer-service | Add eureka-client dep | Add eureka config | Verify |
| account-service | Add eureka-client dep | Add eureka config | Verify |
| credit-service | Add eureka-client dep | Add eureka config | Verify |
| transaction-service | Add eureka-client dep | Add eureka config | Verify |
| fraud-detection-service | Add eureka-client dep | Add eureka config | Verify |
