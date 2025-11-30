# Project start guide## Mobile App (Your Phone) → Backend Server (Friend's Computer) → Desktop App (Friend's Computer) → Printer![Distributed Deployment](./assets/distributed_deployment_diagram.png)
---

## 📊 System Architecture

![Distributed Deployment](file:///C:/Users/jaswa/.gemini/antigravity/brain/cd1da1e9-34e1-41d9-9b25-3d61506052b4/distributed_deployment_diagram_1763761227962.png)

---

## 🎯 Overview

This complete guide explains how to set up the Secure File Print System across two locations:

- **You (Mobile User)**: Run the mobile app on your phone to upload encrypted files
- **Your Friend (Server Owner)**: Run the backend server and desktop app to receive and print files

### How It Works

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
      (Encrypted)   (Stored)      (Decrypted)   (Printed)
```

---

## ⏱️ Time Required

- **Friend's Setup**: 15-20 minutes
- **Your Setup**: 10-15 minutes
- **Testing**: 5 minutes
- **Total**: ~30-40 minutes

---

## 📋 Prerequisites

### Your Requirements (Mobile User)

- ✅ Android phone with USB debugging enabled OR ability to transfer APK files
- ✅ Laptop with Flutter SDK installed (for building the app)
- ✅ WiFi connection (same network as friend OR internet access)
- ✅ Your friend's server IP address and port

### Friend's Requirements (Server Owner)

- ✅ Windows computer
- ✅ Docker Desktop installed ([Download](https://docs.docker.com/desktop/install/windows-install/))
- ✅ Flutter SDK installed ([Download](https://docs.flutter.dev/get-started/install/windows))
- ✅ Static local IP address or public IP
- ✅ Port 5000 available and accessible
- ✅ 2GB free disk space

---

# 🚀 PART 1: Friend's Setup (Server Owner)

Your friend needs to complete this section to set up the backend server and desktop app.

---

## Step 1.1: Navigate to Project Directory

Open PowerShell and navigate to the project:

```powershell
cd "C:\Users\[username]\OneDrive\Desktop\Homework\SEM-III\SEM-III EL\Prefinal"
```

Replace `[username]` with the actual Windows username.

---

## Step 1.2: Start Backend Server

### Using Docker (Recommended)

```powershell
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
Backend running on http://0.0.0.0:5000
```

**⚠️ Keep this PowerShell window open!** The server logs will appear here.

### Alternative: Without Docker

If Docker is not available:

```powershell
cd backend

# Install dependencies
npm install

# Copy environment file
copy .env.example .env

# Edit .env file and set:
# - JWT_SECRET (minimum 32 characters)
# - ENCRYPTION_KEY (minimum 32 characters)
# - Database credentials

# Start PostgreSQL (must be running separately)

# Run migrations
npm run migrate

# Start server
npm start
```

---

## Step 1.3: Find Your IP Address

Open a **new PowerShell window** (keep the server running):

```powershell
ipconfig
```

**Look for the IPv4 Address:**

```
Wireless LAN adapter Wi-Fi:
   Connection-specific DNS Suffix  . :
   IPv4 Address. . . . . . . . . . . : 192.168.1.100
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
```

**✍️ Write down your IP address:** `192.168.1.100`

**📱 Share this with your friend!** They need it to configure the mobile app.

### Important Notes

- **Same WiFi Network**: Use local IP (e.g., `192.168.1.100`)
- **Different Networks**: Use public IP or set up ngrok (see Network Setup section)

---

## Step 1.4: Configure Windows Firewall

Your friend must allow incoming connections on port 5000.

### Method 1: PowerShell (Quick)

**Open PowerShell as Administrator** and run:

```powershell
New-NetFirewallRule -DisplayName "Secure Print Backend" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

**Expected Output:** Rule created successfully

### Method 2: Windows Firewall GUI

1. Press `Win + R`, type `wf.msc`, press Enter
2. Click "Inbound Rules" in left panel
3. Click "New Rule..." in right panel
4. Select "Port" → Next
5. Select "TCP" and enter port `5000` → Next
6. Select "Allow the connection" → Next
7. Check all profiles (Domain, Private, Public) → Next
8. Name: "Secure Print Backend" → Finish

---

## Step 1.5: Test Server Accessibility

Still in the second PowerShell window:

```powershell
# Test locally
curl http://localhost:5000/health

# Test from your local network (use your actual IP)
curl http://192.168.1.100:5000/health
```

**Expected Response:**
```json
{
  "status": "OK",
  "timestamp": "2025-11-22T03:13:26.000Z",
  "environment": "production"
}
```

✅ **If you see this JSON, your server is working!**

---

## Step 1.6: Build and Run Desktop App

Open a **third PowerShell window**:

```powershell
# Navigate to desktop app
cd "C:\Users\[username]\OneDrive\Desktop\Homework\SEM-III\SEM-III EL\Prefinal\desktop_app"

# Install dependencies
flutter pub get

# Run the desktop app (development mode)
flutter run -d windows
```

**For production build:**
```powershell
flutter build windows --release
cd build\windows\runner\Release
.\desktop_app.exe
```

**Wait for the desktop app window to open.**

---

## Step 1.7: Configure Desktop App (If Needed)

The desktop app should connect to `http://localhost:5000` by default.

If you need to verify, check the configuration file (usually no change needed):

**File:** `desktop_app\lib\services\api_service.dart`

```dart
final String baseUrl = 'http://localhost:5000';  // Should be localhost for friend
```

---

## Step 1.8: Create Owner Account

In the desktop app:

1. Click **"Register"** (if no account exists)
2. Fill in owner details:
   - **Email**: `owner@example.com`
   - **Password**: `YourSecurePassword123!`
   - **Full Name**: `Owner Name`
3. Click **"Create Account"**
4. **Login** with the same credentials

✅ You should now see the main screen with an empty print queue.

---

## Step 1.9: Share Information

**Send this to your friend:**

```
Server IP: 192.168.1.100
Port: 5000
Full URL: http://192.168.1.100:5000

Make sure we're on the same WiFi network!
```

---

## ✅ Friend's Checklist

Before moving to the next part, verify:

- [ ] Backend server is running (PowerShell shows logs)
- [ ] Desktop app is open and logged in as owner
- [ ] Firewall allows port 5000
- [ ] Server responds to `curl http://localhost:5000/health`
- [ ] IP address shared with your friend

---

# 📱 PART 2: Your Setup (Mobile User)

Now it's your turn to set up the mobile app on your phone.

---

## Step 2.1: Get Friend's Server Details

Obtain from your friend:

- ✅ **IP Address**: e.g., `192.168.1.100`
- ✅ **Port**: `5000`
- ✅ **Full URL**: `http://192.168.1.100:5000`

---

## Step 2.2: Configure Mobile App API Endpoint

This is the **most important step**!

### Find the Configuration File

**File:** `mobile_app\lib\services\api_service.dart`

**Line:** 11

### Make the Change

**Open the file** in your code editor and find line 11:

```dart
final String baseUrl = 'http://localhost:5000';
```

**Change it to:**

```dart
final String baseUrl = 'http://192.168.1.100:5000';  // Use friend's IP
```

**⚠️ CRITICAL:**
- Replace `192.168.1.100` with your friend's **actual IP address**
- Use `http://` (not `https://`) for local network
- Keep `:5000` at the end
- **DO NOT use `localhost` or `127.0.0.1`** (these point to your own device!)

### Example

**Before:**
```dart
class ApiService {
  final String baseUrl = 'http://localhost:5000';
  // ...
```

**After:**
```dart
class ApiService {
  final String baseUrl = 'http://192.168.1.100:5000';  // Friend's computer
  // ...
```

**Save the file!**

---

## Step 2.3: Build the Mobile App APK

### Option A: Build APK and Install Manually

```bash
# Navigate to mobile app directory
cd mobile_app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release
```

**APK Location:** `build\app\outputs\flutter-apk\app-release.apk`

**Transfer to Phone:**
1. Connect phone via USB
2. Copy `app-release.apk` to phone's Downloads folder
3. On phone: Open Files app → Downloads → Tap APK
4. Enable "Install from Unknown Sources" if prompted
5. Install the app

### Option B: Run Directly on Connected Phone

```bash
# Enable USB debugging on Android phone:
# Settings → About Phone → Tap "Build Number" 7 times → Developer Options → USB Debugging

# Connect phone via USB

# Verify device detected
flutter devices

# Run on connected device
flutter run --release
```

---

## Step 2.4: Connect to Same Network

### For Same WiFi Network (Recommended)

1. Ensure your phone is connected to **same WiFi** as friend's computer
2. Both devices should be on same subnet (e.g., `192.168.1.x`)

### For Different Networks (Internet)

Your friend needs to use **ngrok**:

```bash
# Friend installs ngrok: https://ngrok.com/download

# Friend runs:
ngrok http 5000

# Friend shares the URL: https://abc123.ngrok.io
```

**You then configure:**
```dart
final String baseUrl = 'https://abc123.ngrok.io';  // No port needed
```

---

## Step 2.5: Test Connection from Your Phone

**Before opening the app**, test network connectivity:

1. Open **browser** on your phone
2. Navigate to: `http://192.168.1.100:5000/health`
3. You should see:
   ```json
   {
     "status": "OK",
     "timestamp": "2025-11-22T...",
     "environment": "production"
   }
   ```

✅ **If you see this, the connection is working!**

❌ **If connection fails:**
- Verify IP address is correct
- Check both on same WiFi
- Verify friend's firewall allows port 5000
- Try pinging from a network tool app

---

## Step 2.6: Create User Account

**On mobile app:**

1. Open the installed app
2. Click **"Register"** (first time) or **"Login"** (if account exists)
3. **Register** with:
   - **Email**: `user@example.com`
   - **Password**: `YourPassword123!`
   - **Full Name**: `Your Name`
4. **Login** with same credentials

✅ You should see the home screen

---

## ✅ Your Checklist

Before testing upload:

- [ ] Mobile app configured with friend's IP address
- [ ] APK built and installed on phone
- [ ] Phone connected to same network as friend
- [ ] Browser test successful (`http://FRIEND_IP:5000/health`)
- [ ] User account created and logged in

---

# 🧪 PART 3: Testing the Complete Flow

Now test the end-to-end workflow!

---

## Test 1: Network Connectivity

### From Your Phone Browser

Navigate to: `http://192.168.1.100:5000/health`

**✓ Expected:** JSON response with `"status": "OK"`

---

## Test 2: Upload File from Mobile App

### Your Actions:

1. **Open mobile app** on your phone
2. **Login** with your credentials
3. **Tap "Upload File"** or similar button
4. **Select a file** from your phone:
   - Document (PDF, Word, etc.)
   - Image (JPG, PNG, etc.)
   - Max size: 100MB
5. **Tap "Upload"**

### What Happens:

```
Mobile App:
  ├─ Shows "Encrypting file..."
  ├─ Shows "Uploading..."
  └─ Shows "✅ Upload successful! File ID: abc123"
```

### Behind the Scenes:

```
📱 Mobile App (Your Phone)
  │
  ├─► 1. User selects file
  ├─► 2. File encrypted with AES-256-GCM
  ├─► 3. Encrypted data sent to server
  │
  ▼
🖥️ Backend Server (Friend's Computer)
  │
  ├─► 4. Receives encrypted file
  ├─► 5. Stores in PostgreSQL database
  ├─► 6. Returns success + file ID
  │
  ▼
🖨️ Desktop App (Friend's Computer)
  │
  ├─► 7. Polls server for new files
  ├─► 8. Downloads encrypted file
  ├─► 9. Decrypts file
  └─► 10. Shows in print queue
```

---

## Test 3: Receive and Print (Friend's Side)

### Friend's Actions:

1. **Desktop app shows notification**: "New file received"
2. **File appears in print queue** with:
   - File name
   - Upload time
   - File size
   - Your email
   - Status: "Ready to print"
3. **Click the file** to preview (automatically decrypted)
4. **Click "Print"** to send to printer

### What Happens:

```
Desktop App:
  ┌─────────────────────────────┐
  │ 🔔 New File Received        │
  ├─────────────────────────────┤
  │ File: my_document.pdf       │
  │ Size: 2.5 MB                │
  │ From: user@example.com      │
  │ Upload: 2025-11-22 03:15    │
  │ Status: Ready to print      │
  │                             │
  │ [Preview] [Print] [Delete]  │
  └─────────────────────────────┘
```

---

## Test 4: Verify Complete Workflow

### Success Criteria:

- [x] You uploaded file from mobile app
- [x] Upload showed success message
- [x] Friend's desktop received notification
- [x] File appears in friend's print queue
- [x] Friend can preview file (decrypted)
- [x] Friend can print file
- [x] File printed successfully

✅ **Congratulations! Your system is working!**

---

# 🔧 Troubleshooting

## Problem: Mobile App Can't Connect to Server

### Symptoms:
- "Network Error"
- "Connection refused"
- "Timeout"

### Solutions:

```bash
# 1. Verify friend's server is running
# Friend runs:
docker-compose ps

# 2. Check firewall on friend's computer
Get-NetFirewallRule -DisplayName "Secure Print Backend"

# 3. Verify both on same network
# Check WiFi settings on both devices

# 4. Test from your phone browser
http://192.168.1.100:5000/health
```

### Common Causes:

| Cause | Solution |
|-------|----------|
| Wrong IP address | Verify with `ipconfig` |
| Different networks | Connect to same WiFi |
| Firewall blocking | Allow port 5000 |
| Server not running | Start with `docker-compose up` |
| Wrong configuration | Check `api_service.dart` line 11 |

---

## Problem: Upload Fails

### Symptoms:
- "Upload failed"
- "Authentication error"
- "401 Unauthorized"

### Solutions:

1. **Check authentication:**
   - Logout and login again
   - Verify credentials are correct
   - Check JWT token is valid

2. **Check file size:**
   - Max size: 100MB
   - Try smaller file first

3. **Check server logs:**
   ```powershell
   # Friend runs:
   docker-compose logs backend
   ```

---

## Problem: Desktop App Doesn't Show Files

### Symptoms:
- Upload succeeds but desktop doesn't show file
- Desktop app shows empty queue

### Solutions:

1. **Verify desktop app is logged in as owner:**
   - Check role is "owner" not regular user
   - Logout and login again

2. **Check database:**
   ```powershell
   # Friend runs:
   docker-compose exec postgres psql -U postgres -d secure_print
   SELECT * FROM files;
   ```

3. **Restart desktop app:**
   - Close and reopen
   - Check console for errors

---

## Problem: Can't Print File

### Symptoms:
- File shows in queue but print fails
- Decryption error

### Solutions:

1. **Verify encryption key matches:**
   - Same key used for encryption and decryption
   - Check `.env` file on server

2. **Check printer connection:**
   - Printer is connected and ready
   - Print test page from Windows

3. **Check file format:**
   - Supported formats: PDF, JPG, PNG, DOC
   - Try different file type

---

## Server Not Accessible Over Network

### Check Server Binding:

The server must listen on `0.0.0.0` not `127.0.0.1`.

**Verify in `docker-compose.yml`:**
```yaml
environment:
  HOST: 0.0.0.0  # Listen on all interfaces
```

**Or in `server.js`:**
```javascript
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`);
});
```

---

# 🌐 Network Setup Options

## Option 1: Same WiFi Network (Easiest)

**Requirements:**
- Both devices on same WiFi
- Same subnet (e.g., 192.168.1.x)

**Configuration:**
```dart
final String baseUrl = 'http://192.168.1.100:5000';  // Friend's local IP
```

**Pros:** Fast, secure, no additional setup
**Cons:** Only works on same network

---

## Option 2: Different Networks (Using ngrok)

**Friend's Setup:**

```bash
# Download ngrok: https://ngrok.com/download

