# Banking System - Kafka Test Script
# This script tests Kafka connectivity and produces/consumes test messages

param(
    [switch]$Produce,
    [switch]$Consume,
    [switch]$TestAll
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Banking System - Kafka Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check if Podman is installed
try {
    $podmanVersion = podman --version
    Write-Host "Podman Version: $podmanVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Podman is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Function to test Kafka connection
function Test-KafkaConnection {
    Write-Host "`nTesting Kafka connection..." -ForegroundColor Yellow
    
    try {
        podman exec banking-kafka kafka-broker-api-versions --bootstrap-server localhost:9092 | Out-Null
        Write-Host "Kafka connection successful!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "ERROR: Cannot connect to Kafka" -ForegroundColor Red
        return $false
    }
}

# Function to list topics
function Get-KafkaTopics {
    Write-Host "`nKafka Topics:" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Cyan
    
    try {
        $topics = podman exec banking-kafka kafka-topics --bootstrap-server localhost:9092 --list
        foreach ($topic in $topics) {
            Write-Host "  - $topic" -ForegroundColor White
        }
        return $topics
    } catch {
        Write-Host "ERROR: Cannot list topics" -ForegroundColor Red
        return @()
    }
}

# Function to produce test message
function Send-TestMessage {
    param(
        [string]$Topic = "transaction-events",
        [string]$Message = '{"transactionId":"test-123","customerId":"cust-456","amount":100.00,"currency":"PEN","transactionType":"DEPOSIT"}'
    )
    
    Write-Host "`nProducing test message to topic: $Topic" -ForegroundColor Yellow
    
    try {
        $Message | podman exec -i banking-kafka kafka-console-producer --bootstrap-server localhost:9092 --topic $Topic
        Write-Host "Message sent successfully!" -ForegroundColor Green
        Write-Host "Message: $Message" -ForegroundColor White
    } catch {
        Write-Host "ERROR: Cannot produce message" -ForegroundColor Red
    }
}

# Function to consume messages
function Receive-TestMessage {
    param(
        [string]$Topic = "transaction-events",
        [int]$Timeout = 5
    )
    
    Write-Host "`nConsuming messages from topic: $Topic" -ForegroundColor Yellow
    Write-Host "Timeout: $Timeout seconds" -ForegroundColor White
    Write-Host "========================" -ForegroundColor Cyan
    
    try {
        podman exec -it banking-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic $Topic --from-beginning --timeout-ms $($Timeout * 1000)
    } catch {
        Write-Host "ERROR: Cannot consume messages" -ForegroundColor Red
    }
}

# Function to describe topic
function Get-TopicDetails {
    param(
        [string]$Topic = "transaction-events"
    )
    
    Write-Host "`nTopic Details: $Topic" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Cyan
    
    try {
        podman exec banking-kafka kafka-topics --bootstrap-server localhost:9092 --describe --topic $Topic
    } catch {
        Write-Host "ERROR: Cannot describe topic" -ForegroundColor Red
    }
}

# Function to run all tests
function Test-AllKafka {
    Write-Host "`nRunning all Kafka tests..." -ForegroundColor Yellow
    
    # Test connection
    $connected = Test-KafkaConnection
    if (-not $connected) {
        Write-Host "Kafka is not running. Please start Kafka first." -ForegroundColor Red
        return
    }
    
    # List topics
    $topics = Get-KafkaTopics
    if ($topics.Count -eq 0) {
        Write-Host "No topics found. Creating topics..." -ForegroundColor Yellow
        .\kafka-setup.ps1 -CreateTopics
    }
    
    # Describe transaction-events topic
    Get-TopicDetails -Topic "transaction-events"
    
    # Produce test message
    Send-TestMessage -Topic "transaction-events"
    
    # Consume messages
    Receive-TestMessage -Topic "transaction-events" -Timeout 5
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "All tests completed!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
}

# Main logic
if ($Produce) {
    Send-TestMessage
} elseif ($Consume) {
    Receive-TestMessage
} elseif ($TestAll) {
    Test-AllKafka
} else {
    Write-Host "`nKafka Test Options:" -ForegroundColor Yellow
    Write-Host "  .\kafka-test.ps1 -Produce    # Send test message" -ForegroundColor White
    Write-Host "  .\kafka-test.ps1 -Consume    # Receive messages" -ForegroundColor White
    Write-Host "  .\kafka-test.ps1 -TestAll    # Run all tests" -ForegroundColor White
}
