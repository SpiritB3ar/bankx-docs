# Kafka Setup with Podman

## Overview

This directory contains the Kafka infrastructure setup for the Banking System using Podman (or Docker).

## Components

| Component | Container Name | Port | Description |
|-----------|----------------|------|-------------|
| **Zookeeper** | banking-zookeeper | 2181 | Kafka coordination service |
| **Kafka** | banking-kafka | 9092, 29092 | Message broker |
| **Kafka UI** | banking-kafka-ui | 8080 | Web UI for Kafka management |

## Quick Start

### Option 1: Using PowerShell Script (Recommended)

```powershell
# Start Kafka services and create topics
.\kafka-setup.ps1

# Show status
.\kafka-setup.ps1 -Status

# Show logs
.\kafka-setup.ps1 -Logs

# Stop services
.\kafka-setup.ps1 -Stop

# Create topics only
.\kafka-setup.ps1 -CreateTopics
```

### Option 2: Using Podman Compose

```bash
# Start services
podman-compose up -d

# Stop services
podman-compose down

# Show logs
podman-compose logs -f

# Show status
podman ps -a --filter "name=banking-"
```

### Option 3: Using Podman Commands

```bash
# Create network
podman network create banking-network

# Start Zookeeper
podman run -d \
  --name banking-zookeeper \
  --hostname zookeeper \
  -p 2181:2181 \
  -e ZOOKEEPER_CLIENT_PORT=2181 \
  -e ZOOKEEPER_TICK_TIME=2000 \
  --network banking-network \
  confluentinc/cp-zookeeper:7.5.0

# Start Kafka
podman run -d \
  --name banking-kafka \
  --hostname kafka \
  -p 9092:9092 \
  -p 29092:29092 \
  --network banking-network \
  -e KAFKA_BROKER_ID=1 \
  -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
  -e "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT" \
  -e "KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092" \
  -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
  -e KAFKA_AUTO_CREATE_TOPICS_ENABLE=true \
  confluentinc/cp-kafka:7.5.0
```

## Kafka Topics

### Pre-configured Topics

| Topic | Partitions | Description |
|-------|------------|-------------|
| `transaction-events` | 3 | Transaction events for fraud detection |
| `fraud-alerts` | 3 | Fraud alert notifications |
| `customer-events` | 3 | Customer-related events |
| `account-events` | 3 | Account-related events |
| `credit-events` | 3 | Credit-related events |

### Create Topics Manually

```bash
# Create a topic
podman exec banking-kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --create \
  --topic my-topic \
  --partitions 3 \
  --replication-factor 1

# List topics
podman exec banking-kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --list

# Describe a topic
podman exec banking-kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --describe \
  --topic transaction-events

# Delete a topic
podman exec banking-kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --delete \
  --topic my-topic
```

## Accessing Services

### Kafka UI

Open in browser: **http://localhost:8080**

Features:
- View all topics
- Produce/consumer messages
- View consumer groups
- Monitor broker metrics

### Kafka Bootstrap Server

- **Internal**: `kafka:29092` (for containers in the same network)
- **External**: `localhost:9092` (for host machine)

### Zookeeper

- **Connection**: `localhost:2181`

## Testing Kafka

### Produce a Test Message

```bash
podman exec -it banking-kafka kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic transaction-events

> {"transactionId": "test-123", "amount": 100.00}
```

### Consume Messages

```bash
podman exec -it banking-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic transaction-events \
  --from-beginning
```

## Integration with Microservices

### Application Configuration

Update `application.yml` for each microservice:

```yaml
spring:
  kafka:
    bootstrap-servers: localhost:9092
```

### Transaction Service (Producer)

```yaml
spring:
  kafka:
    bootstrap-servers: localhost:9092
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
```

### Fraud Detection Service (Consumer)

```yaml
spring:
  kafka:
    bootstrap-servers: localhost:9092
    consumer:
      group-id: fraud-detection-group
      auto-offset-reset: earliest
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.apache.kafka.common.serialization.StringDeserializer
```

## Troubleshooting

### Container Won't Start

```bash
# Check container logs
podman logs banking-kafka

# Check if port is in use
netstat -an | findstr "9092"

# Remove and recreate
podman rm -f banking-kafka
podman rm -f banking-zookeeper
```

### Kafka Not Ready

```bash
# Check Kafka health
podman exec banking-kafka kafka-broker-api-versions \
  --bootstrap-server localhost:9092

# Check Zookeeper connection
podman exec banking-zookeeper echo ruok | nc localhost 2181
```

### Reset Everything

```bash
# Stop and remove all containers
podman stop banking-kafka-ui banking-kafka banking-zookeeper
podman rm banking-kafka-ui banking-kafka banking-zookeeper

# Remove volumes
podman volume rm zookeeper-data zookeeper-log kafka-data

# Remove network
podman network rm banking-network
```

## Useful Commands

```bash
# Show running containers
podman ps --filter "name=banking-"

# Show all containers (including stopped)
podman ps -a --filter "name=banking-"

# Enter Kafka container
podman exec -it banking-kafka bash

# Enter Zookeeper container
podman exec -it banking-zookeeper bash

# View Kafka logs
podman logs -f banking-kafka

# View Zookeeper logs
podman logs -f banking-zookeeper
```

## Network Configuration

All containers are connected to the `banking-network` network:

- **Zookeeper**: `zookeeper:2181`
- **Kafka**: `kafka:29092` (internal), `localhost:9092` (external)
- **Kafka UI**: `http://kafka-ui:8080`

## Volumes

| Volume | Description |
|--------|-------------|
| `zookeeper-data` | Zookeeper data |
| `zookeeper-log` | Zookeeper logs |
| `kafka-data` | Kafka data |

## Ports Summary

| Service | Port | Protocol | Description |
|---------|------|----------|-------------|
| Zookeeper | 2181 | TCP | Client connections |
| Kafka | 9092 | TCP | External connections |
| Kafka | 29092 | TCP | Internal connections |
| Kafka UI | 8080 | HTTP | Web interface |
