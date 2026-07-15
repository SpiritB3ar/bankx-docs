# Banking System - MongoDB Setup with Podman
# This script starts MongoDB and Mongo Express using Podman

param(
    [switch]$Stop,
    [switch]$Logs,
    [switch]$Status,
    [switch]$Shell
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Banking System - MongoDB Setup (Podman)" -ForegroundColor Cyan
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

# Function to start MongoDB services
function Start-MongoServices {
    Write-Host "`nStarting MongoDB services..." -ForegroundColor Yellow
    
    # Create network if it doesn't exist
    $networkExists = podman network ls --format "{{.Name}}" | Select-String "banking-network"
    if (-not $networkExists) {
        podman network create banking-network
    }
    
    # Start MongoDB
    Write-Host "Starting MongoDB..." -ForegroundColor Green
    podman run -d `
        --name banking-mongodb `
        --hostname mongodb `
        -p 27017:27017 `
        -e MONGO_INITDB_ROOT_USERNAME=admin `
        -e MONGO_INITDB_ROOT_PASSWORD=admin123 `
        -v mongodb-data:/data/db `
        -v mongodb-config:/data/configdb `
        --network banking-network `
        mongo:6.0
    
    # Wait for MongoDB to be ready
    Write-Host "Waiting for MongoDB to be ready..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    # Start Mongo Express
    Write-Host "Starting Mongo Express..." -ForegroundColor Green
    podman run -d `
        --name banking-mongo-express `
        --hostname mongo-express `
        -p 8081:8081 `
        -e ME_CONFIG_MONGODB_ADMINUSERNAME=admin `
        -e ME_CONFIG_MONGODB_ADMINPASSWORD=admin123 `
        -e ME_CONFIG_MONGODB_URL=mongodb://admin:admin123@mongodb:27017/ `
        -e ME_CONFIG_BASICAUTH_USERNAME=admin `
        -e ME_CONFIG_BASICAUTH_PASSWORD=admin123 `
        -e ME_CONFIG_MONGODB_ENABLE_ADMIN=true `
        --network banking-network `
        mongo-express:latest
    
    Write-Host "MongoDB services started successfully!" -ForegroundColor Green
}

# Function to stop services
function Stop-MongoServices {
    Write-Host "`nStopping MongoDB services..." -ForegroundColor Yellow
    
    # Stop containers
    podman stop banking-mongo-express 2>$null
    podman stop banking-mongodb 2>$null
    
    # Remove containers
    podman rm banking-mongo-express 2>$null
    podman rm banking-mongodb 2>$null
    
    Write-Host "MongoDB services stopped successfully!" -ForegroundColor Green
}

# Function to show logs
function Show-MongoLogs {
    Write-Host "`nShowing MongoDB logs..." -ForegroundColor Yellow
    podman logs -f banking-mongodb
}

# Function to show status
function Show-MongoStatus {
    Write-Host "`nMongoDB Services Status:" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Cyan
    
    podman ps -a --filter "name=banking-mongo" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    Write-Host "`nDatabases:" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Cyan
    
    try {
        podman exec banking-mongodb mongosh -u admin -p admin123 --authenticationDatabase admin --eval "show dbs" --quiet
    } catch {
        Write-Host "Unable to list databases (MongoDB may not be ready)" -ForegroundColor Red
    }
}

# Function to open MongoDB shell
function Open-MongoShell {
    Write-Host "`nOpening MongoDB shell..." -ForegroundColor Yellow
    Write-Host "Username: admin" -ForegroundColor White
    Write-Host "Password: admin123" -ForegroundColor White
    Write-Host "========================" -ForegroundColor Cyan
    
    podman exec -it banking-mongodb mongosh -u admin -p admin123 --authenticationDatabase admin
}

# Function to create databases and collections
function New-MongoDatabases {
    Write-Host "`nCreating databases and collections..." -ForegroundColor Yellow
    
    $databases = @(
        @{name="customer_db"; collections=@("customers")},
        @{name="account_db"; collections=@("accounts")},
        @{name="credit_db"; collections=@("credits")},
        @{name="transaction_db"; collections=@("transactions")},
        @{name="fraud_db"; collections=@("fraud_alerts")}
    )
    
    foreach ($db in $databases) {
        Write-Host "Creating database: $($db.name)" -ForegroundColor Green
        
        foreach ($collection in $db.collections) {
            Write-Host "  Creating collection: $collection" -ForegroundColor White
            podman exec banking-mongodb mongosh -u admin -p admin123 --authenticationDatabase admin --eval "use $($db.name); db.createCollection('$collection')" --quiet
        }
    }
    
    Write-Host "`nAll databases and collections created!" -ForegroundColor Green
    Show-MongoDatabases
}

# Function to show databases
function Show-MongoDatabases {
    Write-Host "`nMongoDB Databases:" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Cyan
    
    podman exec banking-mongodb mongosh -u admin -p admin123 --authenticationDatabase admin --eval "show dbs" --quiet
}

# Function to show connection info
function Show-MongoConnection {
    Write-Host "`nMongoDB Connection Info:" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Cyan
    
    Write-Host "Connection String: mongodb://admin:admin123@localhost:27017" -ForegroundColor White
    Write-Host "Host: localhost" -ForegroundColor White
    Write-Host "Port: 27017" -ForegroundColor White
    Write-Host "Username: admin" -ForegroundColor White
    Write-Host "Password: admin123" -ForegroundColor White
    
    Write-Host "`nMongo Express UI: http://localhost:8081" -ForegroundColor Yellow
    Write-Host "Username: admin" -ForegroundColor White
    Write-Host "Password: admin123" -ForegroundColor White
    
    Write-Host "`nDatabases:" -ForegroundColor Yellow
    Write-Host "  - customer_db (Customer Service)" -ForegroundColor White
    Write-Host "  - account_db (Account Service)" -ForegroundColor White
    Write-Host "  - credit_db (Credit Service)" -ForegroundColor White
    Write-Host "  - transaction_db (Transaction Service)" -ForegroundColor White
    Write-Host "  - fraud_db (Fraud Detection Service)" -ForegroundColor White
}

# Main logic
if ($Stop) {
    Stop-MongoServices
} elseif ($Logs) {
    Show-MongoLogs
} elseif ($Status) {
    Show-MongoStatus
} elseif ($Shell) {
    Open-MongoShell
} else {
    # Start services
    Start-MongoServices
    
    # Show status
    Show-MongoStatus
    
    # Create databases
    New-MongoDatabases
    
    # Show connection info
    Show-MongoConnection
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "MongoDB Setup Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
    Write-Host "`nUseful Commands:" -ForegroundColor Yellow
    Write-Host "  .\mongo-setup.ps1 -Status    # Show status" -ForegroundColor White
    Write-Host "  .\mongo-setup.ps1 -Logs      # Show logs" -ForegroundColor White
    Write-Host "  .\mongo-setup.ps1 -Stop      # Stop services" -ForegroundColor White
    Write-Host "  .\mongo-setup.ps1 -Shell     # Open MongoDB shell" -ForegroundColor White
}
