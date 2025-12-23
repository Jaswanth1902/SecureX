# Quick Setup Checklist
## You (Mobile App) → Friend (Server + Desktop)

---

## 🎯 Goal
Upload a file from your phone → Encrypted → Sent to friend's server → Friend's desktop receives and can print

---

## ✅ Your Friend's Checklist (Server Owner)

### 0. Prerequisites

Before starting, ensure you have:

- [ ] **Docker & Docker Compose** installed and running
- [ ] **Flutter SDK** installed (run `flutter --version` to verify)
- [ ] **Administrator access** for firewall configuration
- [ ] **Port 5000 available** (not used by other applications)
- [ ] **Connected to WiFi network** that mobile user will access

---

### 1. Start Backend Server
```bash
cd Prefinal/backend
docker-compose up
```
**✓ Expected:** Server running on http://localhost:5000

### 2. Find IP Address
```cmd
ipconfig
```
**✓ Write down:** IPv4 Address (e.g., `192.168.1.100`)

### 3. Configure Firewall
```powershell
# As Administrator
New-NetFirewallRule -DisplayName "Secure Print Backend" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

### 4. Test Server
```bash
curl http://localhost:5000/health
```
**✓ Expected:** `{"status":"OK",...}`

### 5. Build Desktop App
```bash
cd Prefinal/desktop_app
flutter pub get
flutter build windows --release
cd build\windows\runner\Release
.\desktop_app.exe
```

### 6. Share with You
**Send to your friend:**
- IP Address: `192.168.1.100`
- Port: `5000`
- Full URL: `http://192.168.1.100:5000`

---

## ✅ Your Checklist (Mobile App User)

### 1. Update API Configuration

**Edit:** `mobile_app/lib/config/api_config.dart`

```dart
static const String baseUrl = 'http://192.168.1.100:5000'; // Use friend's IP
```

### 2. Build Mobile App

**Option A - Install APK:**
```bash
cd mobile_app
flutter build apk --release
# Copy build/app/outputs/flutter-apk/app-release.apk to phone
# Install on phone
```

**Option B - Run directly:**
```bash
cd mobile_app
flutter run --release
# (Phone must be connected via USB)
```

### 3. Connect to Same WiFi
- ✓ Same network as your friend's computer
- ✓ Both on 192.168.1.x subnet

### 4. Test Connection
- Open browser on phone
- Go to: `http://192.168.1.100:5000/health`
- Should see JSON response

### 5. Use Mobile App
1. Open mobile app
2. Register/Login
3. Upload file
4. ✓ Success!

---

## 🧪 Testing Flow

### Step 1: You upload file
```
Mobile App → Select file → Encrypt → Upload
```
**✓ Expected:** "Upload successful" message

### Step 2: Friend receives
```
Desktop App → New file notification → Decrypt → View
```
**✓ Expected:** File appears in print queue

### Step 3: Friend prints
```
Desktop App → Select file → Print
```
**✓ Expected:** File sent to printer

---

## 🔧 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't connect | Check both on same WiFi, verify IP address |
| Connection refused | Check firewall, ensure server running |
| Port 5000 already in use | **Windows:** `netstat -ano \| findstr :5000` then `taskkill /PID <PID> /F`<br>**macOS/Linux:** `lsof -i :5000` or `sudo ss -ltnp \| grep :5000` then `kill <PID>`<br>**Or:** Start server on different port: `PORT=5001 docker-compose up` |
| Upload fails | Check authentication, verify file size < 100MB |
| Desktop doesn't receive | Verify desktop app is logged in as owner |

---

## 📱 Network Testing

**On your phone browser:**
```
http://192.168.1.100:5000/health
```

**Expected:**
```json
{
  "status": "OK",
  "timestamp": "2025-11-22T...",
  "environment": "production"
}
```

---

## 🚨 Important Notes

- ⚠️ Use friend's **actual IP address** (not localhost)
- ⚠️ Both must be on **same WiFi network**
- ⚠️ Friend's server must be **running** before you test
- ⚠️ Files are **encrypted** before upload
- ⚠️ Friend needs to be logged in as **owner** on desktop app

---

## 🎯 One-Liner Commands

### Friend (Windows):
```powershell
# Start everything
cd backend; docker-compose up
# In new terminal:
cd desktop_app; flutter run -d windows
```

### You:
```bash
# Build and install
cd mobile_app
flutter build apk --release
# Transfer APK to phone and install
```

---

## 📞 Emergency Commands

### Friend - Check Server Status:
```bash
docker-compose ps
docker-compose logs backend
```

### Friend - Restart Server:
```bash
docker-compose down
docker-compose up
```

### You - Rebuild App:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

## ✅ Success Criteria (Check off as you complete each step)

- [ ] Friend's server running and accessible
- [ ] Your mobile app configured with friend's IP
- [ ] Both on same network
- [ ] You can upload file from mobile app
- [ ] Friend's desktop app receives and displays file
- [ ] File can be printed
---

**For detailed instructions, see:** [DISTRIBUTED_DEPLOYMENT_GUIDE.md](DISTRIBUTED_DEPLOYMENT_GUIDE.md)
