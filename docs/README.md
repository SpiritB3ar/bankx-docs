# Banking System - Documentation

## Overview

This directory contains the UML diagrams and OpenAPI contracts for the Banking System microservices.

## Directory Structure

```
docs/
├── uml/
│   ├── architecture-diagram.drawio          # Overall system architecture (AKS / APIM)
│   ├── deployment-architecture.drawio        # AKS deployment architecture
│   ├── microservices-interaction.drawio      # Inter-service interaction via APIM + Kafka
│   ├── hexagonal-architecture.drawio         # Hexagonal architecture pattern
│   ├── kafka-topics.drawio                   # Kafka topics (Event Hubs)
│   └── fraud-detection-sequence.drawio       # Fraud detection flow sequence
├── diagrams/
│   ├── sequence-auth-jwt-flow.drawio         # Auth / JWT login flow
│   ├── sequence-account-operations.drawio    # Account operations
│   ├── sequence-credit-operations.drawio     # Credit operations
│   ├── sequence-transaction-operations.drawio# Transaction operations
│   ├── sequence-debt-check-kafka.drawio      # Debt-check via Kafka
│   ├── sequence-fraud-detection.drawio       # Fraud detection
│   ├── sequence-third-party-payment.drawio   # Third-party credit payment
│   └── sequence-yanki-wallet.drawio          # Yanki wallet
├── openapi/
│   ├── customer-service-api.yaml             # Customer Service API contract
│   ├── account-service-api.yaml              # Account Service API contract
│   ├── credit-service-api.yaml               # Credit Service API contract
│   ├── transaction-service-api.yaml          # Transaction Service API contract
│   ├── fraud-detection-service-api.yaml       # Fraud Detection Service API contract
│   ├── auth-service-api.yaml                 # Auth Service API contract
│   └── yanki-service-api.yaml                # Yanki Service API contract
└── README.md                                 # This file
```

## UML Diagrams

### 1. Architecture Diagram (`architecture-diagram.drawio`)

**Purpose**: Shows the overall microservices architecture deployed on AKS, exposed through Azure API Management.

**Key Components**:
- External Clients (Postman / API consumers)
- Azure API Management (`apim-bankx`) — single entry point, JWT validation
- 7 Business Microservices (Customer, Account, Credit, Transaction, Auth, Yanki, Fraud Detection)
- Fraud Detection Service (with Spring AI + Gemini)
- Azure Cosmos DB (MongoDB API) — database per service
- Azure Event Hubs (Kafka) — inter-service messaging
- Azure Cache for Redis — catalog/cache acceleration

### 2. Deployment Architecture (`deployment-architecture.drawio`)

**Purpose**: Shows how the services run on AKS (`aks-bankx`, namespace `bankx`) behind ingress-nginx, with Cosmos DB and Event Hubs as managed Azure services.

### 3. Hexagonal Architecture Diagram (`hexagonal-architecture.drawio`)

**Purpose**: Shows the internal structure of each microservice following hexagonal architecture (Ports & Adapters pattern).

**Layers**:
- **Inbound Adapters**: REST Controllers, Kafka Listeners, DTOs, Mappers
- **Inbound Ports**: Use Cases (Create, Find, Update, Delete)
- **Domain Layer**: Domain Model, Domain Service
- **Outbound Ports**: Repository Ports, Event Publisher Ports
- **Outbound Adapters**: Persistence Adapter, Kafka Producer, AI Adapter

### 4. Microservices Interaction (`microservices-interaction.drawio`)

**Purpose**: Shows how clients reach services via APIM and how services communicate via Kafka (Event Hubs) — no REST calls between microservices.

### 5. Fraud Detection Sequence Diagram (`fraud-detection-sequence.drawio`)

**Purpose**: Shows the flow of transaction analysis for fraud detection.

**Flow**:
1. Client creates a transaction (via APIM → transaction-service)
2. Transaction Service saves to Cosmos DB (MongoDB API)
3. Transaction Service publishes event to Kafka (Event Hubs)
4. Fraud Detection Service consumes event
5. Customer / transaction history is retrieved from Cosmos DB
6. Gemini AI analyzes the transaction
7. Fraud alert is saved to Cosmos DB

## OpenAPI Contracts

All services are exposed under the APIM base URL `https://apim-bankx.azure-api.net`.
Local development base URLs are shown for reference only.

### 1. Customer Service API (`customer-service-api.yaml`)

**Base URL (APIM)**: `https://apim-bankx.azure-api.net/api/v1/customers`

**Endpoints**:
- `POST /api/v1/customers` - Create customer
- `GET /api/v1/customers` - Find all customers
- `GET /api/v1/customers/{id}` - Find customer by ID
- `PUT /api/v1/customers/{id}` - Update customer
- `DELETE /api/v1/customers/{id}` - Delete customer
- `GET /api/v1/customers/customer-type/{customerType}` - Find by type
- `GET /api/v1/customers/document/{documentNumber}` - Find by document

### 2. Account Service API (`account-service-api.yaml`)

**Base URL (APIM)**: `https://apim-bankx.azure-api.net/api/v1/accounts`

