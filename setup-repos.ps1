# Banking System - Git Repositories Setup Script
# This script initializes Git repositories for all microservices

param(
    [string]$GitHubUsername = ""
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Banking System - Git Repository Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Get project root
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $projectRoot

Write-Host "`nProject Root: $projectRoot" -ForegroundColor Yellow

# Check if Git is installed
try {
    $gitVersion = git --version
    Write-Host "Git Version: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Git is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Get GitHub username if not provided
if ([string]::IsNullOrEmpty($GitHubUsername)) {
    $GitHubUsername = Read-Host -Prompt "Enter your GitHub username"
}

if ([string]::IsNullOrEmpty($GitHubUsername)) {
    Write-Host "ERROR: GitHub username is required" -ForegroundColor Red
    exit 1
}

Write-Host "`nGitHub Username: $GitHubUsername" -ForegroundColor Yellow

# List of microservices
$microservices = @(
    "config-server",
    "customer-service",
    "account-service",
    "credit-service",
    "transaction-service",
    "fraud-detection-service"
)

# Process each microservice
foreach ($service in $microservices) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Processing: $service" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
    $servicePath = Join-Path $projectRoot $service
    
    if (-not (Test-Path $servicePath)) {
        Write-Host "ERROR: Directory not found: $servicePath" -ForegroundColor Red
        continue
    }
    
    Set-Location $servicePath
    
    # Initialize Git if not already initialized
    if (-not (Test-Path ".git")) {
        Write-Host "Initializing Git repository..." -ForegroundColor Yellow
        git init
        
        # Configure Git (optional - uncomment if needed)
        # git config user.email "your.email@example.com"
        # git config user.name "Your Name"
    } else {
        Write-Host "Git repository already initialized" -ForegroundColor Yellow
    }
    
    # Add all files
    Write-Host "Adding files..." -ForegroundColor Yellow
    git add .
    
    # Check if there are changes to commit
    $status = git status --porcelain
    if ($status) {
        # Create initial commit
        Write-Host "Creating initial commit..." -ForegroundColor Yellow
        git commit -m "Initial commit: $service with hexagonal architecture"
    } else {
        Write-Host "No changes to commit" -ForegroundColor Yellow
    }
    
    # Add remote
    $remoteUrl = "https://github.com/$GitHubUsername/$service.git"
    $remoteExists = git remote -v | Select-String "origin"
    
    if (-not $remoteExists) {
        Write-Host "Adding remote: $remoteUrl" -ForegroundColor Yellow
        git remote add origin $remoteUrl
    } else {
        Write-Host "Remote 'origin' already exists" -ForegroundColor Yellow
    }
    
    # Show status
    Write-Host "`nRepository Status:" -ForegroundColor Green
    git status
    
    Write-Host "`nRemote URL: $remoteUrl" -ForegroundColor Yellow
    Write-Host "To push: cd $service && git push -u origin main" -ForegroundColor White
    
    # Return to project root
    Set-Location $projectRoot
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nRepositories to create on GitHub:" -ForegroundColor Yellow
foreach ($service in $microservices) {
    Write-Host "  - https://github.com/$GitHubUsername/$service" -ForegroundColor White
}

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Create each repository on GitHub (without README, .gitignore, or license)" -ForegroundColor White
Write-Host "2. Push each repository:" -ForegroundColor White
foreach ($service in $microservices) {
    Write-Host "   cd $service && git push -u origin main" -ForegroundColor White
}

Write-Host "`n========================================" -ForegroundColor Cyan
