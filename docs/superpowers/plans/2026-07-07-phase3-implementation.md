# Phase III - BankSystem Final Project Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Phase III with JWT authentication, debit cards, Yanki mobile wallet, Redis caching, debt validation, and third-party credit payments using event-driven architecture.

**Architecture:** 3 new microservices (auth-service, debit-card-service, yanki-service) + modifications to existing services. Kafka for inter-service communication. Redis for caching. JWT for auth.

**Tech Stack:** Java 17, Spring Boot 3.3.1, Spring Cloud 2023.0.2, Spring Security, JJWT, Kafka, Redis, Resilience4j, JUnit 5, Mockito

## Global Constraints

- Java 17, Spring Boot 3.3.1, Spring Cloud 2023.0.2
- All class/method names in English
- Hexagonal architecture (Ports & Adapters)
- Reactive stack: Spring WebFlux + RxJava 3
- MongoDB per service
- New microservices CANNOT use REST to call other services (must use Kafka)
- All new public methods must have unit tests with mocks
- JaCoCo coverage >60%
- Redis for master data caching

---

## PHASE A: auth-service (JWT Authentication)

### Task 1: Create auth-service Microservice

**Files:**
- Create: `auth-service/pom.xml`
- Create: `auth-service/src/main/java/com/bank/auth/AuthServiceApplication.java`
- Create: `auth-service/src/main/java/com/bank/auth/domain/model/User.java`
- Create: `auth-service/src/main/java/com/bank/auth/domain/model/Role.java`
- Create: `auth-service/src/main/java/com/bank/auth/domain/port/in/AuthenticationUseCase.java`
- Create: `auth-service/src/main/java/com/bank/auth/domain/port/in/ValidateTokenUseCase.java`
- Create: `auth-service/src/main/java/com/bank/auth/domain/port/out/UserRepositoryPort.java`
- Create: `auth-service/src/main/java/com/bank/auth/domain/service/AuthDomainService.java`
- Create: `auth-service/src/main/java/com/bank/auth/application/service/AuthenticationServiceImpl.java`
- Create: `auth-service/src/main/java/com/bank/auth/application/service/ValidateTokenServiceImpl.java`
- Create: `auth-service/src/main/java/com/bank/auth/config/SecurityConfig.java`
- Create: `auth-service/src/main/java/com/bank/auth/config/JwtConfig.java`
- Create: `auth-service/src/main/java/com/bank/auth/config/BeanConfig.java`
- Create: `auth-service/src/main/java/com/bank/auth/adapter/inbound/web/AuthController.java`
- Create: `auth-service/src/main/java/com/bank/auth/adapter/inbound/web/dto/LoginRequest.java`
- Create: `auth-service/src/main/java/com/bank/auth/adapter/inbound/web/dto/RegisterRequest.java`
- Create: `auth-service/src/main/java/com/bank/auth/adapter/inbound/web/dto/TokenResponse.java`
- Create: `auth-service/src/main/java/com/bank/auth/adapter/outbound/persistence/UserPersistenceAdapter.java`
- Create: `auth-service/src/main/java/com/bank/auth/adapter/outbound/persistence/UserMongoRepository.java`
- Create: `auth-service/src/main/java/com/bank/auth/adapter/outbound/persistence/document/UserDocument.java`
- Create: `auth-service/src/main/resources/application.yml`
- Create: `auth-service/Dockerfile`

**Interfaces:**
- Produces: JWT tokens
- Consumes: MongoDB for user storage

- [ ] **Step 1: Create auth-service pom.xml**
  - Parent: spring-boot-starter-parent 3.3.1
  - Dependencies: webflux, data-mongodb-reactive, security, jjwt (0.12.5), eureka-client, actuator, config, lombok, spring-cloud 2023.0.2

- [ ] **Step 2: Create domain models**
  - User: id, username, password, email, customerId, roles, active, createdAt
  - Role: CUSTOMER, ADMIN, ANALYST

- [ ] **Step 3: Create use case interfaces**
  - AuthenticationUseCase: login(LoginRequest) -> TokenResponse, register(RegisterRequest) -> User
  - ValidateTokenUseCase: validate(String token) -> TokenClaims

- [ ] **Step 4: Create JwtConfig and SecurityConfig**
  - JwtConfig: secret key, expiration, issuer
  - SecurityConfig: JWT filter, public endpoints (/login, /register), secured endpoints

