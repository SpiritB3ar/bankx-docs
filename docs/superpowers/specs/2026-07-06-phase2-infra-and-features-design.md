# Phase II - BankSystem: Infrastructure & Business Features Design

> **Date:** 2026-07-06
> **Status:** Draft - Pending user approval
> **Scope:** Infrastructure services, circuit breaker, testing, business logic, Dockerfiles

## 1. Context

The BankSystem project has a solid Phase I foundation with 6 microservices (customer, account, credit, transaction, fraud-detection, config-server) using hexagonal architecture, Spring WebFlux + RxJava 3, MongoDB reactive, Kafka, and OpenAPI documentation.

Phase II adds service discovery, API gateway, resilience patterns, new business logic, testing infrastructure, and containerization.

### Current State
- **Microservices:** customer-service (8081), account-service (8082), credit-service (8083), transaction-service (8084), fraud-detection-service (8085), config-server (8888)
- **Architecture:** Hexagonal (Ports & Adapters) with reactive stack
- **Java 17**, Spring Boot 3.3.1, Spring Cloud 2023.0.2
- **Database per service** with MongoDB reactive
- **Kafka** for transaction-service -> fraud-detection-service events
- **No Eureka, no Gateway, no CircuitBreaker, no meaningful tests, no Dockerfiles**

## 2. Requirements (from AGENTS.md Part II)

### Bases
1. Functional/reactive programming with RxJava 3 (already in place)
2. Collection management using Streams APIs
3. Add Checkstyle plugin in pom.xml
4. Eureka service registry microservice with dashboard
5. API Gateway with Spring Cloud Gateway
6. Circuit Breaker with Resilience4j (2-second timeout)
7. Software design patterns
8. Unit tests + JaCoCo coverage reports
9. Each microservice in independent Docker container

### Business Features
1. Minimum opening amount for bank accounts (can be 0) - partially done
2. New client profiles: VIP (personal), PYME (enterprise)
3. Max free transactions per account, commission after exceeding
4. Bank transfers between accounts (same client and third-party)
5. Reports: complete product report by date range, last 10 movements for debit/credit cards

## 3. Architecture Decisions

### 3.1 Repository Structure
**Decision:** Separate repositories per microservice (as per AGENTS.md requirement).
**Implementation:** During development, work in monorepo. Final delivery splits into individual repos.

### 3.2 Eureka Server
**New microservice:** `eureka-server/`
- Port: 8761
- Dependencies: `spring-cloud-starter-netflix-eureka-server`
- Self-registration disabled
- Dashboard enabled at `http://localhost:8761`

### 3.3 API Gateway
**New microservice:** `gateway-service/`
- Port: 8080
- Dependencies: `spring-cloud-starter-gateway`, `spring-cloud-starter-netflix-eureka-client`
- Routes configured for all 5 business microservices
- Load balancing via Eureka discovery

### 3.4 Circuit Breaker (Resilience4j)
- Dependency: `resilience4j-spring-boot3`, `resilience4j-reactor`
- Applied to: inter-service calls (account->customer, transaction->account, credit->customer)
- Timeout: 2 seconds
- Fallback: return meaningful error responses

### 3.5 Checkstyle
- Plugin: `maven-checkstyle-plugin` in all pom.xml
- Style: Google Java Style (adapted for Spring Boot)

### 3.6 JaCoCo
- Plugin: `jacoco-maven-plugin` in all pom.xml
- Minimum coverage target: 60%
- Report: `mvn jacoco:report`

### 3.7 Testing Strategy
- **Domain Services:** Unit tests with Mockito mocks
- **Application Services:** Unit tests mocking ports
- **Controllers:** WebTestClient tests mocking services
- **Mappers:** MapStruct test verification

### 3.8 Dockerfiles
- Multi-stage build: `maven:3.9-eclipse-temurin-17` -> `eclipse-temurin:17-jre`
- One Dockerfile per microservice (8 total)
- docker-compose.yml updated with all services

## 4. Business Logic Design

