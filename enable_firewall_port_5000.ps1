# Windows Firewall Configuration for Flask Backend
# Run this script as Administrator

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click on PowerShell and select 'Run as administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "Adding firewall rule for Flask Backend on port 5000..." -ForegroundColor Cyan

# Add firewall rule for port 5000 from private networks (hotspot/WiFi)
$RuleName = "Flask Backend 5000"
$RuleExists = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue

if ($RuleExists) {
    Write-Host "Rule already exists. Removing old rule..." -ForegroundColor Yellow
    Remove-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
}

# Create new rule
New-NetFirewallRule -DisplayName $RuleName `
    -Direction Inbound `
    -Action Allow `
    -Protocol TCP `
    -LocalPort 5000 `
    -RemoteAddress @("192.168.0.0/16", "10.0.0.0/8", "172.16.0.0/12") `
    -Profile Private `
    -Enabled True

Write-Host "Firewall rule created successfully!" -ForegroundColor Green
Write-Host ""

# Verify port is listening
Write-Host "Checking port 5000 status..." -ForegroundColor Cyan
netstat -ano | Select-String ":5000"

Write-Host ""
Write-Host "Configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Now you can test the mobile app:" -ForegroundColor Yellow
Write-Host "1. Make sure mobile device is connected to your laptop hotspot" -ForegroundColor White
Write-Host "2. Run: flutter run" -ForegroundColor White
Write-Host "3. Check if files load without timeout error" -ForegroundColor White
