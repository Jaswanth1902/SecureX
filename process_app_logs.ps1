#!/usr/bin/env powershell
# Process and log SafeCopy app activity
# Real-time processor for logcat output

$app = "com.jaswanth.saveandorganize"
$logFile = "MOBILE_APP_ACTIVITY_LOG.md"
$rawLog = "app_raw_logcat.log"
$lastPos = 0

# Initialize activity log
$header = @"
# Real-Time Activity Monitor - SafeCopy App
**Monitoring Started**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Device**: Samsung Android (10BE5820BZ0009L)
**Package**: com.jaswanth.saveandorganize
**Status**: ✓ LIVE MONITORING ACTIVE

---

## Activity Stream

"@

if (-not (Test-Path $logFile)) {
    Set-Content -Path $logFile -Value $header
}

function Log-Activity {
    param([string]$text)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $entry = "[$timestamp] $text"
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry -ForegroundColor Green
}

# Monitor logcat in real-time
while ($true) {
    if (Test-Path $rawLog) {
        $lines = @(Get-Content $rawLog)
        $currentLines = $lines.Count
        
        if ($currentLines -gt $lastPos) {
            # Process new lines
            $newLines = $lines[$lastPos..($currentLines-1)]
            
            foreach ($line in $newLines) {
                # Check for app-related activity
                if ($line -match $app) {
                    Log-Activity "APP EVENT: $line"
                }
                
                # Check for file operations
                if ($line -match "FileProvider|Content|Database|Store") {
                    Log-Activity "FILE OP: $line"
                }
                
                # Check for crashes
                if ($line -match "CRASH|Exception|Error|ANR") {
                    Log-Activity "ERROR: $line"
                }
                
                # Check for network activity
                if ($line -match "HTTP|socket|connection") {
                    Log-Activity "NETWORK: $line"
                }
            }
            
            $lastPos = $currentLines
        }
    }
    
    Start-Sleep -Milliseconds 500
}