**Endpoints**:
- `POST /api/v1/accounts` - Create account
- `GET /api/v1/accounts` - Find all accounts
- `GET /api/v1/accounts/{id}` - Find account by ID
- `PUT /api/v1/accounts/{id}` - Update account
- `DELETE /api/v1/accounts/{id}` - Delete account
- `GET /api/v1/accounts/{id}/balance` - Get balance
- `GET /api/v1/accounts/customer/{customerId}` - Find by customer
- `POST /api/v1/accounts/{id}/holders` - Add holder

### 3. Credit Service API (`credit-service-api.yaml`)

**Base URL (APIM)**: `https://apim-bankx.azure-api.net/api/v1/credits`

**Endpoints**:
- `POST /api/v1/credits` - Create credit
- `GET /api/v1/credits` - Find all credits
- `GET /api/v1/credits/{id}` - Find credit by ID
- `PUT /api/v1/credits/{id}` - Update credit
- `DELETE /api/v1/credits/{id}` - Delete credit
- `GET /api/v1/credits/{id}/balance` - Get balance
- `GET /api/v1/credits/customer/{customerId}` - Find by customer
- `GET /api/v1/credits/type/{creditType}` - Find by type

### 4. Transaction Service API (`transaction-service-api.yaml`)

**Base URL (APIM)**: `https://apim-bankx.azure-api.net/api/v1/transactions`

**Endpoints**:
- `POST /api/v1/transactions` - Create transaction
- `GET /api/v1/transactions` - Find all transactions
- `GET /api/v1/transactions/{id}` - Find transaction by ID
- `DELETE /api/v1/transactions/{id}` - Delete transaction
- `PUT /api/v1/transactions/{id}/status` - Update status
- `PUT /api/v1/transactions/{id}/cancel` - Cancel transaction
- `GET /api/v1/transactions/account/{accountId}` - Find by account
- `GET /api/v1/transactions/customer/{customerId}` - Find by customer
- `GET /api/v1/transactions/credit/{creditId}` - Find by credit
- `GET /api/v1/transactions/account/{accountId}/last/{limit}` - Last N transactions
- `GET /api/v1/transactions/reports/date-range` - Report by date range

### 5. Fraud Detection Service API (`fraud-detection-service-api.yaml`)

**Base URL (APIM)**: `https://apim-bankx.azure-api.net/api/v1/fraud`

**Endpoints**:
- `POST /api/v1/fraud/analyze/{transactionId}` - Analyze transaction
- `GET /api/v1/fraud` - Find all alerts
- `GET /api/v1/fraud/{id}` - Find alert by ID
- `PUT /api/v1/fraud/{id}` - Update alert
- `DELETE /api/v1/fraud/{id}` - Delete alert
- `PUT /api/v1/fraud/{id}/resolve` - Resolve alert
- `GET /api/v1/fraud/customer/{customerId}` - Find by customer
- `GET /api/v1/fraud/status/{status}` - Find by status
- `GET /api/v1/fraud/risk-level/{riskLevel}` - Find by risk level
- `GET /api/v1/fraud/reports/date-range` - Report by date range

### 6. Auth Service API (`auth-service-api.yaml`)

**Base URL (APIM)**: `https://apim-bankx.azure-api.net/api/v1/auth`

**Endpoints**:
- `POST /api/v1/auth/register` - Register user (public)
- `POST /api/v1/auth/login` - Login → returns JWT (public)

### 7. Yanki Service API (`yanki-service-api.yaml`)

**Base URL (APIM)**: `https://apim-bankx.azure-api.net/api/v1/yanki/wallets`

**Endpoints**:
- `POST /api/v1/yanki/wallets` - Register wallet
- `GET /api/v1/yanki/wallets/{id}` - Find wallet by ID
- `GET /api/v1/yanki/wallets/phone/{phoneNumber}` - Find wallet by phone
- `POST /api/v1/yanki/wallets/{id}/send` - Send payment (by phone)
- `POST /api/v1/yanki/wallets/{id}/receive` - Receive payment (by phone)
- `POST /api/v1/yanki/wallets/{id}/link-debit-card` - Link debit card
- `GET /api/v1/yanki/wallets/{id}/balance` - Get balance

## Usage

### Viewing Diagrams

1. Go to [draw.io](https://app.diagrams.net/)
2. Click "Open Existing Diagram"
3. Select the `.drawio` file
4. Edit and export as needed

### Testing APIs

1. Import the OpenAPI YAML file into Postman, or use the pre-built collections in `docs/postman/`.
2. Set `baseUrl` to `https://apim-bankx.azure-api.net` and provide a `Bearer` JWT token.

## Microservices Summary

| Service | Database (Cosmos / MongoDB API) | Notes |
|---------|--------------------------------|-------|
| Customer Service | customer_db | Personal / Business customers |
| Account Service | account_db | Savings, checking, fixed-term |
| Credit Service | credit_db | Personal / Business loans, credit cards |
| Transaction Service | transaction_db | Deposits, withdrawals, transfers |
| Auth Service | auth_db | JWT issuance / validation |
| Yanki Service | yanki_db | Mobile wallet (phone-based) |
| Fraud Detection | fraud_db | Gemini AI risk analysis |