- [ ] **Step 5: Create application services**
  - AuthenticationServiceImpl: validate credentials, generate JWT
  - ValidateTokenServiceImpl: parse JWT, extract claims, validate expiration

- [ ] **Step 6: Create AuthController**
  - POST /api/v1/auth/login -> TokenResponse
  - POST /api/v1/auth/register -> User
  - POST /api/v1/auth/validate -> TokenClaims

- [ ] **Step 7: Create persistence adapter**
  - UserPersistenceAdapter implements UserRepositoryPort
  - UserMongoRepository extends ReactiveMongoRepository
  - UserDocument with MapStruct mapper

- [ ] **Step 8: Create application.yml**
  - Port: 8086
  - MongoDB: auth_db
  - JWT config: secret, expiration

- [ ] **Step 9: Create Dockerfile**

- [ ] **Step 10: Verify build**
  Run: `cd auth-service && mvn clean compile -q`

---

## PHASE B: debit-card-service

### Task 2: Create debit-card-service Microservice

**Files:**
- Create: `debit-card-service/pom.xml`
- Create: `debit-card-service/src/main/java/com/bank/debitcard/DebitCardServiceApplication.java`
- Create: `debit-card-service/src/main/java/com/bank/debitcard/domain/model/DebitCard.java`
- Create: `debit-card-service/src/main/java/com/bank/debitcard/domain/model/DebitCardStatus.java`
- Create: `debit-card-service/src/main/java/com/bank/debitcard/domain/port/in/*.java` (CRUD + payment use cases)
- Create: `debit-card-service/src/main/java/com/bank/debitcard/domain/port/out/DebitCardRepositoryPort.java`
- Create: `debit-card-service/src/main/java/com/bank/debitcard/domain/service/DebitCardDomainService.java`
- Create: `debit-card-service/src/main/java/com/bank/debitcard/application/service/*.java`
- Create: `debit-card-service/src/main/java/com/bank/debitcard/config/*.java` (BeanConfig, Kafka configs)
- Create: `debit-card-service/src/main/java/com/bank/debitcard/adapter/inbound/web/DebitCardController.java`
- Create: `debit-card-service/src/main/java/com/bank/debitcard/adapter/inbound/web/dto/*.java`
- Create: `debit-card-service/src/main/java/com/bank/debitcard/adapter/outbound/persistence/*.java`
- Create: `debit-card-service/src/main/java/com/bank/debitcard/adapter/outbound/kafka/DebitCardEventProducer.java`
- Create: `debit-card-service/src/main/java/com/bank/debitcard/adapter/inbound/kafka/DebitCardEventConsumer.java`
- Create: `debit-card-service/src/main/resources/application.yml`
- Create: `debit-card-service/Dockerfile`

- [ ] **Step 1: Create pom.xml**
  - Dependencies: webflux, mongodb-reactive, kafka, eureka-client, resilience4j, config, lombok

- [ ] **Step 2: Create domain models**
  - DebitCard: id, cardNumber, accountId, customerId, status, dailyLimit, monthlyLimit, createdAt
  - DebitCardStatus: ACTIVE, BLOCKED, EXPIRED

- [ ] **Step 3: Create use cases and services**
  - CreateDebitCardUseCase, FindDebitCardUseCase, UpdateDebitCardUseCase, DeleteDebitCardUseCase
  - MakePaymentUseCase -> publishes Kafka event

- [ ] **Step 4: Create Kafka producer/consumer**
  - Producer: publishes `debit-card-payment` events
  - Consumer: consumes `transaction-completed` events

- [ ] **Step 5: Create controller**
  - CRUD endpoints + POST /{id}/payment

- [ ] **Step 6: Create persistence adapter**

- [ ] **Step 7: Create application.yml and Dockerfile**

- [ ] **Step 8: Verify build**

---

## PHASE C: yanki-service

### Task 3: Create yanki-service Microservice

