# Banking System - Test Plan

## Overview

Test plan for the 7 functional microservices in the Banking System. Covers unit tests (JUnit 5 + Mockito) with JaCoCo coverage reports.

> Note: The system runs on AKS with Azure API Management (JWT), Azure Cosmos DB (MongoDB API) and Azure Event Hubs (Kafka). There is **no** Spring Cloud Gateway, Eureka or Config Server in production — `gateway-service`, `eureka-server` and `config-server` folders exist only as legacy/reference code and are not part of the deployed platform.

## Test Execution Order

Services depend on Cosmos DB (MongoDB API) and Event Hubs (Kafka). Unit tests mock Kafka, Redis and Gemini:

1. `auth-service` (depends on Cosmos DB)
2. `customer-service` (depends on Cosmos DB, Redis)
3. `account-service` (depends on Cosmos DB, Redis, Kafka)
4. `credit-service` (depends on Cosmos DB, Redis, Kafka)
5. `transaction-service` (depends on Cosmos DB, Kafka)
6. `fraud-detection-service` (depends on Cosmos DB, Kafka, Gemini AI)
7. `yanki-service` (depends on Cosmos DB, Kafka)

## Test Summary by Service

| Service | Test Classes | Test Count | Coverage Target |
|---------|-------------|------------|-----------------|
| account-service | 7 | ~48 | 33%+ |
| auth-service | 4 | ~20 | 25%+ |
| credit-service | 7 | ~54 | 22%+ |
| customer-service | 7 | ~36 | 32%+ |
| fraud-detection-service | 6 | ~37 | 22%+ |
| transaction-service | 6 | ~52 | 28%+ |
| yanki-service | 11 | ~68 | 25%+ |
| **TOTAL** | **48** | **~315** | - |

---

## 1. account-service (7 test classes)

| Test Class | Tests | Description |
|-----------|-------|-------------|
| AccountServiceApplicationTests | 1 | Spring context load |
| AccountControllerTest | ~10 | REST controller endpoints |
| AccountDomainServiceTest | ~8 | Domain business rules |
| CreateAccountServiceImplTest | ~8 | Create account, VIP validation, debt check |
| FindAccountServiceImplTest | ~6 | Find by ID, customer, all |
| UpdateAccountServiceImplTest | ~4 | Update account fields |
| DeleteAccountServiceImplTest | ~3 | Delete account |

**Key scenarios tested:**
- Create standard/personal/PYME accounts
- VIP savings account requires active credit card (Kafka)
- Account creation blocked on overdue debt (Kafka)
- Account CRUD operations
- Balance queries
- Transfer between accounts

---

## 2. auth-service (4 test classes)

| Test Class | Tests | Description |
|-----------|-------|-------------|
| AuthServiceApplicationTests | 1 | Spring context load |
| AuthenticationServiceImplTest | ~8 | Login, register, token generation |
| ValidateTokenServiceImplTest | ~6 | JWT validation, expiration |
| AuthDomainServiceTest | ~5 | Password hashing, credentials |

**Key scenarios tested:**
- User registration and login
- JWT token generation and validation
- Invalid credentials handling
- Token expiration

---

## 3. config-server (1 test class)

| Test Class | Tests | Description |
|-----------|-------|-------------|
| ConfigServerApplicationTests | 1 | Spring context load |

---

## 4. credit-service (7 test classes)

| Test Class | Tests | Description |
|-----------|-------|-------------|
| CreditServiceApplicationTests | 1 | Spring context load |
| CreditControllerTest | ~10 | REST controller endpoints |
| CreditDomainServiceTest | ~8 | Domain business rules |
| ChargeCreditServiceImplTest | ~8 | Charge credit card, limit check |
| FindCreditServiceImplTest | ~6 | Find by ID, customer, type |
| PaymentCreditServiceImplTest | ~8 | Payment processing |
| ThirdPartyPaymentServiceImplTest | ~6 | Third-party credit payment |

**Key scenarios tested:**
- Create credit cards (personal/enterprise)
- Create loans (personal/enterprise)
- Charge credit card with limit validation
- Process payments (own + third-party)
- Debit card operations
- Credit limit calculations

---

## 5. customer-service (7 test classes)

