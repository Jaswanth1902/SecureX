# Distributed Deployment Guide
## Mobile App (Your Laptop/Phone) → Server (Friend's Computer) → Desktop App (Friend's Computer)

This guide explains how to set up the Secure File Print System across two locations where:
- **You**: Run the mobile app on your phone to upload files
- **Your Friend**: Runs the backend server and desktop app to receive and print files

---

## 🎯 Overview

```
┌─────────────────────┐         ┌──────────────────────────┐
│   YOUR SETUP        │         │   FRIEND'S SETUP         │
│                     │         │                          │
│  📱 Mobile App      │  WiFi/  │  🖥️  Backend Server      │
│  (Android Phone)    │  ────►  │  (Docker/Node.js)        │
│                     │ Internet│         │                │
│  💻 Your Laptop     │         │         ▼                │
│  (Dev Environment)  │         │  🖨️  Desktop App         │
│                     │         │  (Flutter - Windows)     │
└─────────────────────┘         └──────────────────────────┘

Flow: Mobile App → Backend API → Desktop App → Printer
```

---

## 📋 Prerequisites

### Your Requirements (Mobile App User)
- ✅ Android phone with USB debugging enabled **OR** built APK
- ✅ Laptop with Flutter SDK installed (for development)
- ✅ WiFi connection (same network as friend OR internet access)
- ✅ Your friend's server IP address and port

### Your Friend's Requirements (Server + Desktop Owner)
- ✅ Windows computer (for desktop app)
- ✅ Docker Desktop installed **OR** Node.js 18+ installed
- ✅ Static local IP address or public IP (for you to connect)
- ✅ Port 5000 accessible (firewall configured)
- ✅ Flutter SDK installed (to build desktop app)

---

## 🚀 Part 1: Friend's Setup (Server Side)

Your friend needs to set up and run the backend server and desktop app.

### Step 1.1: Prepare the Project

```bash
# Navigate to the project directory
cd "C:\path\to\Prefinal"

# Verify all files are present
dir backend
dir desktop_app
```

---

### Step 1.2: Configure the Backend Server

#### Option A: Using Docker (Recommended)

```bash
# Navigate to backend directory
cd backend

# Verify Docker is installed
docker --version
docker-compose --version

# Start the server
docker-compose up --build
```

**Expected Output:**
```
✓ Network secure_print_network created
✓ Container secure_print_db started
✓ Container secure_print_backend started
Server running on http://localhost:5000
```

#### Option B: Without Docker (Manual Setup)

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Set up environment variables
copy .env.example .env

# Edit .env file and set (generate secure values):
# - JWT_SECRET (minimum 32 characters)
#   Generate with: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
# - ENCRYPTION_KEY (minimum 32 characters)
#   Generate with: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
# - DB credentials (use strong password)

# Start PostgreSQL database (must be running separately)
# Option 1: Using Windows Service (if PostgreSQL is installed as a service)
net start postgresql-x64-14

# Option 2: If using pgAdmin, ensure the PostgreSQL service is running
# Option 3: Using command line (if PostgreSQL bin is in PATH)
psql -U postgres
# Then press Ctrl+C to exit psql after confirming it's running

# Run database migrations
npm run migrate

# Start the server
npm start
```

**Expected Output:**
```
==================================================
Secure File Printing System - API Server
Server running on http://localhost:5000
Environment: development
==================================================
```

---

### Step 1.3: Find Friend's IP Address

Your friend needs to find their computer's IP address:

#### On Windows:
```cmd
ipconfig

# Look for "IPv4 Address" under your active network adapter
# Example: 192.168.1.100
```

#### Important Notes:
- **Same WiFi Network**: Use local IP (e.g., `192.168.1.100`)
- **Different Networks**: Use public IP or set up port forwarding/ngrok

---

### Step 1.4: Configure Firewall (Windows)

Your friend must allow incoming connections on port 5000:

```powershell
# Open PowerShell as Administrator
# Add firewall rule
New-NetFirewallRule -DisplayName "Secure Print Backend" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

