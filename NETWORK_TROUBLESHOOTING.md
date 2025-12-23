# Network Connectivity Troubleshooting Guide

## Error Analysis
**Error:** `No route to host (OS Error: No route to host, errno = 113)`  
**Target:** `10.83.12.71:5000`

This means the mobile device cannot establish a connection to the backend server.

---

## Step 1: Verify Backend Server IP Address

Your backend is currently configured to listen on `0.0.0.0:5000` (all network interfaces).

### Check Your Current IP Address:

**Windows:**
```bash
ipconfig
```

Look for your **WiFi adapter's IPv4 address**. Common patterns:
- `192.168.x.x` (Home WiFi)
- `10.x.x.x` (Some networks)
- `172.16.x.x` to `172.31.x.x` (Private networks)

**Current configured IP in mobile app:** `10.83.12.71`

---

## Step 2: Verify Backend is Running and Accessible

### A. Check if backend is listening on port 5000:
```bash
netstat -an | findstr :5000
```

You should see:
```
TCP    0.0.0.0:5000           0.0.0.0:0              LISTENING
```

### B. Test from your PC browser:
```
http://localhost:5000/health
http://<YOUR_IP>:5000/health
```

Both should return: `{"status":"OK","environment":"development"}`

---

## Step 3: Test Network Connectivity

### From Your PC:

**Option 1: Using curl (if installed)**
```bash
curl http://10.83.12.71:5000/health
```

**Option 2: Using PowerShell**
```powershell
Invoke-WebRequest -Uri "http://10.83.12.71:5000/health"
```

If these fail, your PC's IP has changed!

---

## Step 4: Fix the Issue

### Scenario A: IP Address Changed ✅ MOST LIKELY

Your WiFi IP address has changed from `10.83.12.71` to something else.

**Solution:**
1. Run `ipconfig` and note your **current** WiFi IPv4 address
2. Update mobile app:
   ```dart
   // File: mobile_app/lib/services/api_service.dart (line 11)
   final String baseUrl = 'http://YOUR_NEW_IP:5000';
   ```
3. Rebuild: `flutter build apk`
4. Install: `flutter install --device-id=10BE5820BZ0009L`

---

### Scenario B: Firewall Blocking Connection

Windows Firewall might be blocking incoming connections.

**Solution:**
```powershell
# Run PowerShell as Administrator
netsh advfirewall firewall add rule name="Flask Server" dir=in action=allow protocol=TCP localport=5000
```

Or use Windows Firewall GUI:
1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules" → "New Rule"
4. Port → TCP → 5000 → Allow the connection
5. Name it "SafeCopy Backend"

---

### Scenario C: Mobile and PC on Different Networks

**Check:**
- PC connected to WiFi: `YOUR_WIFI_NAME`
- Mobile connected to WiFi: `SAME_WIFI_NAME` ← Must match!

**Solution:**
- Connect both devices to the same WiFi network
- Disable mobile data on your phone
- Some WiFi routers have "AP Isolation" - disable it in router settings

---

## Step 5: Alternative - Use USB Debugging (Temporary)

If network issues persist, use ADB port forwarding:

```bash
# Forward mobile port 5000 to PC port 5000
adb -s 10BE5820BZ0009L reverse tcp:5000 tcp:5000
```

Then in mobile app:
```dart
final String baseUrl = 'http://localhost:5000';
```

This makes the app connect through USB instead of WiFi.

---

## Quick Fix Commands

**1. Find your current IP:**
```bash
ipconfig | findstr IPv4
```

**2. Test backend connectivity:**
```bash
curl http://localhost:5000/health
curl http://YOUR_IP:5000/health
```

**3. Check if port 5000 is listening:**
```bash
netstat -an | findstr :5000
```

**4. Add firewall rule:**
```powershell
netsh advfirewall firewall add rule name="SafeCopy_Backend" dir=in action=allow protocol=TCP localport=5000
```

**5. Test from mobile (using ADB):**
```bash
adb -s 10BE5820BZ0009L shell curl http://YOUR_IP:5000/health
```

---

## Common Issues Checklist

- [ ] Backend server is running (`python app.py`)
- [ ] Server shows "Server running on http://0.0.0.0:5000"
- [ ] Both devices on same WiFi network
- [ ] Mobile data disabled on phone
- [ ] Firewall allows port 5000
- [ ] IP address in mobile app matches current PC IP
- [ ] Can access http://YOUR_IP:5000/health from PC browser

---

## Expected Log Output (When Working)

**Backend console should show:**
```
Server running on http://0.0.0.0:5000
Flask server started on port 5000
```

**Mobile app should show:**
```
Upload details:
   Owner ID: surya@gmail.com
   File name: environment_final_report_vf.pdf
   Base URL: http://10.83.12.71:5000
✅ Public key retrieved successfully
✅ Symmetric key encrypted
📤 Uploading file...
✅ File uploaded successfully
```

**NOT:**
```
❌ Upload error: Get public key error: ClientException with SocketException: No route to host
```
