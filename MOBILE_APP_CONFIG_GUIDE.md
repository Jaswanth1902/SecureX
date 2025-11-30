# Mobile App Configuration Guide
## Connecting to Your Friend's Server

---

## 📍 What You Need to Change

**File to Edit:** `mobile_app\lib\services\api_service.dart`

**Line to Change:** Line 11

---

## ✏️ Step-by-Step Instructions

### Step 1: Get Friend's Server IP Address

Your friend needs to run this command on their computer:

**Windows:**
```cmd
ipconfig
```

**Look for:** `IPv4 Address` under their active WiFi/Ethernet adapter

**Example Output:**
```
Wireless LAN adapter Wi-Fi:
   IPv4 Address. . . . . . . . . . . : 192.168.1.100
```

**✓ Write down:** `192.168.1.100` (this is the IP address)

---

### Step 2: Edit the Mobile App Configuration

**Open File:**
```
mobile_app\lib\services\api_service.dart
```

**Find Line 11:**
```dart
final String baseUrl = 'http://localhost:5000';
```

**Change To:**
```dart
final String baseUrl = 'http://192.168.1.100:5000';  // Use friend's IP
```

**⚠️ Important:**
- Replace `192.168.1.100` with your friend's **actual IP address**
- Keep `http://` (not `https://`)
- Keep `:5000` port at the end
- **DO NOT** use `localhost` or `127.0.0.1`

---

## 🎯 Quick Reference

| Scenario | baseUrl Value | Example |
|----------|---------------|---------|
| **Same WiFi Network** | `http://[friend's local IP]:5000` | `http://192.168.1.100:5000` |
| **Different Networks (ngrok)** | `https://[ngrok URL]` | `https://abc123.ngrok.io` |
| **Testing Locally** | `http://localhost:5000` | `http://localhost:5000` |

---

## ✅ Verification

After changing the configuration:

### Test 1: Build the App
```bash
cd mobile_app
flutter clean
flutter pub get
flutter build apk --release
```

**✓ Expected:** Build completes without errors

### Test 2: Test Connection (On Your Phone)

1. Open phone browser
2. Navigate to: `http://192.168.1.100:5000/health` (use friend's IP)
3. **✓ Expected:** See JSON response like:
   ```json
   {
     "status": "OK",
     "timestamp": "2025-11-22T...",
     "environment": "production"
   }
   ```

### Test 3: Run the App

1. Install APK on your phone
2. Open the app
3. Try to login/register
4. **✓ Expected:** Connection successful, no network errors

---

## 🔧 Troubleshooting

### Error: "Failed to connect to /192.168.1.100:5000"

**Solution:**
- Check friend's server is running: `docker-compose ps`
- Verify both on same WiFi network
- Ping friend's IP from your phone using a network tool app

### Error: "Connection refused"

**Solution:**
- Friend needs to allow port 5000 in firewall
- Server must be listening on `0.0.0.0` not `127.0.0.1`

### Error: "No route to host"

**Solution:**
- Verify IP address is correct
- Check both devices are on same subnet (e.g., 192.168.1.x)

---

## 🌐 Alternative: Using ngrok (For Different Networks)

If you and your friend are **NOT on the same WiFi**:

### Friend's Setup (with ngrok):

```bash
# Download and install ngrok
# https://ngrok.com/download

# Start ngrok tunnel
ngrok http 5000
```

**Output:**
```
Forwarding: https://abc123.ngrok.io -> http://localhost:5000
```

### Your Configuration:

```dart
final String baseUrl = 'https://abc123.ngrok.io';  // Use ngrok URL
```

**⚠️ Note:** Free ngrok URLs change each time, so you'll need to update this frequently

---

## 📝 Summary

1. **Get** friend's IP address (`ipconfig`)
2. **Edit** `api_service.dart` line 11
3. **Change** `localhost` to friend's IP
4. **Save** the file
5. **Build** the app (`flutter build apk`)
6. **Test** connection from phone browser
7. **Install** and run the app

---

## 🎯 Complete Example

### Before (Default):
```dart
class ApiService {
  final String baseUrl = 'http://localhost:5000';
  // Rest of the code...
```

### After (Connected to Friend):
```dart
class ApiService {
  final String baseUrl = 'http://192.168.1.100:5000';  // Friend's IP
  // Rest of the code...
```

---

## 🚨 Critical Checklist

Before testing:
- [x] Friend's server is running (`docker-compose up`)
- [x] Friend's IP address obtained (`ipconfig`)
- [x] `api_service.dart` updated with friend's IP
- [x] Mobile app rebuilt (`flutter build apk`)
- [x] Both devices on same WiFi network
- [x] Firewall allows port 5000 on friend's computer
- [x] Connection tested from phone browser

---

**Once configured, you're ready to upload files from your phone to your friend's server!** 🚀
