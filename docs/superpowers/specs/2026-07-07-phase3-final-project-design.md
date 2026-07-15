# Phase III - BankSystem Final Project: Design Spec

> **Date:** 2026-07-07
> **Status:** Draft - Pending user approval
> **Scope:** JWT Auth, Debit Cards, Yanki Wallet, Redis Cache, Debt Validation, Third-party Payments, Kafka Events

## 1. Context

Phase I built the core microservices (customer, account, credit, transaction, fraud-detection, config-server). Phase II added infrastructure (Eureka, Gateway, CircuitBreaker, Checkstyle, JaCoCo, tests, Dockerfiles) and business features (transfers, VIP/PYME validation, commissions, credit operations).

Phase III adds authentication/authorization (JWT), new product types (debit cards, Yanki mobile wallet), cross-service business rules (debt validation), Redis caching, and enforces event-driven architecture between new microservices.

## 2. Requirements (from AGENTS.md Part III)

### Bases
1. Functional/reactive programming with RxJava
2. Collection management with Streams APIs
3. New public methods must have unit tests with mocks
4. Present JaCoCo coverage report
5. Event-driven architecture with Kafka (new microservices CANNOT use REST to call other services)
6. Reactive controllers with RxJava and Spring
7. JWT authentication and authorization flow
8. Redis cache for catalog/master data
9. Maintain draw.io solution diagram

### Business Features
1. Customer cannot acquire a product if they have overdue debt on any credit product
2. Customer can pay any third-party credit product
3. Debit cards linked to bank accounts, payments with debit cards
4. Yanki mobile wallet:
   - No bank customer required (just ID document, phone, IMEI, email)
   - Send/receive payments with phone number only
   - Link wallet to debit card (balance charges/credits to main account)

## 3. New Microservices Architecture

### 3.1 auth-service (Port: 8086)
- **Purpose:** JWT token generation and validation
- **Database:** MongoDB (user credentials, roles)
- **Dependencies:** spring-boot-starter-webflux, spring-security, jjwt, mongodb-reactive
- **Endpoints:**
  - `POST /api/v1/auth/register` - Register user
  - `POST /api/v1/auth/login` - Login, get JWT token
  - `POST /api/v1/auth/validate` - Validate token
  - `POST /api/v1/auth/refresh` - Refresh token
- **Communication:** REST (this is the auth provider, other services call it to validate tokens)

### 3.2 debit-card-service (Port: 8087)
- **Purpose:** Manage debit cards linked to bank accounts
- **Database:** MongoDB (debit cards)
- **Dependencies:** spring-boot-starter-webflux, mongodb-reactive, kafka, eureka-client
- **Endpoints:**
  - `POST /api/v1/debit-cards` - Create debit card (linked to account)
  - `GET /api/v1/debit-cards` - Find all
  - `GET /api/v1/debit-cards/{id}` - Find by ID
  - `GET /api/v1/debit-cards/account/{accountId}` - Find by account
  - `GET /api/v1/debit-cards/customer/{customerId}` - Find by customer
  - `PUT /api/v1/debit-cards/{id}` - Update
  - `DELETE /api/v1/debit-cards/{id}` - Delete
  - `POST /api/v1/debit-cards/{id}/payment` - Make payment with debit card
- **Communication:** Kafka events for transactions (cannot call transaction-service via REST)

### 3.3 yanki-service (Port: 8088)
- **Purpose:** Mobile wallet - send/receive payments via phone number
- **Database:** MongoDB (wallets, transactions)
- **Dependencies:** spring-boot-starter-webflux, mongodb-reactive, kafka, eureka-client
- **Endpoints:**
  - `POST /api/v1/yanki/wallets` - Register wallet (phone, DNI, IMEI, email)
  - `GET /api/v1/yanki/wallets` - Find all
  - `GET /api/v1/yanki/wallets/{id}` - Find by ID
  - `GET /api/v1/yanki/wallets/phone/{phone}` - Find by phone
  - `PUT /api/v1/yanki/wallets/{id}` - Update
  - `DELETE /api/v1/yanki/wallets/{id}` - Delete
  - `POST /api/v1/yanki/wallets/{id}/link-debit-card` - Link to debit card
  - `POST /api/v1/yanki/wallets/{id}/send` - Send payment
  - `POST /api/v1/yanki/wallets/{id}/receive` - Receive payment
  - `GET /api/v1/yanki/wallets/{id}/balance` - Get balance
- **Communication:** Kafka events for all transaction operations

## 4. Cross-Service Business Rules

### 4.1 Debt Validation (No new product if overdue debt)
- **Where:** account-service CreateAccountServiceImpl, credit-service CreateCreditServiceImpl
- **How:** Via Kafka event - publish `debt-check-request` event, credit-service responds with `debt-check-response`
- **Alternative:** Since we can't use REST between new services, use Kafka request-reply pattern

### 4.2 Third-Party Credit Payment
- **Where:** credit-service - new endpoint `POST /api/v1/credits/{id}/third-party-payment`
- **How:** Accept payer info (not necessarily the credit owner), process payment
- **Validation:** Credit must exist and be active

### 4.3 Debit Card Payment Flow
1. Client initiates payment via debit-card-service
2. debit-card-service publishes `debit-card-payment` Kafka event
3. transaction-service consumes event, creates transaction, updates account balance
4. transaction-service publishes `transaction-completed` event
5. debit-card-service updates card status

