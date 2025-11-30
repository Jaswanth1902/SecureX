# Mobile App Activity Monitor Script
# Monitors SafeCopy app (com.jaswanth.saveandorganize) on connected Android device

$logDir = "c:\Users\jaswa\Downloads\SafeCopy"
$activityLog = "$logDir\MOBILE_APP_ACTIVITY_LOG.md"
$logcatFile = "$logDir\app_logcat_stream.txt"
$summaryLog = "$logDir\ACTIVITY_SUMMARY.txt"

function Add-ActivityLog {
    param(
        [string]$Activity,
        [string]$Details = "",
        [string]$Severity = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Severity] $Activity"
    if ($Details) {
        $logEntry += "`n  Details: $Details"
    }
    
    Add-Content -Path $activityLog -Value "`n$logEntry"
    Add-Content -Path $summaryLog -Value "`n$logEntry"
    Write-Host $logEntry
}

# Initialize logs
$header = @"
# Mobile App Activity Monitor - Real-Time Tracking
**Start Time**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Device**: Samsung Android (10BE5820BZ0009L)
**App Package**: com.jaswanth.saveandorganize
**App Name**: SafeCopy
**Branch**: MobileF1
**Monitoring Method**: ADB Logcat

---

## Activity Events

"@

Set-Content -Path $activityLog -Value $header
Set-Content -Path $summaryLog -Value "MOBILE APP ACTIVITY SUMMARY`n$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"

Add-ActivityLog "Activity Monitor Started" "Monitoring SafeCopy app for real-time activity" "START"

# Main monitoring loop
while ($true) {
    $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Check if app is running
    $appRunning = adb shell pidof com.jaswanth.saveandorganize 2>$null
    
    if ($appRunning) {
        Add-ActivityLog "App Running" "PID: $appRunning" "RUNNING"
        
        # Get app info
        $appState = adb shell dumpsys window windows | Select-String "com.jaswanth.saveandorganize" -ErrorAction SilentlyContinue
        if ($appState) {
            Add-ActivityLog "Window State" "App window is visible" "ACTIVE"
        }
        
        # Check for file operations
        $fileOps = adb shell logcat | Select-String "FileObserver|ContentProvider|database" -ErrorAction SilentlyContinue | Select-Object -First 5
        if ($fileOps) {
            Add-ActivityLog "File Operations Detected" "$fileOps" "FILE_OP"
        }
        
        # Check logcat for errors
        $errors = adb shell logcat | Select-String "ERROR|EXCEPTION|Crash" -ErrorAction SilentlyContinue | Select-Object -First 3
        if ($errors) {
            Add-ActivityLog "Errors Detected" "$errors" "ERROR"
        }
    } else {
        Add-ActivityLog "App Not Running" "" "INACTIVE"
    }
    
    # Wait before next check
    Start-Sleep -Seconds 30
}