| Test Class | Tests | Description |
|-----------|-------|-------------|
| CustomerServiceApplicationTests | 1 | Spring context load |
| CustomerControllerTest | ~10 | REST controller endpoints |
| CustomerDomainServiceTest | ~8 | Domain business rules |
| CreateCustomerServiceImplTest | ~6 | Create personal/enterprise customers |
| FindCustomerServiceImplTest | ~6 | Find by ID, type, document |
| UpdateCustomerServiceImplTest | ~4 | Update customer fields |
| DeleteCustomerServiceImplTest | ~3 | Delete customer |

**Key scenarios tested:**
- Create personal and enterprise customers
- Customer validation (document, type)
- CRUD operations
- Find by document number

---

## 6. fraud-detection-service (6 test classes)

| Test Class | Tests | Description |
|-----------|-------|-------------|
| FraudDetectionServiceApplicationTests | 2 | Spring context load |
| FraudControllerTest | 10 | REST controller endpoints |
| FraudDomainServiceTest | 7 | Domain business rules |
| AnalyzeTransactionServiceImplTest | 9 | AI fraud analysis |
| UpdateFraudAlertServiceImplTest | 14 | Alert status updates |
| DeleteFraudAlertServiceImplTest | 4 | Delete alerts |

**Key scenarios tested:**
- Transaction analysis with Gemini AI
- Fraud alert creation
- Alert status updates (resolve, add comments)
- Delete alerts
- Risk level classification

---

## 7. transaction-service (6 test classes)

| Test Class | Tests | Description |
|-----------|-------|-------------|
| TransactionServiceApplicationTests | 1 | Spring context load |
| TransactionControllerTest | ~10 | REST controller endpoints |
| TransactionDomainServiceTest | ~8 | Domain business rules |
| CreateTransactionServiceImplTest | ~8 | Create transactions |
| FindTransactionServiceImplTest | ~6 | Find by ID, account, date range |
| TransferServiceImplTest | ~6 | Transfer between accounts |

**Key scenarios tested:**
- Create deposit/withdrawal transactions
- Transfer between accounts (same customer + third-party)
- Transaction reports by date range
- Last N transactions
- Kafka event publishing

---

## 8. yanki-service (11 test classes)

| Test Class | Tests | Description |
|-----------|-------|-------------|
| YankiServiceApplicationTests | 1 | Spring context load |
| YankiControllerTest | ~10 | REST controller endpoints |
| YankiDomainServiceTest | ~8 | Domain business rules |
| RegisterWalletServiceImplTest | ~6 | Register wallet |
| FindWalletServiceImplTest | ~6 | Find by phone, ID |
| SendPaymentServiceImplTest | ~6 | Send money |
| ReceivePaymentServiceImplTest | ~6 | Receive money |
| LinkDebitCardServiceImplTest | ~6 | Link debit card |
| GetBalanceServiceImplTest | ~4 | Check balance |
| UpdateWalletServiceImplTest | ~4 | Update wallet |
| DeleteWalletServiceImplTest | ~4 | Delete wallet |

**Key scenarios tested:**
- Register wallet (no bank account required)
- Send/receive payments by phone
- Link debit card
- Balance inquiries
- Duplicate phone validation
- CRUD operations

---

## Run Commands

### Run all tests for a single service:
```bash
cd <service-name>
mvn test
```

### Run all tests for all services:
```powershell
$services = @("auth-service","customer-service","account-service","credit-service","transaction-service","fraud-detection-service","yanki-service")
foreach ($s in $services) {
    Write-Host "=== Testing $s ==="
    cd "C:\Users\eccalcin\OneDrive - NTT DATA EMEAL\NTTDATA\bootcamp\projects\banksystem\$s"
    mvn test
}
```

### Generate JaCoCo coverage report:
```bash
mvn test jacoco:report
```
Report location: `target/site/jacoco/index.html`

---

## Infrastructure Required for Tests

| Component | Required | Purpose |
|-----------|----------|---------|
| Cosmos DB (MongoDB API) | Yes | All services use `@DataMongoTest` (test profile) |
| Kafka (Event Hubs) | No | Mocked with Mockito in unit tests |
| Redis | No | Excluded via `spring.autoconfigure.exclude` |
| Eureka / Config Server | No | Not part of the deployed platform |
| Gemini AI | No | Mocked with `TestAiConfig` in fraud tests |

**Note:** All unit tests run with mocked dependencies. No external infrastructure is required to run the test suite.