### 4.4 Yanki Payment Flow
1. User sends payment via yanki-service
2. yanki-service publishes `yanki-transfer` Kafka event
3. If wallet linked to debit card → transaction-service processes via debit card
4. If wallet not linked → internal wallet-to-wallet transfer

## 5. JWT Authentication Flow

### 5.1 Token Generation
1. User logs in via `POST /api/v1/auth/login` with credentials
2. auth-service validates credentials against MongoDB
3. auth-service generates JWT with: userId, roles, expiration
4. Returns token to client

### 5.2 Token Validation (Gateway Filter)
1. Gateway-service has JWT filter that intercepts all requests
2. Filter extracts token from `Authorization: Bearer <token>` header
3. Filter validates token signature and expiration
4. If valid, forwards request to downstream service
5. If invalid, returns 401 Unauthorized

### 5.3 Service-Level Security
- Each service has Spring Security configured
- JWT filter validates token on each request
- Role-based access control: CUSTOMER, ADMIN, ANALYST

## 6. Redis Cache Design

### 6.1 What to Cache
- Customer profiles (TTL: 5 min)
- Account types and their rules (TTL: 1 hour)
- Credit types and limits (TTL: 1 hour)
- Debit card status (TTL: 1 min)

### 6.2 Cache Strategy
- **Pattern:** Cache-Aside (Lazy Loading)
- **On Read:** Check cache first → if miss, read DB → store in cache
- **On Write:** Update DB → invalidate cache
- **TTL:** Different per entity type

### 6.3 Implementation
- Add `spring-boot-starter-data-redis-reactive` to services that need caching
- Create `@Cacheable`, `@CacheEvict` annotations on service methods
- Redis host: `localhost:6379` (configurable via Config Server)

## 7. Kafka Topics (New)

| Topic | Producer | Consumer | Event |
|-------|----------|----------|-------|
| `debit-card-payment` | debit-card-service | transaction-service | Payment request |
| `transaction-completed` | transaction-service | debit-card-service | Payment confirmation |
| `yanki-transfer` | yanki-service | transaction-service | Transfer request |
| `debt-check-request` | account-service, credit-service | credit-service | Debt validation request |
| `debt-check-response` | credit-service | account-service, credit-service | Debt validation result |
| `debit-card-events` | debit-card-service | yanki-service | Card linking events |

## 8. File Structure

### New Microservices
```
auth-service/
  pom.xml
  src/main/java/com/bank/auth/
    Auth-serviceApplication.java
    config/
      SecurityConfig.java
      JwtConfig.java
    domain/
      model/User.java, Role.java
      port/in/AuthenticationUseCase.java, ValidateTokenUseCase.java
      port/out/UserRepositoryPort.java
    application/service/
      AuthenticationServiceImpl.java
      ValidateTokenServiceImpl.java
    adapter/
      inbound/web/AuthController.java
      outbound/persistence/UserPersistenceAdapter.java
  src/main/resources/application.yml
  Dockerfile

debit-card-service/
  pom.xml
  src/main/java/com/bank/debitcard/
    DebitCardServiceApplication.java
    config/
      BeanConfig.java
      KafkaProducerConfig.java
      KafkaConsumerConfig.java
    domain/
      model/DebitCard.java, DebitCardStatus.java
      port/in/...UseCase.java
      port/out/DebitCardRepositoryPort.java
    application/service/...
    adapter/
      inbound/web/DebitCardController.java
      outbound/persistence/...
      outbound/kafka/DebitCardEventProducer.java
      inbound/kafka/DebitCardEventConsumer.java
  src/main/resources/application.yml
  Dockerfile

yanki-service/
  pom.xml
  src/main/java/com/bank/yanki/
    YankiServiceApplication.java
    config/
      BeanConfig.java
      KafkaProducerConfig.java
      KafkaConsumerConfig.java
    domain/
      model/YankiWallet.java, YankiTransaction.java
      port/in/...UseCase.java
      port/out/WalletRepositoryPort.java
    application/service/...
    adapter/
      inbound/web/YankiController.java
      outbound/persistence/...
      outbound/kafka/YankiEventProducer.java
      inbound/kafka/YankiEventConsumer.java
  src/main/resources/application.yml
  Dockerfile
```

### Modified Files
```
gateway-service/ - Add JWT filter, new routes for auth/debit-card/yanki
config-server/ - Add config for auth-service, debit-card-service, yanki-service
customer-service/ - Add Redis cache
account-service/ - Add Redis cache, debt validation via Kafka
credit-service/ - Add Redis cache, debt check response via Kafka, third-party payment
transaction-service/ - Add Kafka consumers for debit-card and yanki events
docker-compose.yml - Add auth-service, debit-card-service, yanki-service, Redis
```

## 9. Validation Checklist

- [ ] auth-service: JWT login/register/validate working
- [ ] gateway-service: JWT filter blocks unauthorized requests
- [ ] debit-card-service: CRUD + payment via Kafka
- [ ] yanki-service: Wallet CRUD + send/receive via Kafka
- [ ] Redis cache working for customer/account/credit data
- [ ] Debt validation prevents product acquisition with overdue debt
- [ ] Third-party credit payment works
- [ ] All new services use Kafka (no REST calls between new services)
- [ ] All new methods have unit tests with mocks
- [ ] JaCoCo coverage report >60%
- [ ] All services compile and tests pass
- [ ] docker-compose.yml includes all new services + Redis
- [ ] draw.io diagram updated with new architecture
