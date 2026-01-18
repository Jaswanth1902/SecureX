# Mobile Hotspot File Upload - Troubleshooting Guide

## Current Setup
- **Laptop IP on Hotspot**: 192.168.204.34
- **Backend Port**: 5000
- **Backend URL**: http://192.168.204.34:5000
- **Backend Status**: ✅ Running and listening on 0.0.0.0:5000

## Connection Timeout Error
```
Error checking file statuses: TimeoutException after 0:00:10.000000: Future not completed
```

This means the mobile device cannot reach the laptop at 192.168.204.34:5000

## Troubleshooting Checklist

### Step 1: Verify Mobile Device Connection
- [ ] Mobile device is connected to your laptop's mobile hotspot
- [ ] Hotspot is actively enabled on your laptop
- [ ] Mobile device shows "Connected" status to the hotspot

### Step 2: Verify Network Connectivity
On your mobile device, try to ping or curl the laptop:
```bash
# If you have curl on device (Android shell)
curl http://192.168.204.34:5000

# Or try accessing any endpoint:
curl http://192.168.204.34:5000/health
```

### Step 3: Check Laptop Firewall
Windows Firewall might be blocking port 5000. Try one of these:

**Option A: Disable Firewall (NOT RECOMMENDED - temporary only)**
```powershell
netsh advfirewall set allprofiles state off
```

**Option B: Add Firewall Rule (RECOMMENDED)**
```powershell
# Run as Administrator
netsh advfirewall firewall add rule name="Flask Backend 5000" `
  dir=in action=allow protocol=tcp localport=5000
```

**Option C: Check Windows Defender**
1. Go to Windows Defender Firewall
2. Click "Allow an app through firewall"
3. Look for Python or flask
4. Ensure it's allowed for both Private and Public networks
5. If not listed, click "Allow another app" and add it

### Step 4: Verify Backend is Actually Listening
Run this on your laptop:
```powershell
netstat -ano | findstr :5000
```

Should show:
```
TCP    0.0.0.0:5000            LISTENING
```

### Step 5: Test from Laptop First
Before testing from mobile, confirm it works from laptop:
```powershell
# On same laptop as backend
curl http://127.0.0.1:5000
curl http://192.168.204.34:5000
```

### Step 6: Check Hotspot Network
Make sure laptop and mobile are on same hotspot network:

**On Laptop:**
```powershell
ipconfig
```
Look for "Mobile Hotspot" adapter - verify it shows 192.168.204.34

**On Mobile Device:**
- Go to WiFi settings
- Verify you're connected to your laptop's hotspot
- Note the IP address assigned to your phone (should be 192.168.20X.X)

### Step 7: Switch Network If Needed
If hotspot isn't working, try local WiFi:

Edit `mobile_app/lib/services/api_service.dart` line 24:
```dart
// Change from:
static const String BACKEND_IP = HOTSPOT_IP;

// To:
static const String BACKEND_IP = WIFI_IP;  // Uses 192.168.0.103
```

Then rebuild:
```bash
flutter run
```

## Quick Fix: Disable Firewall (Temporary)
If nothing works, temporarily disable Windows Firewall to test:

```powershell
# Disable all firewall profiles
netsh advfirewall set allprofiles state off

# Test with flutter run
# Then re-enable:
netsh advfirewall set allprofiles state on
```

## Network Configuration in App

File: `mobile_app/lib/services/api_service.dart`

**Line 13**: `WIFI_IP = '192.168.0.103'` (Local WiFi)
**Line 16**: `HOTSPOT_IP = '192.168.204.34'` (Mobile Hotspot) ← CURRENT
**Line 19**: `ETHERNET_IP = '192.168.56.1'` (Ethernet)
**Line 22**: `EMULATOR_IP = '10.0.2.2'` (Emulator)

**Line 24**: `static const String BACKEND_IP = HOTSPOT_IP;` ← ACTIVE

## Backend Server
- **Command**: `python app.py` in `backend_flask/` folder
- **Status**: ✅ Running and accepting connections
- **Listen Address**: 0.0.0.0:5000 (all interfaces)

## Expected Success
When connection works, you should see:
- File list loads (either cached files or live files from server)
- No timeout error
- Able to upload files
- File status updates

## Debug: Enable Logging
In `mobile_app/lib/screens/file_list_screen.dart`, add debug prints:

```dart
print('Connecting to: ${ApiService().baseUrl}');
print('Request timeout: 10 seconds');
```

This will show in Flutter logs during `flutter run`.

---
**Last Updated**: After setting hotspot IP to 192.168.204.34
**Backend Status**: Running ✅
**App Configuration**: Ready ✅
**Missing**: Network connectivity between mobile and laptop