**OR use Windows Firewall GUI:**
1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules" → "New Rule"
4. Select "Port" → Next
5. Select "TCP" and enter port `5000` → Next
6. Select "Allow the connection" → Next
7. Check all profiles → Next
8. Name it "Secure Print Backend" → Finish

---

### Step 1.5: Test Server Accessibility

Your friend should test if the server is accessible:

```bash
# Test locally first
curl http://localhost:5000/health

# Test from local network (replace with actual IP)
curl http://192.168.1.100:5000/health
```

**Expected Response:**
```json
{
  "status": "OK",
  "timestamp": "2025-11-22T03:07:10.000Z",
  "environment": "production"
}
```

---

### Step 1.6: Build and Run Desktop App

```bash
# Navigate to desktop app directory
cd desktop_app

# Install dependencies
flutter pub get

# Build for Windows (release mode)
flutter build windows --release

# Run the desktop app
cd build\windows\runner\Release
.\desktop_app.exe
```

**OR for development:**
```bash
cd desktop_app
flutter run -d windows
```

---

### Step 1.7: Configure Desktop App API Endpoint

Before running, update the API endpoint in the desktop app to point to localhost:

**Edit:** `desktop_app\lib\config\api_config.dart` (or similar)

class ApiConfig {
  // If server is on SAME machine:
  static const String baseUrl = 'http://localhost:5000';
  
  // If server is on a different machine on the same network:
  // Replace with the server's local IP (e.g., 192.168.1.100)
  // static const String baseUrl = 'http://192.168.1.100:5000';
}---

## 📱 Part 2: Your Setup (Mobile App Side)

### Step 2.1: Get Friend's Server Details

Obtain from your friend:
- ✅ **IP Address**: e.g., `192.168.1.100` (local) or `203.0.113.50` (public)
- ✅ **Port**: `5000` (default)
- ✅ **Full URL**: `http://192.168.1.100:5000`

---

### Step 2.2: Configure Mobile App API Endpoint

**Edit:** `mobile_app\lib\config\api_config.dart`

```dart
class ApiConfig {
  // Replace with your friend's IP address
  static const String baseUrl = 'http://192.168.1.100:5000';
  
  // Endpoints
  static const String uploadEndpoint = '/api/files/upload';
  static const String authEndpoint = '/api/auth/login';
}
```

**⚠️ IMPORTANT:** 
- Use `http://` (not `https://`) for local development
- Use your friend's actual IP address
- **DO NOT** use `localhost` or `127.0.0.1` (these point to your own device)

---

### Step 2.3: Build the Mobile App APK

#### Option A: Build APK and Install Manually

```bash
# Navigate to mobile app directory
cd mobile_app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release

# APK location: build\app\outputs\flutter-apk\app-release.apk
```

**Transfer APK to your phone:**
1. Connect phone via USB
2. Copy `app-release.apk` to your phone's Downloads folder
3. On your phone, open the APK and install
4. You may need to enable "Install from Unknown Sources"

#### Option B: Run Directly on Connected Phone

```bash
# Enable USB debugging on your Android phone
# Connect phone to laptop via USB

# Verify device is detected
flutter devices

# Run the app on the connected device
flutter run --release
```

---

### Step 2.4: Connect Phone to Same Network

**For Local Network (Same WiFi):**
1. Ensure your phone is connected to the **same WiFi network** as your friend's computer
2. Both devices should be on the same subnet (e.g., 192.168.1.x)

