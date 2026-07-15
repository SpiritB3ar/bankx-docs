# Git Repositories Setup Guide

## Overview

Each microservice should have its own independent Git repository as per the project requirements. This guide provides instructions for setting up Git repositories for all microservices.

## Microservices to Configure

| Microservice | Repository Name | Description |
|--------------|-----------------|-------------|
| Config Server | `config-server` | Configuration Server |
| Customer Service | `customer-service` | Customer Management |
| Account Service | `account-service` | Account Management |
| Credit Service | `credit-service` | Credit Products Management |
| Transaction Service | `transaction-service` | Transaction Management |
| Fraud Detection | `fraud-detection-service` | Fraud Detection with AI |

## Step 1: Create GitHub Repositories

For each microservice, create a new repository on GitHub:

1. Go to [GitHub](https://github.com)
2. Click the "+" icon → "New repository"
3. Enter repository name (e.g., `config-server`)
4. Select visibility (Private recommended)
5. **DO NOT** initialize with README, .gitignore, or license
6. Click "Create repository"

## Step 2: Initialize Git Repositories

Run the following commands from the project root directory:

```powershell
# Navigate to project root
cd C:\Users\eccalcin\OneDrive - NTT DATA EMEAL\NTTDATA\bootcamp\projects\banksystem

# Initialize each microservice repository
$microservices = @(
    "config-server",
    "customer-service",
    "account-service",
    "credit-service",
    "transaction-service",
    "fraud-detection-service"
)

foreach ($service in $microservices) {
    Write-Host "Setting up $service..." -ForegroundColor Green
    
    # Navigate to service directory
    Set-Location $service
    
    # Initialize git
    git init
    
    # Add all files
    git add .
    
    # Create initial commit
    git commit -m "Initial commit: $service microservice with hexagonal architecture"
    
    # Navigate back to root
    Set-Location ..
    
    Write-Host "$service repository initialized" -ForegroundColor Yellow
}
```

## Step 3: Connect to GitHub and Push

For each microservice, connect to the remote repository and push:

```powershell
# Example for config-server (repeat for each service)
cd config-server

# Add remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/config-server.git

# Push to GitHub
git push -u origin main

cd ..
```

## Step 4: Create Root Repository (Optional)

If you want to keep a parent repository with links to all microservices:

```powershell
# Navigate to project root
cd C:\Users\eccalcin\OneDrive - NTT DATA EMEAL\NTTDATA\bootcamp\projects\banksystem

# Initialize root repository
git init
git add .
git commit -m "Initial commit: Banking System project root"

# Add remote
git remote add origin https://github.com/YOUR_USERNAME/banksystem.git

# Push
git push -u origin main
```

## Repository Structure per Microservice

Each microservice repository should contain:

```
microservice-name/
├── pom.xml
├── .gitignore
├── README.md
├── src/
│   ├── main/
│   │   ├── java/com/bank/[service]/
│   │   │   ├── [Service]Application.java
│   │   │   ├── domain/
│   │   │   ├── application/
│   │   │   ├── adapter/
│   │   │   └── config/
│   │   └── resources/
│   │       ├── application.yml
│   │       └── bootstrap.yml
│   └── test/
│       └── java/com/bank/[service]/
└── target/ (gitignored)
```

## Quick Setup Script

Create a file named `setup-repos.ps1` and run it:

```powershell
# setup-repos.ps1

$projectRoot = "C:\Users\eccalcin\OneDrive - NTT DATA EMEAL\NTTDATA\bootcamp\projects\banksystem"
$githubUsername = "YOUR_USERNAME"  # Replace with your GitHub username

$microservices = @(
    "config-server",
    "customer-service",
    "account-service",
    "credit-service",
    "transaction-service",
    "fraud-detection-service"
)

Set-Location $projectRoot

foreach ($service in $microservices) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Setting up: $service" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
    $servicePath = Join-Path $projectRoot $service
    
    if (Test-Path $servicePath) {
        Set-Location $servicePath
        
        # Initialize git if not already initialized
        if (-not (Test-Path ".git")) {
            git init
            git add .
            git commit -m "Initial commit: $service with hexagonal architecture"
        }
        
        # Add remote
        $remoteUrl = "https://github.com/$githubUsername/$service.git"
        $remoteExists = git remote -v | Select-String "origin"
        
        if (-not $remoteExists) {
            git remote add origin $remoteUrl
        }
        
        Write-Host "Repository: $remoteUrl" -ForegroundColor Yellow
        Write-Host "To push: cd $service && git push -u origin main" -ForegroundColor White
        
        Set-Location $projectRoot
    } else {
        Write-Host "Directory not found: $servicePath" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor White
Write-Host "1. Create repositories on GitHub" -ForegroundColor Yellow
Write-Host "2. Run: cd [service] && git push -u origin main" -ForegroundColor Yellow
```

## Verify Setup

After setting up, verify each repository:

```powershell
foreach ($service in $microservices) {
    Set-Location (Join-Path $projectRoot $service)
    Write-Host "`n$service:" -ForegroundColor Green
    git status
    git log --oneline -1
    Set-Location $projectRoot
}
```

## Best Practices

1. **Commit Messages**: Use conventional commits
   - `feat: add new feature`
   - `fix: resolve bug`
   - `docs: update documentation`
   - `refactor: improve code structure`

2. **Branching Strategy**:
   - `main` - Production-ready code
   - `develop` - Development branch
   - `feature/*` - Feature branches
   - `hotfix/*` - Hotfix branches

3. **Git Ignore**: Each repository has a `.gitignore` that excludes:
   - `target/` (Maven build output)
   - IDE files (`.idea/`, `*.iml`)
   - Environment variables (`.env`)
   - Logs (`*.log`, `logs/`)

4. **Documentation**: Each repository should have:
   - `README.md` with setup instructions
   - API documentation (Swagger UI)
   - Environment requirements

## Troubleshooting

### Git not recognizing files
```powershell
# Force add files
git add -A
git commit -m "Add all files"
```

### Remote already exists
```powershell
# Remove existing remote
git remote remove origin
# Add new remote
git remote add origin https://github.com/YOUR_USERNAME/repo.git
```

### Push rejected
```powershell
# Force push (use with caution)
git push -u origin main --force
```
