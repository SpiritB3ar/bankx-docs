# Banking System - Microservices Project

## Overview

A complete banking system built with microservices architecture, following hexagonal architecture (Ports & Adapters) pattern, reactive programming with Spring WebFlux, and AI-powered fraud detection.

## Project Structure

```
banksystem/
├── config-server/                    # Configuration Server
├── customer-service/                 # Customer Management
├── account-service/                  # Account Management
├── credit-service/                   # Credit Products Management
├── transaction-service/              # Transaction Management
├── fraud-detection-service/          # Fraud Detection with AI
├── docs/                             # Documentation
│   ├── uml/                          # UML Diagrams (draw.io)
│   └── openapi/                      # OpenAPI Contracts
├── start-infra.ps1                   # Start all infrastructure
├── kafka-setup.ps1                   # Kafka setup script
├── kafka-cleanup.ps1                 # Kafka cleanup script
├── kafka-test.ps1                    # Kafka test script
├── mongo-setup.ps1                   # MongoDB setup script
├── mongo-cleanup.ps1                 # MongoDB cleanup script
├── setup-repos.ps1                   # Git repository setup script
├── docker-compose.yml                # Docker/Podman Compose (Kafka)
├── podman-compose.yml                # Podman Compose (Kafka with topics)
├── mongo-compose.yml                 # Podman Compose (MongoDB)
├── KAFKA-SETUP.md                    # Kafka documentation
├── MONGO-SETUP.md                    # MongoDB documentation
└── README.md                         # This file
```

## Microservices

| Service | Port | Database | Description |
|---------|------|----------|-------------|
| **Config Server** | 8888 | N/A | Centralized configuration |
| **Customer Service** | 8081 | customer_db | Customer management |
| **Account Service** | 8082 | account_db | Bank accounts management |
| **Credit Service** | 8083 | credit_db | Credit products management |
| **Transaction Service** | 8084 | transaction_db | Transaction management |
| **Fraud Detection** | 8085 | fraud_db | AI-powered fraud detection |

## Technology Stack

- **Java 17**
- **Spring Boot 3.3.1**
- **Spring WebFlux** (Reactive Programming)
- **Spring Cloud Config** (Externalized Configuration)
- **MongoDB** (Database per Service)
- **Apache Kafka** (Event-Driven Architecture)
- **Spring AI with Gemini AI** (Fraud Detection)
- **MapStruct** (Object Mapping)
- **Lombok** (Code Reduction)
- **Springdoc OpenAPI** (API Documentation)

## Architecture

### Hexagonal Architecture (Ports & Adapters)

Each microservice follows hexagonal architecture:

- **Domain Layer**: Business logic, entities, use cases
- **Application Layer**: Application services
- **Adapter Inbound**: REST controllers, Kafka listeners
- **Adapter Outbound**: MongoDB repositories, Kafka producers

### Key Features

1. **Reactive Programming**: Non-blocking I/O with WebFlux
2. **Database per Service**: Each service has its own MongoDB database
3. **Event-Driven**: Kafka for inter-service communication
4. **AI-Powered Fraud Detection**: Gemini AI for transaction analysis
5. **Externalized Configuration**: Spring Cloud Config Server

## Prerequisites

- Java 17 or higher
- Maven 3.8+
- Podman (or Docker)
- Git

## Getting Started

### Prerequisites

- Java 17 or higher
- Maven 3.8+
- Podman (or Docker)
- Git

### 1. Start Infrastructure (Podman)

```powershell
# Start all infrastructure (MongoDB + Kafka)
.\start-infra.ps1

# Or start individually:
.\mongo-setup.ps1    # Start MongoDB
.\kafka-setup.ps1    # Start Kafka
```

### 2. Start Config Server

```powershell
cd config-server
mvn spring-boot:run
```

### 3. Start Microservices

```powershell
# Start each service in a separate terminal
cd customer-service && mvn spring-boot:run
cd account-service && mvn spring-boot:run
cd credit-service && mvn spring-boot:run
cd transaction-service && mvn spring-boot:run
cd fraud-detection-service && mvn spring-boot:run
```

### 4. Access Services

| Service | URL |
|---------|-----|
| **Config Server** | http://localhost:8888 |
| **Customer Service** | http://localhost:8081/swagger-ui.html |
| **Account Service** | http://localhost:8082/swagger-ui.html |
| **Credit Service** | http://localhost:8083/swagger-ui.html |
| **Transaction Service** | http://localhost:8084/swagger-ui.html |
| **Fraud Detection** | http://localhost:8085/swagger-ui.html |
| **Mongo Express** | http://localhost:8081 (MongoDB UI) |
| **Kafka UI** | http://localhost:8080 |

### Infrastructure Services

| Service | Port | URL |
|---------|------|-----|
| **MongoDB** | 27017 | mongodb://admin:admin123@localhost:27017 |
| **Mongo Express** | 8081 | http://localhost:8081 |
| **Kafka** | 9092 | localhost:9092 |
| **Kafka UI** | 8080 | http://localhost:8080 |
| **Zookeeper** | 2181 | localhost:2181

## API Documentation

OpenAPI contracts are available in `docs/openapi/` directory:

- `customer-service-api.yaml`
- `account-service-api.yaml`
- `credit-service-api.yaml`
- `transaction-service-api.yaml`
- `fraud-detection-service-api.yaml`

## UML Diagrams

Architecture and sequence diagrams are available in `docs/uml/` directory:

- `architecture-diagram.drawio` - System architecture
- `hexagonal-architecture.drawio` - Hexagonal pattern
- `fraud-detection-sequence.drawio` - Fraud detection flow

## Git Repositories Setup

Each microservice should have its own Git repository. Run the setup script:

```powershell
.\setup-repos.ps1 -GitHubUsername "YOUR_USERNAME"
```

Or follow the manual setup guide in `docs/GIT-REPOSITORIES-SETUP.md`.

## Business Rules

### Customer Types
- **Personal**: Individual customers
- **Business**: Corporate customers
- **VIP**: Personal customers with premium benefits
- **PYME**: Small business customers

### Account Types
- **Savings (Ahorro)**: No maintenance fee, limited transactions
- **Checking (Corriente)**: Maintenance fee, unlimited transactions
- **Fixed-term (Plazo Fijo)**: No maintenance fee, one transaction per month

### Credit Types
- **Personal**: One active credit per customer
- **Business**: Multiple credits allowed
- **Credit Card**: Revolving credit with minimum payment

### Fraud Detection
- **Risk Score 0-39**: Auto approve
- **Risk Score 40-69**: Manual review required
- **Risk Score 70-89**: Transaction blocked
- **Risk Score 90-100**: Immediate block and alert

## Development

### Code Style

- All class/method names in English
- Classes and methods must be commented
- Use Lombok for code reduction
- Use MapStruct for object mapping
- Follow hexagonal architecture

### Testing

```bash
# Run tests for a service
cd customer-service
mvn test

# Run tests with coverage
mvn test jacoco:report
```

## License

This project is for educational purposes.