# Start tunnel
ngrok http 5000
```

**Output:**
```
Forwarding: https://abc123.ngrok.io -> http://localhost:5000
```

**Your Configuration:**
```dart
final String baseUrl = 'https://abc123.ngrok.io';  // ngrok URL
```

**Pros:** Works over internet
**Cons:** Free tier has random URLs, session limits

---

## Option 3: Port Forwarding (Advanced)

**Friend's Router Setup:**
1. Login to router admin panel
2. Find "Port Forwarding" settings
3. Forward external port 5000 → friend's local IP:5000
4. Find public IP: https://whatismyipaddress.com

**Your Configuration:**
```dart
final String baseUrl = 'http://[PUBLIC_IP]:5000';
```

**Pros:** Permanent solution
**Cons:** Security risks, requires router access

---

# 🔒 Security Best Practices

## For Development/Testing:

- ✅ Files are encrypted before upload (AES-256-GCM)
- ✅ Use HTTP on trusted local network
- ✅ Strong passwords for all accounts
- ✅ Firewall configured properly

## For Production Deployment:

- ⚠️ **Use HTTPS** with valid SSL certificate
- ⚠️ Set up reverse proxy (nginx, Traefik)
- ⚠️ Use environment-specific secrets (not hardcoded)
- ⚠️ Enable rate limiting
- ⚠️ Regular security audits
- ⚠️ Use VPN for remote access

---

# 📝 Command Reference

## Friend's Commands (Server Owner)

```powershell
# Start backend
cd backend
docker-compose up

