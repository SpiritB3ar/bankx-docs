# Banking System - Documentation

## Overview

This directory contains the UML diagrams and OpenAPI contracts for the Banking System microservices.

## Directory Structure

```
docs/
├── uml/
│   ├── architecture-diagram.drawio          # Overall system architecture
│   ├── hexagonal-architecture.drawio        # Hexagonal architecture pattern
│   └── fraud-detection-sequence.drawio      # Fraud detection flow sequence
├── openapi/
│   ├── customer-service-api.yaml            # Customer Service API contract
│   ├── account-service-api.yaml             # Account Service API contract
│   ├── credit-service-api.yaml              # Credit Service API contract
│   ├── transaction-service-api.yaml         # Transaction Service API contract
│   └── fraud-detection-service-api.yaml     # Fraud Detection Service API contract
└── README.md                                # This file
```

## UML Diagrams

### 1. Architecture Diagram (`architecture-diagram.drawio`)

**Purpose**: Shows the overall microservices architecture of the banking system.

**Key Components**:
- External Clients (Postman/API)
- API Gateway (Spring Cloud Gateway)
- Config Server (Port 8888)
- Eureka Server (Port 8761)
- Business Microservices (Customer, Account, Credit, Transaction)
- Fraud Detection Service (with Spring AI + Gemini)
- MongoDB databases (Database per Service pattern)
- Apache Kafka (Message Broker)

**How to Use**:
1. Open the `.drawio` file in [draw.io](https://app.diagrams.net/)
2. Edit diagrams as needed
3. Export to PNG/PDF for documentation

### 2. Hexagonal Architecture Diagram (`hexagonal-architecture.drawio`)

**Purpose**: Shows the internal structure of each microservice following hexagonal architecture (Ports & Adapters pattern).

**Layers**:
- **Inbound Adapters**: REST Controllers, Kafka Listeners, DTOs, Mappers
- **Inbound Ports**: Use Cases (Create, Find, Update, Delete)
- **Domain Layer**: Domain Model, Domain Service
- **Outbound Ports**: Repository Ports, Event Publisher Ports
- **Outbound Adapters**: Persistence Adapter, Kafka Producer, AI Adapter

### 3. Fraud Detection Sequence Diagram (`fraud-detection-sequence.drawio`)

**Purpose**: Shows the flow of transaction analysis for fraud detection.

**Flow**:
1. Client creates a transaction
2. Transaction Service saves to MongoDB
3. Transaction Service publishes event to Kafka
4. Fraud Detection Service consumes event
5. Customer history is retrieved from MongoDB
6. Gemini AI analyzes the transaction
7. Fraud alert is saved to MongoDB

## OpenAPI Contracts

### 1. Customer Service API (`customer-service-api.yaml`)

**Base URL**: `http://localhost:8081`

**Endpoints**:
- `POST /api/v1/customers` - Create customer
- `GET /api/v1/customers` - Find all customers
- `GET /api/v1/customers/{id}` - Find customer by ID
- `PUT /api/v1/customers/{id}` - Update customer
- `DELETE /api/v1/customers/{id}` - Delete customer
- `GET /api/v1/customers/customer-type/{customerType}` - Find by type
- `GET /api/v1/customers/document/{documentNumber}` - Find by document

### 2. Account Service API (`account-service-api.yaml`)

**Base URL**: `http://localhost:8082`

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

**Base URL**: `http://localhost:8083`

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

**Base URL**: `http://localhost:8084`

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

**Base URL**: `http://localhost:8085`

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

## Usage

### Viewing Diagrams

1. Go to [draw.io](https://app.diagrams.net/)
2. Click "Open Existing Diagram"
3. Select the `.drawio` file
4. Edit and export as needed

### Testing APIs

1. Import the OpenAPI YAML file into Postman:
   - Click "Import" in Postman
   - Select "File" tab
   - Choose the `.yaml` file
   - Postman will auto-generate the collection

2. Or use Swagger UI:
   - Each microservice exposes Swagger UI at `/swagger-ui.html`
   - Example: `http://localhost:8081/swagger-ui.html`

## Microservices Summary

| Service | Port | Database | API Documentation |
|---------|------|----------|-------------------|
| Config Server | 8888 | N/A | N/A |
| Customer Service | 8081 | customer_db | `/swagger-ui.html` |
| Account Service | 8082 | account_db | `/swagger-ui.html` |
| Credit Service | 8083 | credit_db | `/swagger-ui.html` |
| Transaction Service | 8084 | transaction_db | `/swagger-ui.html` |
| Fraud Detection | 8085 | fraud_db | `/swagger-ui.html` |