**Files:**
- Create: `yanki-service/pom.xml`
- Create: `yanki-service/src/main/java/com/bank/yanki/YankiServiceApplication.java`
- Create: `yanki-service/src/main/java/com/bank/yanki/domain/model/YankiWallet.java`
- Create: `yanki-service/src/main/java/com/bank/yanki/domain/model/YankiTransaction.java`
- Create: `yanki-service/src/main/java/com/bank/yanki/domain/port/in/*.java`
- Create: `yanki-service/src/main/java/com/bank/yanki/domain/port/out/*.java`
- Create: `yanki-service/src/main/java/com/bank/yanki/domain/service/YankiDomainService.java`
- Create: `yanki-service/src/main/java/com/bank/yanki/application/service/*.java`
- Create: `yanki-service/src/main/java/com/bank/yanki/config/*.java`
- Create: `yanki-service/src/main/java/com/bank/yanki/adapter/inbound/web/YankiController.java`
- Create: `yanki-service/src/main/java/com/bank/yanki/adapter/inbound/web/dto/*.java`
- Create: `yanki-service/src/main/java/com/bank/yanki/adapter/outbound/persistence/*.java`
- Create: `yanki-service/src/main/java/com/bank/yanki/adapter/outbound/kafka/YankiEventProducer.java`
- Create: `yanki-service/src/main/java/com/bank/yanki/adapter/inbound/kafka/YankiEventConsumer.java`
- Create: `yanki-service/src/main/resources/application.yml`
- Create: `yanki-service/Dockerfile`

- [ ] **Step 1: Create pom.xml**

- [ ] **Step 2: Create domain models**
  - YankiWallet: id, phoneNumber, documentType, documentNumber, imei, email, balance, linkedDebitCardId, active, createdAt
  - YankiTransaction: id, fromWalletId, toWalletId, amount, type, status, createdAt

- [ ] **Step 3: Create use cases**
  - RegisterWalletUseCase, FindWalletUseCase, LinkDebitCardUseCase
  - SendPaymentUseCase, ReceivePaymentUseCase, GetBalanceUseCase

- [ ] **Step 4: Create Kafka producer/consumer**
  - Producer: publishes `yanki-transfer` events
  - Consumer: consumes `transaction-completed` events

- [ ] **Step 5: Create controller**
  - CRUD + POST /{id}/send + POST /{id}/receive + POST /{id}/link-debit-card

- [ ] **Step 6: Create persistence and Dockerfile**

- [ ] **Step 7: Verify build**

---

## PHASE D: Redis Cache

### Task 4: Add Redis to Services

**Files:**
- Modify: `customer-service/pom.xml` (add redis dependency)
- Modify: `account-service/pom.xml` (add redis dependency)
- Modify: `credit-service/pom.xml` (add redis dependency)
- Modify: `customer-service/src/main/java/com/bank/customer/application/service/*.java` (add cache annotations)
- Modify: `account-service/src/main/java/com/bank/account/application/service/*.java`
- Modify: `credit-service/src/main/java/com/bank/credit/application/service/*.java`
- Modify: `*/src/main/resources/application.yml` (add redis config)

- [ ] **Step 1: Add Redis dependency to pom.xml**
  ```xml
  <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-redis-reactive</artifactId>
  </dependency>
  ```

- [ ] **Step 2: Add Redis config to application.yml**
  ```yaml
  spring:
    data:
      redis:
        host: localhost
        port: 6379
  ```

- [ ] **Step 3: Add @Cacheable to service methods**
  - FindCustomerServiceImpl.findById -> @Cacheable("customers")
  - FindAccountServiceImpl.findById -> @Cacheable("accounts")
  - FindCreditServiceImpl.findById -> @Cacheable("credits")

- [ ] **Step 4: Add @CacheEvict to update/delete methods**

- [ ] **Step 5: Verify build**

---

## PHASE E: Business Rules

### Task 5: Debt Validation (No product if overdue debt)

**Files:**
- Modify: `credit-service/src/main/java/com/bank/credit/adapter/inbound/kafka/DebtCheckConsumer.java` (new)
- Modify: `credit-service/src/main/java/com/bank/credit/adapter/outbound/kafka/DebtCheckProducer.java` (new)
- Modify: `account-service/src/main/java/com/bank/account/application/service/CreateAccountServiceImpl.java`

- [ ] **Step 1: Create Kafka topic `debt-check-request` and `debt-check-response`**

- [ ] **Step 2: Create DebtCheckConsumer in credit-service**
  - Listens for debt-check-request events
  - Checks if customer has overdue credits
  - Publishes debt-check-response