# Stop backend
docker-compose down

# View logs
docker-compose logs -f backend

# Restart backend
docker-compose restart backend

# Start desktop app
cd desktop_app
flutter run -d windows

# Build desktop app (production)
flutter build windows --release

# Check server status
curl http://localhost:5000/health

# Find IP address
ipconfig

# Check firewall rule
Get-NetFirewallRule -DisplayName "Secure Print Backend"
```

---

## Your Commands (Mobile User)

```bash
# Build mobile APK
cd mobile_app
flutter clean
flutter pub get
flutter build apk --release

# Run on connected phone
flutter run --release

# Check connected devices
flutter devices

# View logs
flutter logs

# Test connection
curl http://192.168.1.100:5000/health
```

---

# 🎓 Example Complete Session

## Friend's Terminal (3 windows):

**Terminal 1 - Backend:**
```powershell
PS C:\Prefinal\backend> docker-compose up
✓ Starting secure_print_db ... done
✓ Starting secure_print_backend ... done
Backend running on http://0.0.0.0:5000
```

**Terminal 2 - Check IP:**
```powershell
PS C:\> ipconfig
IPv4 Address: 192.168.1.100
```

**Terminal 3 - Desktop App:**
```powershell
PS C:\Prefinal\desktop_app> flutter run -d windows
✓ Desktop app running
✓ Logged in as owner@example.com
✓ Listening for new files...
```

---

## Your Actions:

**Step 1 - Configure:**
```dart
// Edit mobile_app/lib/services/api_service.dart
final String baseUrl = 'http://192.168.1.100:5000';
```

**Step 2 - Build:**
```bash
$ cd mobile_app
$ flutter build apk --release
✓ Building APK... done
✓ APK: build/app/outputs/flutter-apk/app-release.apk
```

**Step 3 - Test:**
```
Phone Browser: http://192.168.1.100:5000/health
Response: {"status":"OK",...}
```

**Step 4 - Upload:**
```
Mobile App:
1. Open app
2. Login: user@example.com
3. Tap "Upload File"
4. Select "report.pdf" (2.3 MB)
5. Tap "Upload"
6. See: "✅ Upload successful! File ID: xyz789"
```

---

## Friend Sees:

**Desktop App:**
```
🔔 Notification: "New file received"

