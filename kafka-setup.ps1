# Banking System - Kafka Setup with Podman
# This script starts Kafka and Zookeeper using Podman

param(
    [switch]$Stop,
    [switch]$Logs,
    [switch]$Status,
    [switch]$CreateTopics
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Banking System - Kafka Setup (Podman)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Get project root
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Check if Podman is installed
try {
    $podmanVersion = podman --version
    Write-Host "Podman Version: $podmanVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Podman is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Install Podman: https://podman.io/getting-started/installation" -ForegroundColor Yellow
    exit 1
}

# Check if podman-compose is installed
try {
    $composeVersion = podman-compose --version
    Write-Host "Podman Compose Version: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "WARNING: podman-compose not found. Using podman directly." -ForegroundColor Yellow
    $useCompose = $false
} finally {
    if (-not $composeVersion) {
        $useCompose = $false
    } else {
        $useCompose = $true
    }
}

# Function to start services
function Start-KafkaServices {
    Write-Host "`nStarting Kafka services..." -ForegroundColor Yellow
    
    if ($useCompose) {
        Set-Location $projectRoot
        podman-compose up -d
    } else {
        # Start Zookeeper
        Write-Host "Starting Zookeeper..." -ForegroundColor Green
        podman run -d `
            --name banking-zookeeper `
            --hostname zookeeper `
            -p 2181:2181 `
            -e ZOOKEEPER_CLIENT_PORT=2181 `
            -e ZOOKEEPER_TICK_TIME=2000 `
            -e ZOOKEEPER_SYNC_LIMIT=2 `
            -v zookeeper-data:/var/lib/zookeeper/data `
            -v zookeeper-log:/var/lib/zookeeper/log `
            --network banking-network `
            confluentinc/cp-zookeeper:7.5.0

        # Wait for Zookeeper to be ready
        Write-Host "Waiting for Zookeeper to be ready..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10

        # Start Kafka
        Write-Host "Starting Kafka..." -ForegroundColor Green
        podman run -d `
            --name banking-kafka `
            --hostname kafka `
            -p 9092:9092 `
            -p 29092:29092 `
            --network banking-network `
            -e KAFKA_BROKER_ID=1 `
            -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 `
            -e "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT" `
            -e "KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092" `
            -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 `
            -e KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1 `
            -e KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1 `
            -e KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS=0 `
            -e KAFKA_AUTO_CREATE_TOPICS_ENABLE=true `
            -e KAFKA_DELETE_TOPIC_ENABLE=true `
            -v kafka-data:/var/lib/kafka/data `
            confluentinc/cp-kafka:7.5.0

        # Wait for Kafka to be ready
        Write-Host "Waiting for Kafka to be ready..." -ForegroundColor Yellow
        Start-Sleep -Seconds 15
    }
    
    Write-Host "Kafka services started successfully!" -ForegroundColor Green
}

# Function to stop services
function Stop-KafkaServices {
    Write-Host "`nStopping Kafka services..." -ForegroundColor Yellow
    
    if ($useCompose) {
        Set-Location $projectRoot
        podman-compose down
    } else {
        # Stop containers
        podman stop banking-kafka-ui 2>$null
        podman stop banking-kafka 2>$null
        podman stop banking-zookeeper 2>$null
        
        # Remove containers
        podman rm banking-kafka-ui 2>$null
        podman rm banking-kafka 2>$null
        podman rm banking-zookeeper 2>$null
    }
    
    Write-Host "Kafka services stopped successfully!" -ForegroundColor Green
}

# Function to show logs
function Show-KafkaLogs {
    Write-Host "`nShowing Kafka logs..." -ForegroundColor Yellow
    
    if ($useCompose) {
        Set-Location $projectRoot
        podman-compose logs -f
    } else {
        podman logs -f banking-kafka
    }
}

# Function to show status
function Show-KafkaStatus {
    Write-Host "`nKafka Services Status:" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Cyan
    
    podman ps -a --filter "name=banking-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    Write-Host "`nKafka Topics:" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Cyan
    
    try {
        podman exec banking-kafka kafka-topics --bootstrap-server localhost:9092 --list
    } catch {
        Write-Host "Unable to list topics (Kafka may not be ready)" -ForegroundColor Red
    }
}

# Function to create Kafka topics
function New-KafkaTopics {
    Write-Host "`nCreating Kafka topics..." -ForegroundColor Yellow
    
    $topics = @(
        "transaction-events",
        "fraud-alerts",
        "customer-events",
        "account-events",
        "credit-events"
    )
    
    foreach ($topic in $topics) {
        Write-Host "Creating topic: $topic" -ForegroundColor Green
        try {
            podman exec banking-kafka kafka-topics `
                --bootstrap-server localhost:9092 `
                --create `
                --if-not-exists `
                --topic $topic `
                --partitions 3 `
                --replication-factor 1
            
            Write-Host "Topic $topic created successfully" -ForegroundColor Green
        } catch {
            Write-Host "Error creating topic $topic : $_" -ForegroundColor Red
        }
    }
    
    Write-Host "`nAll topics created!" -ForegroundColor Green
    Show-KafkaTopics
}

# Function to show topics
function Show-KafkaTopics {
    Write-Host "`nKafka Topics:" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Cyan
    
    podman exec banking-kafka kafka-topics `
        --bootstrap-server localhost:9092 `
        --list
}

# Function to create network
function New-KafkaNetwork {
    Write-Host "Creating banking network..." -ForegroundColor Yellow
    $networkExists = podman network ls --format "{{.Name}}" | Select-String "banking-network"
    if (-not $networkExists) {
        podman network create banking-network
        Write-Host "Network created" -ForegroundColor Green
    } else {
        Write-Host "Network banking-network already exists" -ForegroundColor Yellow
    }
}

# Main logic
if ($Stop) {
    Stop-KafkaServices
} elseif ($Logs) {
    Show-KafkaLogs
} elseif ($Status) {
    Show-KafkaStatus
} elseif ($CreateTopics) {
    New-KafkaTopics
} else {
    # Create network if it doesn't exist
    New-KafkaNetwork
    
    # Start services
    Start-KafkaServices
    
    # Show status
    Show-KafkaStatus
    
    # Create topics
    New-KafkaTopics
    
    # Show Kafka UI URL
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Kafka Setup Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
    Write-Host "`nKafka UI: http://localhost:8080" -ForegroundColor Yellow
    Write-Host "Kafka Bootstrap Server: localhost:9092" -ForegroundColor Yellow
    Write-Host "Zookeeper: localhost:2181" -ForegroundColor Yellow
    
    Write-Host "`nUseful Commands:" -ForegroundColor Yellow
    Write-Host "  .\kafka-setup.ps1 -Status      # Show status" -ForegroundColor White
    Write-Host "  .\kafka-setup.ps1 -Logs        # Show logs" -ForegroundColor White
    Write-Host "  .\kafka-setup.ps1 -Stop        # Stop services" -ForegroundColor White
    Write-Host "  .\kafka-setup.ps1 -CreateTopics # Create topics" -ForegroundColor White
}
