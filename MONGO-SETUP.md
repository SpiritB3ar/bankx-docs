# MongoDB Setup with Podman

## Overview

This directory contains the MongoDB infrastructure setup for the Banking System using Podman.

## Components

| Component | Container Name | Port | Description |
|-----------|----------------|------|-------------|
| **MongoDB** | banking-mongodb | 27017 | NoSQL database |
| **Mongo Express** | banking-mongo-express | 8081 | Web UI for MongoDB |

## Quick Start

### Option 1: Using PowerShell Script (Recommended)

```powershell
# Start MongoDB services
.\mongo-setup.ps1

# Show status
.\mongo-setup.ps1 -Status

# Show logs
.\mongo-setup.ps1 -Logs

# Open MongoDB shell
.\mongo-setup.ps1 -Shell

# Stop services
.\mongo-setup.ps1 -Stop
```

### Option 2: Using Podman Compose

```bash
# Start services
podman-compose -f mongo-compose.yml up -d

# Stop services
podman-compose -f mongo-compose.yml down

# Show logs
podman-compose -f mongo-compose.yml logs -f
```

### Option 3: Using Podman Commands

```bash
# Create network
podman network create banking-network

# Start MongoDB
podman run -d \
  --name banking-mongodb \
  --hostname mongodb \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=admin123 \
  -v mongodb-data:/data/db \
  -v mongodb-config:/data/configdb \
  --network banking-network \
  mongo:6.0

# Start Mongo Express
podman run -d \
  --name banking-mongo-express \
  --hostname mongo-express \
  -p 8081:8081 \
  -e ME_CONFIG_MONGODB_ADMINUSERNAME=admin \
  -e ME_CONFIG_MONGODB_ADMINPASSWORD=admin123 \
  -e ME_CONFIG_MONGODB_URL=mongodb://admin:admin123@mongodb:27017/ \
  -e ME_CONFIG_BASICAUTH_USERNAME=admin \
  -e ME_CONFIG_BASICAUTH_PASSWORD=admin123 \
  -e ME_CONFIG_MONGODB_ENABLE_ADMIN=true \
  --network banking-network \
  mongo-express:latest
```

## Connection Information

### MongoDB Connection String

```
mongodb://admin:admin123@localhost:27017
```

### Credentials

| Field | Value |
|-------|-------|
| **Username** | admin |
| **Password** | admin123 |
| **Authentication Database** | admin |

### URLs

| Service | URL |
|---------|-----|
| **MongoDB** | mongodb://localhost:27017 |
| **Mongo Express** | http://localhost:8081 |

## Databases

Each microservice has its own database (Database per Service pattern):

| Database | Microservice | Collections |
|----------|--------------|-------------|
| `customer_db` | Customer Service | customers |
| `account_db` | Account Service | accounts |
| `credit_db` | Credit Service | credits |
| `transaction_db` | Transaction Service | transactions |
| `fraud_db` | Fraud Detection Service | fraud_alerts |

### Create Databases and Collections

```powershell
# Using the setup script
.\mongo-setup.ps1

# Or manually
podman exec banking-mongodb mongosh -u admin -p admin123 --authenticationDatabase admin --eval "
use customer_db;
db.createCollection('customers');

use account_db;
db.createCollection('accounts');

use credit_db;
db.createCollection('credits');

use transaction_db;
db.createCollection('transactions');

use fraud_db;
db.createCollection('fraud_alerts');
"
```

## Integration with Microservices

### Application Configuration

Update `application.yml` for each microservice:

```yaml
spring:
  data:
    mongodb:
      uri: mongodb://admin:admin123@localhost:27017/customer_db?authSource=admin
      database: customer_db
```

### Customer Service

```yaml
spring:
  data:
    mongodb:
      uri: mongodb://admin:admin123@localhost:27017/customer_db?authSource=admin
      database: customer_db
```

### Account Service

```yaml
spring:
  data:
    mongodb:
      uri: mongodb://admin:admin123@localhost:27017/account_db?authSource=admin
      database: account_db
```

### Credit Service

```yaml
spring:
  data:
    mongodb:
      uri: mongodb://admin:admin123@localhost:27017/credit_db?authSource=admin
      database: credit_db
```

### Transaction Service

```yaml
spring:
  data:
    mongodb:
      uri: mongodb://admin:admin123@localhost:27017/transaction_db?authSource=admin
      database: transaction_db
```

### Fraud Detection Service

```yaml
spring:
  data:
    mongodb:
      uri: mongodb://admin:admin123@localhost:27017/fraud_db?authSource=admin
      database: fraud_db
```

## MongoDB Shell Commands

### Connect to MongoDB

```bash
podman exec -it banking-mongodb mongosh -u admin -p admin123 --authenticationDatabase admin
```

### Show Databases

```javascript
show dbs
```

### Switch Database

```javascript
use customer_db
```

### Show Collections

```javascript
show collections
```

### Insert Document

```javascript
db.customers.insertOne({
  firstName: "Juan",
  lastName: "Perez",
  customerType: "PERSONAL",
  documentType: "DNI",
  documentNumber: "12345678",
  email: "juan.perez@email.com"
})
```

### Find Documents

```javascript
db.customers.find()
db.customers.find({ customerType: "PERSONAL" })
db.customers.findOne({ documentNumber: "12345678" })
```

### Update Document

```javascript
db.customers.updateOne(
  { documentNumber: "12345678" },
  { $set: { email: "newemail@email.com" } }
)
```

### Delete Document

```javascript
db.customers.deleteOne({ documentNumber: "12345678" })
```

## Troubleshooting

### Container Won't Start

```bash
# Check container logs
podman logs banking-mongodb

# Check if port is in use
netstat -an | findstr "27017"

# Remove and recreate
podman rm -f banking-mongodb
podman rm -f banking-mongo-express
```

### Cannot Connect to MongoDB

```bash
# Test connection
podman exec banking-mongodb mongosh -u admin -p admin123 --authenticationDatabase admin --eval "db.adminCommand('ping')"

# Check if MongoDB is running
podman ps --filter "name=banking-mongodb"
```

### Reset Everything

```bash
# Stop and remove all containers
podman stop banking-mongo-express banking-mongodb
podman rm banking-mongo-express banking-mongodb

# Remove volumes
podman volume rm mongodb-data mongodb-config

# Remove network
podman network rm banking-network
```

## Useful Commands

```bash
# Show running containers
podman ps --filter "name=banking-mongo"

# Show all containers (including stopped)
podman ps -a --filter "name=banking-mongo"

# Enter MongoDB container
podman exec -it banking-mongodb bash

# View MongoDB logs
podman logs -f banking-mongodb

# View Mongo Express logs
podman logs -f banking-mongo-express
```

## Network Configuration

All containers are connected to the `banking-network` network:

- **MongoDB**: `mongodb:27017`
- **Mongo Express**: `http://mongo-express:8081`

## Volumes

| Volume | Description |
|--------|-------------|
| `mongodb-data` | MongoDB data files |
| `mongodb-config` | MongoDB configuration |

## Ports Summary

| Service | Port | Protocol | Description |
|---------|------|----------|-------------|
| MongoDB | 27017 | TCP | Database connections |
| Mongo Express | 8081 | HTTP | Web interface |