Print Queue:
┌─────────────────────────────┐
│ File: report.pdf            │
│ Size: 2.3 MB                │
│ From: user@example.com      │
│ Time: 2025-11-22 03:15:23   │
│ Status: Ready to print      │
│                             │
│ [Preview] [Print] [Delete]  │
└─────────────────────────────┘

Action:
1. Click "Preview" → PDF opens (decrypted)
2. Click "Print" → Sent to HP Printer
3. ✓ Document printed!
```

---

# 📞 Support & Additional Resources

## Quick Help

| Question | Answer |
|----------|--------|
| Default server port? | 5000 |
| Max file size? | 100MB |
| Encryption algorithm? | AES-256-GCM |
| Database? | PostgreSQL 15 |
| Supported file types? | PDF, JPG, PNG, DOC, DOCX |

## API Endpoints

### Mobile App Uses:
- `POST /api/auth/register` - Create account
- `POST /api/auth/login` - Authenticate
- `POST /api/upload` - Upload encrypted file
- `GET /api/files` - List your files
- `GET /health` - Server status

### Desktop App Uses:
- `POST /api/auth/login` - Authenticate owner
- `GET /api/print/:fileId` - Get file for printing
- `POST /api/delete/:fileId` - Delete file
- `GET /api/files` - List all files

## Documentation Files

- **General Deployment**: `DEPLOYMENT.md`
- **Backend API**: `backend/API_GUIDE.md`
- **Backend README**: `backend/README.md`
- **Project Overview**: `00_START_HERE_FIRST.md`

---

# ✅ Final Checklist

## Before You Start

### Friend:
- [ ] Windows computer with admin access
- [ ] Docker Desktop installed
- [ ] Flutter SDK installed
- [ ] Project files extracted
- [ ] 2GB free disk space

### You:
- [ ] Android phone
- [ ] Flutter SDK installed on laptop
- [ ] Friend's IP address
- [ ] WiFi access

## During Setup

### Friend:
- [ ] Backend server started
- [ ] Server accessible (health check works)
- [ ] Firewall configured
- [ ] Desktop app running
- [ ] Logged in as owner
- [ ] IP address shared

### You:
- [ ] `api_service.dart` updated with friend's IP
- [ ] Mobile APK built
- [ ] APK installed on phone
- [ ] Same network as friend
- [ ] Connection tested
- [ ] User account created

## Testing

- [ ] Mobile app connects to server
- [ ] File upload succeeds
- [ ] Desktop receives file
- [ ] File can be decrypted
- [ ] File can be printed
- [ ] Complete workflow works

---

# 🎉 Success!

When everything works, you have a complete **end-to-end encrypted** file printing system:

1. ✅ You upload files from your phone (encrypted)
2. ✅ Files stored securely on friend's server
3. ✅ Friend receives and decrypts files
4. ✅ Friend can print files

**Your Secure File Print System is now fully operational!** 🚀🖨️

---

## Need More Help?

**Check Logs:**
- Backend: `docker-compose logs backend`
- Mobile: `flutter logs`
- Desktop: Console output

**Restart Everything:**
```powershell
# Friend stops:
docker-compose down

# Friend starts:
docker-compose up
```

**Still stuck?**
Review the troubleshooting section above or check the detailed API documentation in `backend/API_GUIDE.md`.

---

**Last Updated:** 2025-11-22
**Version:** 1.0.0