- [ ] **Step 3: Modify CreateAccountServiceImpl**
  - Before creating account, publish debt-check-request
  - Wait for response (with timeout)
  - If overdue debt exists, reject account creation

- [ ] **Step 4: Verify with tests**

### Task 6: Third-Party Credit Payment

**Files:**
- Modify: `credit-service/src/main/java/com/bank/credit/adapter/inbound/web/CreditController.java`
- Create: `credit-service/src/main/java/com/bank/credit/domain/port/in/ThirdPartyPaymentUseCase.java`
- Create: `credit-service/src/main/java/com/bank/credit/application/service/ThirdPartyPaymentServiceImpl.java`

- [ ] **Step 1: Create ThirdPartyPaymentUseCase**
  - execute(creditId, payerInfo, amount) -> PaymentResponse

- [ ] **Step 2: Create ThirdPartyPaymentServiceImpl**
  - Validate credit exists and is active
  - Process payment (reduce currentBalance, increase availableCreditLimit)
  - Record transaction with payer info

- [ ] **Step 3: Add endpoint POST /api/v1/credits/{id}/third-party-payment**

- [ ] **Step 4: Verify with tests**

---

## PHASE F: Gateway JWT Filter

### Task 7: Add JWT Filter to Gateway

**Files:**
- Modify: `gateway-service/pom.xml` (add jjwt, spring-security)
- Create: `gateway-service/src/main/java/com/bank/gateway/config/JwtFilter.java`
- Create: `gateway-service/src/main/java/com/bank/gateway/config/SecurityConfig.java`
- Modify: `gateway-service/src/main/resources/application.yml`

- [ ] **Step 1: Add dependencies**
  - spring-boot-starter-security, jjwt

- [ ] **Step 2: Create JwtFilter**
  - Extract token from Authorization header
  - Validate token signature and expiration
  - If valid, forward request; if invalid, return 401

- [ ] **Step 3: Configure SecurityConfig**
  - Public paths: /api/v1/auth/login, /api/v1/auth/register
  - All other paths require valid JWT

- [ ] **Step 4: Verify build**

---

## PHASE G: Tests and Coverage

### Task 8: Unit Tests for New Services

**Files:**
- Create: `auth-service/src/test/java/com/bank/auth/**/*.java`
- Create: `debit-card-service/src/test/java/com/bank/debitcard/**/*.java`
- Create: `yanki-service/src/test/java/com/bank/yanki/**/*.java`

- [ ] **Step 1: Auth service tests**
  - AuthDomainServiceTest, AuthenticationServiceImplTest, ValidateTokenServiceImplTest
  - AuthControllerTest (WebFluxTest)

- [ ] **Step 2: Debit card service tests**
  - DebitCardDomainServiceTest, DebitCardServiceImplTest
  - DebitCardControllerTest

- [ ] **Step 3: Yanki service tests**
  - YankiDomainServiceTest, YankiServiceImplTest
  - YankiControllerTest

- [ ] **Step 4: Run JaCoCo reports**
  Run: `mvn test jacoco:report` in each service

- [ ] **Step 5: Verify coverage >60%**

---

## PHASE H: Docker and Infrastructure

### Task 9: Update Docker Infrastructure

**Files:**
- Create: `auth-service/Dockerfile`
- Create: `debit-card-service/Dockerfile`
- Create: `yanki-service/Dockerfile`
- Modify: `docker-compose.yml`

- [ ] **Step 1: Create Dockerfiles for new services**

- [ ] **Step 2: Update docker-compose.yml**
  - Add auth-service, debit-card-service, yanki-service
  - Add Redis container
  - Update depends_on

- [ ] **Step 3: Verify docker-compose up**

---

## Self-Review Checklist

- [ ] auth-service: JWT login/register/validate working
- [ ] gateway-service: JWT filter blocks unauthorized requests
- [ ] debit-card-service: CRUD + payment via Kafka
- [ ] yanki-service: Wallet CRUD + send/receive via Kafka
- [ ] Redis cache working for customer/account/credit data
- [ ] Debt validation prevents product acquisition with overdue debt
- [ ] Third-party credit payment works
- [ ] All new services use Kafka (no REST calls between new services)
- [ ] All new methods have unit tests with mocks
- [ ] JaCoCo coverage report >60% for all services
- [ ] All services compile and tests pass
- [ ] docker-compose.yml includes all services + Redis
- [ ] draw.io diagram updated
