# Banking System - Infrastructure Startup Script
# This script starts all required infrastructure services

param(
    [switch]$Stop,
    [switch]$Status,
    [switch]$Logs
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Banking System - Infrastructure Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Get project root
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Check if Podman is installed
try {
    $podmanVersion = podman --version
    Write-Host "Podman Version: $podmanVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Podman is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Function to start all infrastructure
function Start-Infrastructure {
    Write-Host "`nStarting all infrastructure services..." -ForegroundColor Yellow
    
    # Create network if it doesn't exist
    Write-Host "Creating banking network..." -ForegroundColor Green
    $networkExists = podman network ls --format "{{.Name}}" | Select-String "banking-network"
    if (-not $networkExists) {
        podman network create banking-network
    } else {
        Write-Host "Network banking-network already exists" -ForegroundColor Yellow
    }
    
    # Start MongoDB
    Write-Host "`n--- MongoDB ---" -ForegroundColor Cyan
    & "$projectRoot\mongo-setup.ps1"
    
    # Start Kafka
    Write-Host "`n--- Kafka ---" -ForegroundColor Cyan
    & "$projectRoot\kafka-setup.ps1"
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "All infrastructure services started!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
    Show-InfrastructureStatus
}

# Function to stop all infrastructure
function Stop-Infrastructure {
    Write-Host "`nStopping all infrastructure services..." -ForegroundColor Yellow
    
    # Stop Kafka
    Write-Host "`n--- Kafka ---" -ForegroundColor Cyan
    & "$projectRoot\kafka-setup.ps1" -Stop
    
    # Stop MongoDB
    Write-Host "`n--- MongoDB ---" -ForegroundColor Cyan
    & "$projectRoot\mongo-setup.ps1" -Stop
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "All infrastructure services stopped!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
}

# Function to show status
function Show-InfrastructureStatus {
    Write-Host "`nInfrastructure Services Status:" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    
    podman ps -a --filter "name=banking-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    Write-Host "`nService URLs:" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  MongoDB:       mongodb://admin:admin123@localhost:27017" -ForegroundColor White
    Write-Host "  Mongo Express: http://localhost:8081" -ForegroundColor White
    Write-Host "  Kafka:         localhost:9092" -ForegroundColor White
    Write-Host "  Kafka UI:      http://localhost:8080" -ForegroundColor White
    Write-Host "  Zookeeper:     localhost:2181" -ForegroundColor White
}

# Function to show logs
function Show-InfrastructureLogs {
    Write-Host "`nShowing infrastructure logs..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop viewing logs" -ForegroundColor White
    
    podman logs -f banking-mongodb banking-mongo-express banking-zookeeper banking-kafka banking-kafka-ui 2>&1
}

# Main logic
if ($Stop) {
    Stop-Infrastructure
} elseif ($Status) {
    Show-InfrastructureStatus
} elseif ($Logs) {
    Show-InfrastructureLogs
} else {
    Start-Infrastructure
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Infrastructure Ready!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "1. Start Config Server: cd config-server && mvn spring-boot:run" -ForegroundColor White
    Write-Host "2. Start microservices in separate terminals:" -ForegroundColor White
    Write-Host "   cd customer-service && mvn spring-boot:run" -ForegroundColor White
    Write-Host "   cd account-service && mvn spring-boot:run" -ForegroundColor White
    Write-Host "   cd credit-service && mvn spring-boot:run" -ForegroundColor White
    Write-Host "   cd transaction-service && mvn spring-boot:run" -ForegroundColor White
    Write-Host "   cd fraud-detection-service && mvn spring-boot:run" -ForegroundColor White
    
    Write-Host "`nUseful Commands:" -ForegroundColor Yellow
    Write-Host "  .\start-infra.ps1 -Status    # Show status" -ForegroundColor White
    Write-Host "  .\start-infra.ps1 -Stop      # Stop all services" -ForegroundColor White
    Write-Host "  .\start-infra.ps1 -Logs      # Show logs" -ForegroundColor White
}
