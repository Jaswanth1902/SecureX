# Run the desktop Flutter app from repository root
# Usage: In PowerShell, run: .\run_desktop.ps1

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$scriptDir\desktop_app"
Write-Host "Starting Flutter desktop app from: $PWD"
& "flutter" run -d windows
