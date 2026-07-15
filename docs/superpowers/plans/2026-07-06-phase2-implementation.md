# Phase II - BankSystem Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Phase II infrastructure (Eureka, Gateway, CircuitBreaker, Checkstyle, JaCoCo, Tests, Dockerfiles) and business features (transfers, VIP/PYME validation, commissions, credit operations) for the BankSystem microservices platform.

**Architecture:** Hexagonal architecture with Spring Cloud (Eureka, Gateway), Resilience4j for circuit breaking, TDD with JUnit 5 + Mockito, multi-stage Docker builds.

**Tech Stack:** Java 17, Spring Boot 3.3.1, Spring Cloud 2023.0.2, Resilience4j, JUnit 5, Mockito, WebTestClient, MapStruct, Maven, Docker

## Global Constraints

- Java 17, Spring Boot 3.3.1, Spring Cloud 2023.0.2
- All class/method names in English
- Hexagonal architecture (Ports & Adapters) pattern
- Reactive stack: Spring WebFlux + RxJava 3
- MongoDB per service (database per service pattern)
- No @Query annotations, use Spring Data reactive repositories
- Lombok for boilerplate reduction
- Logback for logging
- Externalized configuration via Config Server

---

## PHASE A: Eureka Server & Gateway Infrastructure

### Task 1: Create Eureka Server Microservice

**Files:**
- Create: `eureka-server/pom.xml`
- Create: `eureka-server/src/main/java/com/bank/eureka/EurekaServerApplication.java`
- Create: `eureka-server/src/main/resources/application.yml`

**Interfaces:**
- Produces: Eureka registry at `http://localhost:8761/eureka`

