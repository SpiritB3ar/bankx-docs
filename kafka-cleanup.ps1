# Banking System - Kafka Cleanup Script
# This script stops and removes all Kafka containers and volumes

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Banking System - Kafka Cleanup" -ForegroundColor Cyan
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

# Confirmation
if (-not $Force) {
    $confirmation = Read-Host -Prompt "Are you sure you want to remove all Kafka containers and volumes? (y/N)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Host "Cleanup cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "`nStopping Kafka services..." -ForegroundColor Yellow

# Stop containers
Write-Host "Stopping banking-kafka-ui..." -ForegroundColor Green
podman stop banking-kafka-ui 2>$null

Write-Host "Stopping banking-kafka..." -ForegroundColor Green
podman stop banking-kafka 2>$null

Write-Host "Stopping banking-zookeeper..." -ForegroundColor Green
podman stop banking-zookeeper 2>$null

Write-Host "`nRemoving containers..." -ForegroundColor Yellow

# Remove containers
Write-Host "Removing banking-kafka-ui..." -ForegroundColor Green
podman rm banking-kafka-ui 2>$null

Write-Host "Removing banking-kafka..." -ForegroundColor Green
podman rm banking-kafka 2>$null

Write-Host "Removing banking-zookeeper..." -ForegroundColor Green
podman rm banking-zookeeper 2>$null

Write-Host "`nRemoving volumes..." -ForegroundColor Yellow

# Remove volumes
Write-Host "Removing zookeeper-data..." -ForegroundColor Green
podman volume rm zookeeper-data 2>$null

Write-Host "Removing zookeeper-log..." -ForegroundColor Green
podman volume rm zookeeper-log 2>$null

Write-Host "Removing kafka-data..." -ForegroundColor Green
podman volume rm kafka-data 2>$null

Write-Host "`nRemoving network..." -ForegroundColor Yellow

# Remove network
Write-Host "Removing banking-network..." -ForegroundColor Green
podman network rm banking-network 2>$null

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Cleanup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nAll Kafka containers, volumes, and networks have been removed." -ForegroundColor Yellow
Write-Host "To restart Kafka, run: .\kafka-setup.ps1" -ForegroundColor White