**For Different Networks (Internet):**
Your friend needs to:
1. Set up port forwarding on their router (port 5000 → their computer's local IP)
2. Share their public IP address with you
3. OR use a tunneling service like ngrok (recommended for testing):

   **Friend's steps:**
   ```bash
   # Install ngrok from https://ngrok.com/download
   # Run ngrok to create HTTPS tunnel
   ngrok http 5000
   ```

   **Expected output:**
   ```
   Forwarding  https://abc123.ngrok.io -> http://localhost:5000
   ```

   **⚠️ Important: ngrok provides HTTPS endpoints**

   **Friend must update backend CORS:**
   
   Edit `backend/.env` or `backend/docker-compose.yml`:
   ```
   CORS_ORIGIN=https://abc123.ngrok.io
   ```
   
   Then restart the backend:
   ```bash
   docker-compose down
   docker-compose up
   ```

   **You must update mobile app configuration:**
   
   Edit `mobile_app\lib\services\api_service.dart`:
   ```dart
   final String baseUrl = 'https://abc123.ngrok.io';  // Use HTTPS!
   ```
   
   **📝 Replace `abc123.ngrok.io` with your actual ngrok URL**
   
   Then rebuild and reinstall the mobile app:
   ```bash
   flutter clean
   flutter build apk --release
   # Install new APK on phone
   ```

---

## 🧪 Part 3: Testing the Complete Flow

### Step 3.1: Test Network Connectivity

**On your phone:**
1. Open a browser
2. Navigate to `http://192.168.1.100:5000/health` (use friend's IP)
3. You should see the health check JSON response

**If connection fails:**
- Verify IP address is correct
- Check both devices are on same network
- Verify firewall is not blocking port 5000
- Try pinging the server: use a network tool app

---

### Step 3.2: Create User Accounts

**Your friend (on desktop app):**
1. Open Desktop App
2. Create an **Owner account**
3. Note the credentials

**You (on mobile app):**
1. Open Mobile App
2. **Register** a new user account OR
3. **Login** if account was created on the server

---

### Step 3.3: Upload a File from Mobile App

**On your mobile app:**

1. **Login** with your credentials
2. Click **"Upload File"** or similar button
3. **Select a file** from your phone (document, image, PDF)
4. The app will:
   - ✅ Encrypt the file on your device
   - ✅ Upload encrypted data to the server
   - ✅ Server stores encrypted file
5. You should see a **success message** with a file ID

**What happens behind the scenes:**
```
Mobile App (Your Phone)
   │
   ├─► 1. User selects file
   ├─► 2. File is encrypted using AES encryption
   ├─► 3. Encrypted file sent to server via HTTP (local) or HTTPS (internet)   │
   ▼
Backend API (Friend's Server)
   │
   ├─► 4. Receives encrypted file
   ├─► 5. Stores in database with metadata
   ├─► 6. Returns success + file ID
   │
   ▼
Desktop App (Friend's Computer)
   │
   ├─► 7. Polls server for new files
   ├─► 8. Downloads encrypted file
   ├─► 9. Decrypts file
   └─► 10. Shows print-ready file
```

---

### Step 3.4: Receive and Print File (Friend's Side)

**Your friend (on desktop app):**

1. The desktop app should automatically **detect new files**
2. Files appear in the **print queue**
3. Select the file you uploaded
4. The app will:
   - ✅ Download encrypted file from server
   - ✅ Decrypt the file
   - ✅ Display the file (print-ready)
5. Click **"Print"** to send to printer

---

## 🔧 Troubleshooting

### Problem: Mobile app can't connect to server

**Solution:**
```bash
# 1. Verify friend's server is running
curl http://192.168.1.100:5000/health

# 2. Check firewall on friend's computer
# 3. Verify both on same network
# 4. Try ping test from your phone
```

### Problem: "Network Error" or "Connection Refused"

**Checklist:**
- [ ] Friend's backend server is running
- [ ] Correct IP address in mobile app config
- [ ] Port 5000 is not blocked by firewall
- [ ] Both devices on same network
- [ ] Server is listening on `0.0.0.0` not `127.0.0.1`

**Fix for server binding:**

Edit `backend/docker-compose.yml`:
```yaml
environment:
  HOST: 0.0.0.0  # Listen on all interfaces
```

Or in `backend/server.js`:
```javascript
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`);
});
```

### Problem: File upload fails

**Check:**
1. User is authenticated (valid JWT token)
2. File size is within limit (100MB default)
3. CORS is configured correctly on server
4. Check server logs: `docker-compose logs backend`

### Problem: Desktop app doesn't show uploaded files

**Check:**
1. Desktop app is logged in as owner
2. API endpoint is correct in desktop app
3. Database contains the file records
4. Check desktop app logs for errors

---

## 🔒 Security Considerations

### For Local Network Testing:
- ✅ Use HTTP (encryption handled in application layer)
- ✅ Ensure you trust the network
- ✅ Files are encrypted before transmission

### For Internet/Public Deployment:
- ⚠️ **Use HTTPS with valid SSL certificate**
- ⚠️ Set up reverse proxy (nginx, Traefik)
- ⚠️ Use strong authentication
- ⚠️ Enable rate limiting
- ⚠️ Use VPN if possible

---

## 📝 Quick Reference Commands

### Friend's Computer (Server + Desktop)

```bash
# Start backend server
cd backend
docker-compose up

