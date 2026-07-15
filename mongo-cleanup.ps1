# Banking System - MongoDB Cleanup Script
# This script stops and removes all MongoDB containers and volumes

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Banking System - MongoDB Cleanup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check if Podman is installed
try {
    $podmanVersion = podman --version
    Write-Host "Podman Version: $podmanVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Podman is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Confirmation
if (-not $Force) {
    $confirmation = Read-Host -Prompt "Are you sure you want to remove all MongoDB containers and volumes? (y/N)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host "Cleanup cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "`nStopping MongoDB services..." -ForegroundColor Yellow

# Stop containers
Write-Host "Stopping banking-mongo-express..." -ForegroundColor Green
podman stop banking-mongo-express 2>$null

Write-Host "Stopping banking-mongodb..." -ForegroundColor Green
podman stop banking-mongodb 2>$null

Write-Host "`nRemoving containers..." -ForegroundColor Yellow

# Remove containers
Write-Host "Removing banking-mongo-express..." -ForegroundColor Green
podman rm banking-mongo-express 2>$null

Write-Host "Removing banking-mongodb..." -ForegroundColor Green
podman rm banking-mongodb 2>$null

Write-Host "`nRemoving volumes..." -ForegroundColor Yellow

# Remove volumes
Write-Host "Removing mongodb-data..." -ForegroundColor Green
podman volume rm mongodb-data 2>$null

Write-Host "Removing mongodb-config..." -ForegroundColor Green
podman volume rm mongodb-config 2>$null

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Cleanup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nAll MongoDB containers and volumes have been removed." -ForegroundColor Yellow
Write-Host "To restart MongoDB, run: .\mongo-setup.ps1" -ForegroundColor White
