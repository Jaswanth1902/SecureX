# 📋 Share This With Your Friend
## Server Owner Setup Instructions

Hi! Your friend wants to use the Secure File Print System to upload files from their phone to your computer for printing. This guide will help you set up the server and desktop app.

---

## 🎯 What You'll Be Running

1. **Backend Server** (API) - Receives encrypted files from your friend's phone
2. **Desktop App** (Windows) - Shows files in print queue and allows printing

---

## ⏱️ Time Required: 15 minutes

---

## 📋 Prerequisites

Make sure you have:
- [ ] Windows computer
- [ ] Docker Desktop installed ([Download](https://docs.docker.com/desktop/install/windows-install/))
- [ ] Flutter SDK installed ([Download](https://docs.flutter.dev/get-started/install/windows))
- [ ] 2GB free disk space
- [ ] Same WiFi network as your friend OR internet connection

---

## 🚀 Step-by-Step Setup

### Step 1: Navigate to Project Directory

```powershell
# Open PowerShell
cd "C:\path\to\Prefinal"
```

### Step 2: Start Backend Server

```powershell
cd backend
docker-compose up
```

**Wait for:**
```
✓ Container secure_print_db started
✓ Container secure_print_backend started
Server running on http://localhost:5000
```

**Keep this terminal window open!**

---

### Step 3: Find Your IP Address

Open a **new PowerShell window**:

```powershell
ipconfig
```

**Look for:**
```
Wireless LAN adapter Wi-Fi:
   IPv4 Address. . . . . . . . . . . : 192.168.1.100
```

**Write down your IP:** `192.168.1.100` ⬅️ **Share this with your friend!**

---

### Step 4: Configure Firewall

**Open PowerShell as Administrator** and run:

```powershell
New-NetFirewallRule -DisplayName "Secure Print Backend" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

**You should see:** "OK" message

**Alternative (GUI method):**
1. Open "Windows Defender Firewall"
2. Click "Advanced settings"
3. Click "Inbound Rules" → "New Rule"
4. Select "Port" → Next
5. Enter port `5000` → Next
6. Select "Allow the connection" → Finish

---

### Step 5: Test Server

Still in PowerShell:

```powershell
curl http://localhost:5000/health
```

**Expected response:**
```json
{"status":"OK","timestamp":"2025-11-22T...","environment":"production"}
```

✅ If you see this, your server is working!

---

### Step 6: Start Desktop App

Open a **third PowerShell window**:

```powershell
cd "C:\path\to\Prefinal\desktop_app"
flutter pub get
flutter run -d windows
```

**Wait for the app to open**

---

### Step 7: Create Owner Account

In the desktop app:
1. Click "Register" (if no account exists)
2. Create owner account with:
2. Create owner account with:
   - Email: Your email address (e.g., your_name@gmail.com)
   - Password: A strong password (8+ characters, mix of upper/lower/numbers/symbols)3. Login with these credentials

✅ You should now see the main screen with an empty print queue

---

### Step 8: Share Information with Your Friend

Send your friend this information:

```
Server IP: 192.168.1.100
Port: 5000
Full URL: http://192.168.1.100:5000

Make sure you're on the same WiFi network!
```

---

## ✅ Verification Checklist

Before your friend tests, verify:

- [ ] Backend server is running (PowerShell window shows logs)
- [ ] Desktop app is open and logged in
- [ ] Firewall allows port 5000
- [ ] Server responds to health check
- [ ] You and your friend are on the same WiFi

---

## 📱 When Your Friend Uploads a File

You will see:

1. **Desktop App Notification**: "New file received"
2. **File appears in print queue** with details:
   - File name
   - Upload time
   - File size
   - Sender email

3. **Click the file** to preview (will be automatically decrypted)
4. **Click "Print"** to send to your printer

---

## 🔧 Troubleshooting

### Server won't start

```powershell
# Check if Docker is running
docker --version

# Check if ports are available
netstat -ano | findstr :5000

# Restart Docker Desktop
```

### Desktop app won't connect

```powershell
# Check if server is running
curl http://localhost:5000/health

# Restart the desktop app
```

### Friend can't connect

```powershell
# Verify your IP address
ipconfig

# Check firewall
Get-NetFirewallRule -DisplayName "Secure Print Backend"

# Test from your own browser
http://192.168.1.100:5000/health
```

---

## 🔒 Security Notes

- Files are **encrypted** before reaching your server
- You need the encryption key to decrypt and view files
- Only you (as owner) can see the uploaded files
- Files are stored securely in the database

---

## 🛑 Stopping the Server

When done:

1. **Stop Desktop App**: Close the window
2. **Stop Backend**: In PowerShell, press `Ctrl+C`
3. **Clean shutdown**:
   ```powershell
   docker-compose down
   ```

---

## 🔄 Starting Again Later

```powershell
# Terminal 1: Start backend
cd backend
docker-compose up

# Terminal 2: Start desktop
cd desktop_app
flutter run -d windows
```

---

## 📊 What's Running

```
Your Computer
├── Backend Server (Docker)
│   ├── PostgreSQL Database (port 5432)
│   └── Node.js API Server (port 5000)
│
└── Desktop App (Flutter)
    └── Connects to localhost:5000
```

---

## 💡 Tips

- **Keep terminal windows visible** to see logs
- **Don't close PowerShell** while using the system
- **Your IP may change** if you restart your router
- **Desktop app must be running** to receive files

---

## 🆘 Need Help?

**Check Logs:**
```powershell
# Backend logs
docker-compose logs backend

# Desktop app logs
# (visible in the PowerShell window where you ran it)
```

**Restart Everything:**
```powershell
# Stop backend
docker-compose down

# Start backend
docker-compose up

# Restart desktop app
# (close and run again)
```

---

## 📞 Contact

If something doesn't work:
1. Check the logs in PowerShell
2. Verify all steps were completed
3. Try restarting the server
4. Ask your friend if they can access `http://YOUR_IP:5000/health` from their browser

---

## ✅ Success!

When everything is working:
- ✅ Server running on port 5000
- ✅ Desktop app connected and logged in
- ✅ Your friend can access your server
- ✅ Files can be uploaded, decrypted, and printed

**You're all set!** 🎉

---

**Full documentation:** [DISTRIBUTED_DEPLOYMENT_GUIDE.md](DISTRIBUTED_DEPLOYMENT_GUIDE.md)