# Run desktop app (development)
cd desktop_app
flutter run -d windows

# Check server status
curl http://localhost:5000/health

# View logs
docker-compose logs -f backend
```

### Your Laptop (Mobile Development)

```bash
# Build and run on phone
cd mobile_app
flutter run --release

# Build APK
flutter build apk --release

# Check connected devices
flutter devices
```

---

## ✅ Success Checklist

Before testing the complete flow:

### Friend's Setup:
- [ ] Backend server running on port 5000
- [ ] Server accessible from network (health check works)
- [ ] Firewall allows port 5000
- [ ] Desktop app running and logged in as owner
- [ ] IP address shared with you

### Your Setup:
- [ ] Mobile app configured with correct server IP
- [ ] Phone connected to same network OR internet
- [ ] Can access server from phone browser
- [ ] Mobile app installed and running
- [ ] User account created

### Test Flow:
- [ ] Mobile app connects to server
- [ ] User can login
- [ ] File upload succeeds
- [ ] Desktop app receives file notification
- [ ] File can be decrypted and viewed
- [ ] Print functionality works

---

## 🎓 Example Session

### Friend's Terminal:
```bash
C:\Prefinal\backend> docker-compose up
Starting secure_print_db ... done
Starting secure_print_backend ... done
Backend running on http://0.0.0.0:5000

# In another terminal
C:\Prefinal\desktop_app> flutter run -d windows
Launching desktop_app on Windows...
Running on Windows (debug mode)
Desktop app connected to: http://localhost:5000
```

### Your Actions:
1. Open mobile app on phone
2. Login with credentials
3. Tap "Upload File"
4. Select `my_document.pdf`
5. See "Upload successful! File ID: abc123"

### Friend Sees:
1. Desktop app notification: "New file received"
2. File appears in print queue: `my_document.pdf`
3. Clicks file to preview (decrypted)
4. Clicks "Print" → sent to printer

---

## 🆘 Need Help?

**Check Logs:**
- Backend: `docker-compose logs backend`
- Mobile: `flutter logs`
- Desktop: Check console output

**Common Issues:**
- Connection refused → Check firewall
- 401 Unauthorized → Check authentication
- 404 Not Found → Wrong endpoint URL
- Timeout → Server not running or network issue

**Network Testing Tools:**
- Mobile: "Fing" app (network scanner)
- Desktop: `telnet 192.168.1.100 5000`
- Browser: `http://FRIEND_IP:5000/health`

---

## 📞 Support

For detailed API documentation, see:
- [Backend API Guide](backend/API_GUIDE.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Project Overview](00_START_HERE_FIRST.md)

---

**Happy Printing! 🖨️✨**