### 4.1 Transfer Between Accounts
- Endpoint: `POST /api/v1/transactions/transfer`
- Validation: source account active, sufficient funds, destination account exists
- Atomic operation: debit source, credit destination
- Both transactions recorded with `TRANSFER` type
- Fee applied if exceeding free transaction limit

### 4.2 VIP Profile Validation
- On savings account creation for VIP customer:
  - Verify customer has active credit card
  - Set `minimumDailyAverage` field
  - Track daily balance for monthly average calculation

### 4.3 PYME Profile Validation
- On checking account creation for PYME customer:
  - Verify customer has active credit card
  - Set `maintenanceFee = 0`
  - No maintenance fee charged

### 4.4 Transaction Commissions
- Each account has `maxFreeTransactions` and `currentTransactionCount`
- On each transaction, increment counter
- If counter > maxFreeTransactions, apply fee from `maintenanceFee` field
- Counter resets monthly (configurable)

### 4.5 Credit Card Charges
- Endpoint: `POST /api/v1/credits/{id}/charge`
- Validation: credit active, amount <= available limit
- Reduce `availableCreditLimit`, increase `currentBalance`
- Record transaction with `CREDIT_CARD_PURCHASE` type

### 4.6 Credit Payments
- Endpoint: `POST /api/v1/credits/{id}/payment`
- Reduce `currentBalance`, increase `availableCreditLimit`
- Update `minimumPayment` and `paymentDueDate`

## 5. File Structure

### New Files (per microservice)
```
eureka-server/
  pom.xml
  src/main/java/com/bank/eureka/EurekaServerApplication.java
  src/main/resources/application.yml
  Dockerfile

gateway-service/
  pom.xml
  src/main/java/com/bank/gateway/GatewayServiceApplication.java
  src/main/java/com/bank/gateway/config/RouteConfig.java
  src/main/resources/application.yml
  Dockerfile

account-service/
  Dockerfile
  src/test/java/com/bank/account/application/service/CreateAccountServiceImplTest.java
  src/test/java/com/bank/account/application/service/FindAccountServiceImplTest.java
  src/test/java/com/bank/account/domain/service/AccountDomainServiceTest.java
  src/test/java/com/bank/account/adapter/inbound/web/AccountControllerTest.java

customer-service/
  Dockerfile
  src/test/java/com/bank/customer/application/service/CreateCustomerServiceImplTest.java
  src/test/java/com/bank/customer/domain/service/CustomerDomainServiceTest.java
  src/test/java/com/bank/customer/adapter/inbound/web/CustomerControllerTest.java

credit-service/
  Dockerfile
  src/test/java/com/bank/credit/application/service/...
  src/test/java/com/bank/credit/domain/service/CreditDomainServiceTest.java
  src/test/java/com/bank/credit/adapter/inbound/web/CreditControllerTest.java

transaction-service/
  Dockerfile
  src/test/java/com/bank/transaction/application/service/...
  src/test/java/com/bank/transaction/domain/service/TransactionDomainServiceTest.java
  src/test/java/com/bank/transaction/adapter/inbound/web/TransactionControllerTest.java

fraud-detection-service/
  Dockerfile
  src/test/java/com/bank/fraud/...

config-server/
  Dockerfile
```

### Modified Files
```
*/pom.xml (add Checkstyle, JaCoCo, Eureka Client, Resilience4j dependencies)
*/src/main/resources/application.yml (Eureka config, CircuitBreaker config)
docker-compose.yml (add all services)
```

## 6. Validation Checklist

- [ ] Eureka dashboard accessible at http://localhost:8761
- [ ] All services registered in Eureka
- [ ] Gateway routes working: http://localhost:8080/customer-service/api/v1/customers
- [ ] CircuitBreaker triggers after 2s timeout
- [ ] Checkstyle passes with no violations
- [ ] JaCoCo report shows >60% coverage
- [ ] All unit tests pass
- [ ] Docker containers start and communicate
- [ ] Transfer endpoint works between accounts
- [ ] VIP/PYME validations enforced
- [ ] Transaction commissions applied correctly
- [ ] Credit card charges work
- [ ] Credit payments work