- [ ] **Step 1: Create Eureka Server pom.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.1</version>
        <relativePath/>
    </parent>
    <groupId>com.bank</groupId>
    <artifactId>eureka-server</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <name>eureka-server</name>
    <description>Eureka Service Registry</description>
    <properties>
        <java.version>17</java.version>
        <spring-cloud.version>2023.0.2</spring-cloud.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>${spring-cloud.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

- [ ] **Step 2: Create EurekaServerApplication.java**

```java
package com.bank.eureka;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;

/**
 * Eureka Service Registry Server.
 * Provides service discovery for all bank microservices.
 */
@SpringBootApplication
@EnableEurekaServer
public class EurekaServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(EurekaServerApplication.class, args);
    }
}
```

- [ ] **Step 3: Create application.yml**

```yaml
server:
  port: 8761

eureka:
  client:
    register-with-eureka: false
    fetch-registry: false
    service-url:
      defaultZone: http://localhost:8761/eureka/
  server:
    enable-self-preservation: false

spring:
  application:
    name: eureka-server

management:
  endpoints:
    web:
      exposure:
        include: health,info
```

- [ ] **Step 4: Verify build**

Run: `cd eureka-server && mvn clean compile -q`
Expected: BUILD SUCCESS

---

### Task 2: Create Gateway Service Microservice

**Files:**
- Create: `gateway-service/pom.xml`
- Create: `gateway-service/src/main/java/com/bank/gateway/GatewayServiceApplication.java`
- Create: `gateway-service/src/main/java/com/bank/gateway/config/RouteConfig.java`
- Create: `gateway-service/src/main/resources/application.yml`

**Interfaces:**
- Consumes: Eureka registry at `http://localhost:8761/eureka`
- Produces: API Gateway at `http://localhost:8080`

- [ ] **Step 1: Create Gateway pom.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.1</version>
        <relativePath/>
    </parent>
    <groupId>com.bank</groupId>
    <artifactId>gateway-service</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <name>gateway-service</name>
    <description>API Gateway Service</description>
    <properties>
        <java.version>17</java.version>
        <spring-cloud.version>2023.0.2</spring-cloud.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-gateway</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>${spring-cloud.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

- [ ] **Step 2: Create GatewayServiceApplication.java**

```java
package com.bank.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * API Gateway Service.
 * Routes requests to backend microservices via Eureka discovery.
 */
@SpringBootApplication
@EnableDiscoveryClient
public class GatewayServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(GatewayServiceApplication.class, args);
    }
}
```

- [ ] **Step 3: Create RouteConfig.java**

```java
package com.bank.gateway.config;

import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Gateway route configuration.
 * Defines routes to all backend microservices using Eureka service discovery.
 */
@Configuration
public class RouteConfig {

    /**
     * Configures routes for all bank microservices.
     *
     * @param builder the route locator builder
     * @return configured route locator
     */
    @Bean
    public RouteLocator customRoutes(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("customer-service", r -> r
                        .path("/api/v1/customers/**")
                        .filters(f -> f.stripPrefix(0))
                        .uri("lb://customer-service"))
                .route("account-service", r -> r
                        .path("/api/v1/accounts/**")
                        .filters(f -> f.stripPrefix(0))
                        .uri("lb://account-service"))
                .route("credit-service", r -> r
                        .path("/api/v1/credits/**")
                        .filters(f -> f.stripPrefix(0))
                        .uri("lb://credit-service"))
                .route("transaction-service", r -> r
                        .path("/api/v1/transactions/**")
                        .filters(f -> f.stripPrefix(0))
                        .uri("lb://transaction-service"))
                .route("fraud-detection-service", r -> r
                        .path("/api/v1/fraud/**")
                        .filters(f -> f.stripPrefix(0))
                        .uri("lb://fraud-detection-service"))
                .build();
    }
}
```

- [ ] **Step 4: Create application.yml**

```yaml
server:
  port: 8080

spring:
  application:
    name: gateway-service
  cloud:
    discovery:
      enabled: true

eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
  instance:
    prefer-ip-address: true

management:
  endpoints:
    web:
      exposure:
        include: health,info,gateway
```

- [ ] **Step 5: Verify build**

Run: `cd gateway-service && mvn clean compile -q`
Expected: BUILD SUCCESS

---

### Task 3: Enable Eureka Client in All Existing Services

**Files:**
- Modify: `customer-service/pom.xml`
- Modify: `account-service/pom.xml`
- Modify: `credit-service/pom.xml`
- Modify: `transaction-service/pom.xml`
- Modify: `fraud-detection-service/pom.xml`
- Modify: `*/src/main/resources/application.yml` (add eureka config)

**Interfaces:**
- Consumes: Eureka registry at `http://localhost:8761/eureka`

- [ ] **Step 1: Add Eureka Client dependency to customer-service pom.xml**

Add inside `<dependencies>`:
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

- [ ] **Step 2: Repeat for account-service, credit-service, transaction-service, fraud-detection-service**

- [ ] **Step 3: Add Eureka config to customer-service application.yml**

```yaml
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
  instance:
    prefer-ip-address: true
```

- [ ] **Step 4: Repeat eureka config for all other services**

- [ ] **Step 5: Verify all services compile**

Run: `cd customer-service && mvn clean compile -q && cd ../account-service && mvn clean compile -q`
Expected: All BUILD SUCCESS

---

## PHASE B: Checkstyle & JaCoCo

### Task 4: Add Checkstyle Plugin to All Services

**Files:**
- Modify: `*/pom.xml` (add checkstyle plugin)

- [ ] **Step 1: Add Checkstyle plugin to customer-service pom.xml**

Add inside `<build><plugins>`:
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-checkstyle-plugin</artifactId>
    <version>3.3.1</version>
    <configuration>
        <configLocation>google_checks.xml</configLocation>
        <consoleOutput>true</consoleOutput>
        <failsOnError>false</failsOnError>
        <violationSeverity>warning</violationSeverity>
    </configuration>
    <dependencies>
        <dependency>
            <groupId>com.puppycrawl.tools</groupId>
            <artifactId>checkstyle</artifactId>
            <version>10.17.0</version>
        </dependency>
    </dependencies>
</plugin>
```

- [ ] **Step 2: Repeat for all other services (account, credit, transaction, fraud-detection, config-server, eureka-server, gateway-service)**

- [ ] **Step 3: Run checkstyle on customer-service**

Run: `cd customer-service && mvn checkstyle:check -q`
Expected: Warnings but no errors (failsOnError=false)

---

### Task 5: Add JaCoCo Plugin to All Services

**Files:**
- Modify: `*/pom.xml` (add jacoco plugin)

- [ ] **Step 1: Add JaCoCo plugin to customer-service pom.xml**

Add inside `<build><plugins>`:
```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.11</version>
    <executions>
        <execution>
            <goals>
                <goal>prepare-agent</goal>
            </goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals>
                <goal>report</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

- [ ] **Step 2: Repeat for all other services**

- [ ] **Step 3: Generate JaCoCo report for customer-service**

Run: `cd customer-service && mvn test jacoco:report -q`
Expected: Report generated at `customer-service/target/site/jacoco/index.html`

---

## PHASE C: Circuit Breaker (Resilience4j)

### Task 6: Add Resilience4j Dependencies

**Files:**
- Modify: `*/pom.xml` (add resilience4j)

- [ ] **Step 1: Add Resilience4j to customer-service pom.xml**

Add inside `<dependencies>`:
```xml
<dependency>
    <groupId>io.github.resilience4j</groupId>
    <artifactId>resilience4j-spring-boot3</artifactId>
    <version>2.2.0</version>
</dependency>
<dependency>
    <groupId>io.github.resilience4j</groupId>
    <artifactId>resilience4j-reactor</artifactId>
    <version>2.2.0</version>
</dependency>
```

- [ ] **Step 2: Repeat for account-service, credit-service, transaction-service, fraud-detection-service**

- [ ] **Step 3: Add CircuitBreaker config to customer-service application.yml**

```yaml
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

- [ ] **Step 4: Repeat config for all other services**

- [ ] **Step 5: Verify compilation**

Run: `cd customer-service && mvn clean compile -q`
Expected: BUILD SUCCESS

---

## PHASE D: Unit Tests

### Task 7: Customer Domain Service Tests

**Files:**
- Create: `customer-service/src/test/java/com/bank/customer/domain/service/CustomerDomainServiceTest.java`

**Interfaces:**
- Consumes: CustomerDomainService, Customer model

- [ ] **Step 1: Write failing test**

```java
package com.bank.customer.domain.service;

import com.bank.customer.domain.model.Customer;
import com.bank.customer.domain.model.CustomerType;
import com.bank.customer.domain.model.CustomerProfile;
import com.bank.customer.domain.model.PersonalData;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class CustomerDomainServiceTest {

    private CustomerDomainService domainService;

    @BeforeEach
    void setUp() {
        domainService = new CustomerDomainService();
    }

    @Test
    void shouldCreatePersonalCustomer() {
        Customer customer = Customer.builder()
                .customerType(CustomerType.PERSONAL)
                .customerProfile(CustomerProfile.STANDARD)
                .personalData(PersonalData.builder()
                        .firstName("John")
                        .lastName("Doe")
                        .build())
                .build();

        assertNotNull(customer);
        assertEquals(CustomerType.PERSONAL, customer.getCustomerType());
        assertTrue(customer.isPersonalCustomer());
        assertFalse(customer.isBusinessCustomer());
    }

    @Test
    void shouldCreateBusinessCustomer() {
        Customer customer = Customer.builder()
                .customerType(CustomerType.BUSINESS)
                .customerProfile(CustomerProfile.STANDARD_BUSINESS)
                .build();

        assertNotNull(customer);
        assertTrue(customer.isBusinessCustomer());
        assertFalse(customer.isPersonalCustomer());
    }

    @Test
    void shouldIdentifyVipCustomer() {
        Customer customer = Customer.builder()
                .customerType(CustomerType.PERSONAL)
                .customerProfile(CustomerProfile.VIP)
                .build();

        assertTrue(customer.isVipCustomer());
    }

    @Test
    void shouldIdentifyPymeCustomer() {
        Customer customer = Customer.builder()
                .customerType(CustomerType.BUSINESS)
                .customerProfile(CustomerProfile.PYME)
                .build();

        assertTrue(customer.isPymeCustomer());
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd customer-service && mvn test -Dtest=CustomerDomainServiceTest -q`
Expected: FAIL (depends on Customer builder implementation)

- [ ] **Step 3: Fix any missing builder annotations (if needed)**

Ensure Customer class has `@Builder` Lombok annotation.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd customer-service && mvn test -Dtest=CustomerDomainServiceTest -q`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add customer-service/src/test/java/com/bank/customer/domain/service/CustomerDomainServiceTest.java
git commit -m "test: add CustomerDomainService unit tests"
```

---

### Task 8: Account Domain Service Tests

**Files:**
- Create: `account-service/src/test/java/com/bank/account/domain/service/AccountDomainServiceTest.java`

- [ ] **Step 1: Write failing test**

```java
package com.bank.account.domain.service;

import com.bank.account.domain.model.*;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class AccountDomainServiceTest {

    @Test
    void shouldIdentifySavingsAccount() {
        Account account = Account.builder()
                .accountType(AccountType.SAVINGS)
                .status(AccountStatus.ACTIVE)
                .balance(Balance.builder()
                        .available(BigDecimal.ZERO)
                        .currency("PEN")
                        .build())
                .holders(List.of(AccountHolder.builder()
                        .customerId("c1")
                        .holderType(AccountHolder.HolderType.PRIMARY)
                        .build()))
                .build();

        assertTrue(account.isSavingsAccount());
        assertFalse(account.isCheckingAccount());
        assertFalse(account.isFixedTermAccount());
    }

    @Test
    void shouldIdentifyCheckingAccount() {
        Account account = Account.builder()
                .accountType(AccountType.CHECKING)
                .status(AccountStatus.ACTIVE)
                .build();

        assertTrue(account.isCheckingAccount());
    }

    @Test
    void shouldIdentifyFixedTermAccount() {
        Account account = Account.builder()
                .accountType(AccountType.FIXED_TERM)
                .status(AccountStatus.ACTIVE)
                .build();

        assertTrue(account.isFixedTermAccount());
    }

    @Test
    void shouldDetectMaxFreeTransactionsReached() {
        Account account = Account.builder()
                .accountType(AccountType.CHECKING)
                .maxFreeTransactions(5)
                .currentTransactionCount(6)
                .build();

        assertTrue(account.hasReachedMaxFreeTransactions());
    }

    @Test
    void shouldDetectActiveAccount() {
        Account account = Account.builder()
                .status(AccountStatus.ACTIVE)
                .build();

        assertTrue(account.isActive());
    }

    @Test
    void shouldCalculateBalanceTotal() {
        Balance balance = Balance.builder()
                .available(new BigDecimal("1000.00"))
                .pending(new BigDecimal("200.00"))
                .currency("PEN")
                .build();

        balance.calculateTotal();

        assertEquals(new BigDecimal("1200.00"), balance.getTotal());
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd account-service && mvn test -Dtest=AccountDomainServiceTest -q`
Expected: FAIL (depends on model builders)

- [ ] **Step 3: Ensure models have @Builder annotations**

- [ ] **Step 4: Run test to verify it passes**

Run: `cd account-service && mvn test -Dtest=AccountDomainServiceTest -q`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add account-service/src/test/java/com/bank/account/domain/service/AccountDomainServiceTest.java
git commit -m "test: add AccountDomainService unit tests"
```

---

### Task 9: Credit Domain Service Tests

**Files:**
- Create: `credit-service/src/test/java/com/bank/credit/domain/service/CreditDomainServiceTest.java`

- [ ] **Step 1: Write failing test**

```java
package com.bank.credit.domain.service;

import com.bank.credit.domain.model.*;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

class CreditDomainServiceTest {

    @Test
    void shouldIdentifyPersonalCredit() {
        Credit credit = Credit.builder()
                .creditType(CreditType.PERSONAL)
                .status(CreditStatus.ACTIVE)
                .creditLimit(CreditLimit.builder()
                        .approved(new BigDecimal("10000"))
                        .available(new BigDecimal("10000"))
                        .used(BigDecimal.ZERO)
                        .currency("PEN")
                        .build())
                .build();

        assertTrue(credit.isPersonalCredit());
        assertFalse(credit.isBusinessCredit());
        assertFalse(credit.isCreditCard());
    }

    @Test
    void shouldIdentifyCreditCard() {
        Credit credit = Credit.builder()
                .creditType(CreditType.CREDIT_CARD)
                .status(CreditStatus.ACTIVE)
                .build();

        assertTrue(credit.isCreditCard());
    }

    @Test
    void shouldDetectActiveCredit() {
        Credit credit = Credit.builder()
                .status(CreditStatus.ACTIVE)
                .build();

        assertTrue(credit.isActive());
    }

    @Test
    void shouldCalculateAvailableCredit() {
        CreditLimit limit = CreditLimit.builder()
                .approved(new BigDecimal("10000"))
                .used(new BigDecimal("3000"))
                .currency("PEN")
                .build();

        limit.calculateAvailable();

        assertEquals(new BigDecimal("7000"), limit.getAvailable());
    }
}
```

- [ ] **Step 2: Run test, fix builders, run again**

Run: `cd credit-service && mvn test -Dtest=CreditDomainServiceTest -q`
Expected: PASS after ensuring @Builder on models

- [ ] **Step 3: Commit**

---

### Task 10: Transaction Domain Service Tests

**Files:**
- Create: `transaction-service/src/test/java/com/bank/transaction/domain/service/TransactionDomainServiceTest.java`

- [ ] **Step 1: Write failing test**

```java
package com.bank.transaction.domain.service;

import com.bank.transaction.domain.model.*;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

class TransactionDomainServiceTest {

    @Test
    void shouldCreateDepositTransaction() {
        Transaction tx = Transaction.builder()
                .transactionType(TransactionType.DEPOSIT)
                .accountId("acc1")
                .customerId("cust1")
                .amount(new BigDecimal("500.00"))
                .currency("PEN")
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDateTime.now())
                .build();

        assertEquals(TransactionType.DEPOSIT, tx.getTransactionType());
        assertEquals(TransactionStatus.COMPLETED, tx.getStatus());
    }

    @Test
    void shouldCreateTransferTransaction() {
        Transaction tx = Transaction.builder()
                .transactionType(TransactionType.TRANSFER)
                .accountId("acc1")
                .destinationAccountId("acc2")
                .customerId("cust1")
                .amount(new BigDecimal("200.00"))
                .currency("PEN")
                .status(TransactionStatus.PENDING)
                .build();

        assertEquals(TransactionType.TRANSFER, tx.getTransactionType());
        assertNotNull(tx.getDestinationAccountId());
    }

    @Test
    void shouldCreateCreditPaymentTransaction() {
        Transaction tx = Transaction.builder()
                .transactionType(TransactionType.CREDIT_PAYMENT)
                .creditId("cred1")
                .customerId("cust1")
                .amount(new BigDecimal("1000.00"))
                .currency("PEN")
                .status(TransactionStatus.COMPLETED)
                .build();

        assertEquals(TransactionType.CREDIT_PAYMENT, tx.getTransactionType());
    }
}
```

- [ ] **Step 2: Run test, fix builders, run again**

Run: `cd transaction-service && mvn test -Dtest=TransactionDomainServiceTest -q`
Expected: PASS

- [ ] **Step 3: Commit**

---

### Task 11: Customer Controller Tests

**Files:**
- Create: `customer-service/src/test/java/com/bank/customer/adapter/inbound/web/CustomerControllerTest.java`

**Interfaces:**
- Consumes: CreateCustomerUseCase, FindCustomerUseCase, UpdateCustomerUseCase, DeleteCustomerUseCase
- Produces: REST endpoints at `/api/v1/customers`

- [ ] **Step 1: Write failing test**

```java
package com.bank.customer.adapter.inbound.web;

import com.bank.customer.adapter.inbound.web.dto.CustomerRequest;
import com.bank.customer.adapter.inbound.web.dto.CustomerResponse;
import com.bank.customer.application.service.CreateCustomerServiceImpl;
import com.bank.customer.application.service.DeleteCustomerServiceImpl;
import com.bank.customer.application.service.FindCustomerServiceImpl;
import com.bank.customer.application.service.UpdateCustomerServiceImpl;
import com.bank.customer.domain.model.Customer;
import com.bank.customer.domain.model.CustomerType;
import com.bank.customer.domain.model.CustomerProfile;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.reactive.WebFluxTest;
import org.springframework.boot.test.mock.bean.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.reactive.server.WebTestClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@WebFluxTest(CustomerController.class)
class CustomerControllerTest {

    @Autowired
    private WebTestClient webTestClient;

    @MockBean
    private CreateCustomerServiceImpl createCustomerService;
    @MockBean
    private FindCustomerServiceImpl findCustomerService;
    @MockBean
    private UpdateCustomerServiceImpl updateCustomerService;
    @MockBean
    private DeleteCustomerServiceImpl deleteCustomerService;

    @Test
    void shouldCreateCustomer() {
        CustomerResponse response = CustomerResponse.builder()
                .id("1")
                .customerType(CustomerType.PERSONAL)
                .customerProfile(CustomerProfile.STANDARD)
                .build();

        when(createCustomerService.execute(any())).thenReturn(Mono.just(response));

        webTestClient.post()
                .uri("/api/v1/customers")
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(CustomerRequest.builder()
                        .customerType(CustomerType.PERSONAL)
                        .customerProfile(CustomerProfile.STANDARD)
                        .build())
                .exchange()
                .expectStatus().isOk()
                .expectBody(CustomerResponse.class)
                .value(r -> {
                    assert r.getId().equals("1");
                    assert r.getCustomerType() == CustomerType.PERSONAL;
                });
    }

    @Test
    void shouldFindCustomerById() {
        CustomerResponse response = CustomerResponse.builder()
                .id("1")
                .customerType(CustomerType.PERSONAL)
                .build();

        when(findCustomerService.findById("1")).thenReturn(Mono.just(response));

        webTestClient.get()
                .uri("/api/v1/customers/1")
                .exchange()
                .expectStatus().isOk()
                .expectBody(CustomerResponse.class)
                .value(r -> assert r.getId().equals("1"));
    }

    @Test
    void shouldFindAllCustomers() {
        CustomerResponse response = CustomerResponse.builder()
                .id("1")
                .customerType(CustomerType.PERSONAL)
                .build();

        when(findCustomerService.findAll()).thenReturn(Flux.just(response));

        webTestClient.get()
                .uri("/api/v1/customers")
                .exchange()
                .expectStatus().isOk()
                .expectBodyList(CustomerResponse.class)
                .hasSize(1);
    }

    @Test
    void shouldDeleteCustomer() {
        when(deleteCustomerService.execute("1")).thenReturn(Mono.empty());

        webTestClient.delete()
                .uri("/api/v1/customers/1")
                .exchange()
                .expectStatus().isOk();
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd customer-service && mvn test -Dtest=CustomerControllerTest -q`
Expected: FAIL

- [ ] **Step 3: Fix any missing imports/annotations**

- [ ] **Step 4: Run test to verify it passes**

Run: `cd customer-service && mvn test -Dtest=CustomerControllerTest -q`
Expected: PASS

- [ ] **Step 5: Commit**

---

### Task 12: Account Controller Tests

**Files:**
- Create: `account-service/src/test/java/com/bank/account/adapter/inbound/web/AccountControllerTest.java`

- [ ] **Step 1: Write failing test** (similar pattern to Customer, mock all use cases)

- [ ] **Step 2: Run test, fix, run again**

- [ ] **Step 3: Commit**

---

### Task 13: Credit Controller Tests

**Files:**
- Create: `credit-service/src/test/java/com/bank/credit/adapter/inbound/web/CreditControllerTest.java`

- [ ] **Step 1: Write failing test**

- [ ] **Step 2: Run test, fix, run again**

- [ ] **Step 3: Commit**

---

### Task 14: Transaction Controller Tests

**Files:**
- Create: `transaction-service/src/test/java/com/bank/transaction/adapter/inbound/web/TransactionControllerTest.java`

- [ ] **Step 1: Write failing test**

- [ ] **Step 2: Run test, fix, run again**

- [ ] **Step 3: Commit**

---

## PHASE E: Business Features

### Task 15: Transfer Endpoint

**Files:**
- Create: `transaction-service/src/main/java/com/bank/transaction/domain/port/in/CreateTransferUseCase.java`
- Create: `transaction-service/src/main/java/com/bank/transaction/application/service/CreateTransferServiceImpl.java`
- Modify: `transaction-service/src/main/java/com/bank/transaction/adapter/inbound/web/TransactionController.java`

**Interfaces:**
- Consumes: AccountRepositoryPort (to validate accounts), TransactionRepositoryPort
- Produces: POST `/api/v1/transactions/transfer`

- [ ] **Step 1: Write failing test for transfer**

```java
@Test
void shouldTransferBetweenAccounts() {
    // Given: source account with balance, destination account exists
    // When: transfer of 100 from acc1 to acc2
    // Then: two transactions created (debit + credit), balances updated
}
```

- [ ] **Step 2: Create CreateTransferUseCase interface**

```java
package com.bank.transaction.domain.port.in;

import com.bank.transaction.adapter.inbound.web.dto.TransferRequest;
import com.bank.transaction.adapter.inbound.web.dto.TransferResponse;
import reactor.core.publisher.Mono;

public interface CreateTransferUseCase {
    Mono<TransferResponse> execute(TransferRequest request);
}
```

- [ ] **Step 3: Create CreateTransferServiceImpl**

```java
package com.bank.transaction.application.service;

import com.bank.transaction.domain.port.in.CreateTransferUseCase;
import com.bank.transaction.domain.port.out.TransactionRepositoryPort;
import com.bank.transaction.domain.service.TransactionDomainService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

@Service
@RequiredArgsConstructor
public class CreateTransferServiceImpl implements CreateTransferUseCase {
    private final TransactionRepositoryPort repository;
    private final TransactionDomainService domainService;

    @Override
    public Mono<TransferResponse> execute(TransferRequest request) {
        // Validate source account has funds
        // Create debit transaction for source
        // Create credit transaction for destination
        // Return response
    }
}
```

- [ ] **Step 4: Add transfer endpoint to TransactionController**

```java
@PostMapping("/transfer")
public Mono<TransferResponse> transfer(@RequestBody TransferRequest request) {
    return createTransferUseCase.execute(request);
}
```

- [ ] **Step 5: Run test, fix, run again**

- [ ] **Step 6: Commit**

---

### Task 16: VIP/PYME Account Validation

**Files:**
- Modify: `account-service/src/main/java/com/bank/account/application/service/CreateAccountServiceImpl.java`

- [ ] **Step 1: Write failing test**

```java
@Test
void shouldRejectVipSavingsWithoutCreditCard() {
    // Given: VIP customer without credit card
    // When: try to create savings account
    // Then: exception thrown
}
```

- [ ] **Step 2: Add validation logic**

```java
// In CreateAccountServiceImpl.execute():
if (customer.isVipCustomer() && account.isSavingsAccount()) {
    // Check if customer has active credit card via credit-service
    // If not, throw BusinessException
}
if (customer.isPymeCustomer() && account.isCheckingAccount()) {
    // Set maintenanceFee to 0
}
```

- [ ] **Step 3: Run test, fix, run again**

- [ ] **Step 4: Commit**

---

### Task 17: Transaction Commission Logic

**Files:**
- Modify: `transaction-service/src/main/java/com/bank/transaction/domain/service/TransactionDomainService.java`

- [ ] **Step 1: Write failing test**

```java
@Test
void shouldApplyFeeWhenExceedingMaxFreeTransactions() {
    // Given: account with maxFreeTransactions=5, currentTransactionCount=6
    // When: process transaction
    // Then: fee applied
}
```

- [ ] **Step 2: Implement commission logic in TransactionDomainService**

```java
public BigDecimal calculateTransactionFee(Account account) {
    if (account.hasReachedMaxFreeTransactions()) {
        return account.getMaintenanceFee();
    }
    return BigDecimal.ZERO;
}
```

- [ ] **Step 3: Run test, fix, run again**

- [ ] **Step 4: Commit**

---

### Task 18: Credit Card Charge Endpoint

**Files:**
- Create: `credit-service/src/main/java/com/bank/credit/domain/port/in/ChargeCreditUseCase.java`
- Create: `credit-service/src/main/java/com/bank/credit/application/service/ChargeCreditServiceImpl.java`
- Modify: `credit-service/src/main/java/com/bank/credit/adapter/inbound/web/CreditController.java`

- [ ] **Step 1: Write failing test**

```java
@Test
void shouldChargeCreditCard() {
    // Given: credit card with available limit 5000
    // When: charge 1000
    // Then: available reduced to 4000, current balance increased to 1000
}
```

- [ ] **Step 2: Create use case and service**

- [ ] **Step 3: Add endpoint: POST /api/v1/credits/{id}/charge**

- [ ] **Step 4: Run test, fix, run again**

- [ ] **Step 5: Commit**

---

### Task 19: Credit Payment Endpoint

**Files:**
- Create: `credit-service/src/main/java/com/bank/credit/domain/port/in/PayCreditUseCase.java`
- Create: `credit-service/src/main/java/com/bank/credit/application/service/PayCreditServiceImpl.java`
- Modify: `credit-service/src/main/java/com/bank/credit/adapter/inbound/web/CreditController.java`

- [ ] **Step 1: Write failing test**

```java
@Test
void shouldProcessCreditPayment() {
    // Given: credit with current balance 3000
    // When: payment of 1000
    // Then: balance reduced to 2000, available limit increased
}
```

- [ ] **Step 2: Create use case and service**

- [ ] **Step 3: Add endpoint: POST /api/v1/credits/{id}/payment**

- [ ] **Step 4: Run test, fix, run again**

- [ ] **Step 5: Commit**

---

## PHASE F: Dockerfiles

### Task 20: Create Dockerfiles for All Services

**Files:**
- Create: `eureka-server/Dockerfile`
- Create: `gateway-service/Dockerfile`
- Create: `customer-service/Dockerfile`
- Create: `account-service/Dockerfile`
- Create: `credit-service/Dockerfile`
- Create: `transaction-service/Dockerfile`
- Create: `fraud-detection-service/Dockerfile`
- Create: `config-server/Dockerfile`

- [ ] **Step 1: Create customer-service Dockerfile**

```dockerfile
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests -B

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
```

- [ ] **Step 2: Create similar Dockerfiles for all services (adjust EXPOSE port)**

- [ ] **Step 3: Build and test customer-service Docker image**

Run: `docker build -t customer-service ./customer-service`
Expected: Successfully built

- [ ] **Step 4: Commit all Dockerfiles**

---

### Task 21: Update docker-compose.yml

**Files:**
- Modify: `docker-compose.yml`

- [ ] **Step 1: Add all services to docker-compose.yml**

Add eureka-server, gateway-service, and all business services with proper depends_on, ports, and environment variables.

- [ ] **Step 2: Run docker-compose up**

Run: `docker-compose up -d`
Expected: All services start

- [ ] **Step 3: Commit**

---

## Self-Review Checklist

- [ ] All 8 microservices compile successfully
- [ ] Eureka dashboard accessible at http://localhost:8761
- [ ] All services registered in Eureka
- [ ] Gateway routes working
- [ ] CircuitBreaker configured with 2s timeout
- [ ] Checkstyle runs without errors
- [ ] JaCoCo reports generated
- [ ] All unit tests pass
- [ ] Transfer endpoint functional
- [ ] VIP/PYME validation works
- [ ] Transaction commissions applied
- [ ] Credit charge/payment endpoints work
- [ ] Docker containers start and communicate
