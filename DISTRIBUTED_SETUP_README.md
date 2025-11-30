# 🚀 Quick Start: Distributed Deployment
## Upload Files from Your Phone → Friend's Server → Friend's Printer

---

## 📊 System Architecture

![Distributed Deployment](./assets/distributed_deployment_diagram.png)

> **Note:** If the image doesn't display, the diagram shows the complete flow: Mobile App → Backend Server → Desktop App → Printer

---

## 🎯 Setup Overview

This guide helps you set up a **distributed deployment** where:
- **You** run the mobile app on your phone
- **Your Friend** runs the backend server and desktop app
- Files are encrypted on your phone, sent to server, and print-ready on friend's desktop

---

## 📚 Documentation Index

| Document | Purpose | Who Needs It |
|----------|---------|-------------|
| **[QUICK_SETUP_CHECKLIST.md](QUICK_SETUP_CHECKLIST.md)** | Fast reference checklist | Both |
| **[DISTRIBUTED_DEPLOYMENT_GUIDE.md](DISTRIBUTED_DEPLOYMENT_GUIDE.md)** | Complete step-by-step guide | Both |
| **[MOBILE_APP_CONFIG_GUIDE.md](MOBILE_APP_CONFIG_GUIDE.md)** | Mobile app configuration | You |
| **[DEPLOYMENT.md](DEPLOYMENT.md)** | General deployment guide | Friend |

---

## ⚡ Quick Start (15 Minutes)

### Friend's Tasks (Server Owner):

1. **Start Backend Server**
   ```bash
   cd backend
   docker-compose up
   ```

2. **Get IP Address**
   ```cmd
   ipconfig
   # Note the IPv4 Address (e.g., 192.168.1.100)
   ```

3. **Allow Firewall**
   ```powershell
   New-NetFirewallRule -DisplayName "Secure Print" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
   ```

4. **Build & Run Desktop App**
   ```bash
   cd desktop_app
   flutter run -d windows
   ```

5. **Share IP Address with You**
   - Send: `192.168.1.100`

---

### Your Tasks (Mobile User):

1. **Update API Configuration**
   
   **File:** [`mobile_app/lib/services/api_service.dart`](mobile_app/lib/services/api_service.dart)
   
   **Find this line:** (Search for `final String baseUrl =` or just `baseUrl`)
   
   **Change from:**
   ```dart
   final String baseUrl = 'http://localhost:5000';
   ```
   
   **Change to:**
   ```dart
   final String baseUrl = 'http://192.168.1.100:5000';  // Friend's IP
   ```

2. **Build Mobile App**
   ```bash
   cd mobile_app
   flutter build apk --release
   ```

3. **Install APK on Phone**
   - Copy `build/app/outputs/flutter-apk/app-release.apk` to phone
   - Install the APK

4. **Test Connection**
   - Open browser on phone
   - Go to: `http://192.168.1.100:5000/health`
   - Should see JSON response

5. **Use the App**
   - Open mobile app
   - Register/Login
   - Upload file
   - ✅ Done!

---

## 🔄 Complete Workflow

### Step 1: You Upload File

```
📱 Mobile App (Your Phone)
  │
  ├─ Select file from phone storage
  ├─ File encrypted with AES-256-GCM
  ├─ Upload encrypted file to server
  └─ Receive success confirmation
```

### Step 2: Server Stores File

```
🖥️ Backend Server (Friend's Computer)
  │
  ├─ Receive encrypted file
  ├─ Store in PostgreSQL database
  ├─ Save encrypted file data
  └─ Notify desktop app
```

### Step 3: Friend Receives File

```
🖨️ Desktop App (Friend's Computer)
  │
  ├─ Detect new file in queue
  ├─ Download encrypted file
  ├─ Decrypt file with encryption key
  ├─ Display print-ready file
  └─ Send to printer
```

---

## 🌐 Network Setup

### Same WiFi Network (Recommended for Testing)

```
Your Phone (192.168.1.50)
    │
    │ WiFi: "HomeNetwork"
    │
    ├──────────────────┐
    │                  │
Your Laptop      Friend's Computer (192.168.1.100)
                      └─ Backend Server (Port 5000)
                      └─ Desktop App
```

**Requirements:**
- Both on same WiFi network
- Same subnet (192.168.1.x)
- Firewall allows port 5000

### Different Networks (Using ngrok)

```
Your Phone (Mobile Data/Different WiFi)
    │
    │ Internet
    │
    ▼
ngrok Tunnel (https://abc123.ngrok.io)
    │
    ▼
Friend's Computer
    └─ Backend Server (localhost:5000)
```

**Setup:**
```bash
# Friend runs:
ngrok http 5000

# You configure:
baseUrl = 'https://abc123.ngrok.io'
```

---

## ✅ Pre-Deployment Checklist

### Friend (Server Owner):
- [ ] Docker installed and running
- [ ] Flutter SDK installed
- [ ] Port 5000 available (not used by other apps)
- [ ] Firewall configured to allow port 5000
- [ ] Static IP or dynamic DNS configured (optional)

### You (Mobile User):
- [ ] Flutter SDK installed (for building)
- [ ] Android phone with USB debugging enabled OR APK transfer method
- [ ] Same WiFi network as friend OR ngrok URL
- [ ] Friend's IP address obtained

---

## 🧪 Testing Procedure

### Test 1: Friend's Server

```bash
# On friend's computer
curl http://localhost:5000/health
```

**✓ Expected:**
```json
{"status":"OK","timestamp":"...","environment":"production"}
```

### Test 2: Network Connectivity

```bash
# From your phone browser
http://192.168.1.100:5000/health
```

**✓ Expected:** Same JSON response

### Test 3: Complete Upload Flow

1. **You**: Open mobile app → Upload `test.pdf`
2. **Friend**: Desktop app shows notification → File appears in queue
3. **Friend**: Click file → Preview shows `test.pdf` (decrypted)
4. **Friend**: Click Print → File sent to printer
5. **✓ Success!**

---

## 🔧 Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Connection refused | Firewall blocking | Allow port 5000 in firewall |
| Network error | Wrong IP address | Verify friend's IP with `ipconfig` |
| Timeout | Different networks | Use ngrok or VPN |
| Upload fails | Not authenticated | Login again, check JWT token |
| Desktop doesn't receive | Wrong user role | Login as owner on desktop app |

---

## 🔒 Security Notes

- ✅ Files are **encrypted** before leaving your phone
- ✅ Encryption uses **AES-256-GCM** algorithm
- ✅ Server stores **only encrypted data**
- ✅ Friend's desktop **decrypts** for printing
- ⚠️ Use **HTTPS** for production (not HTTP)
- ⚠️ Use **strong passwords** for all accounts

### Production HTTPS Setup

For production deployments, **always use HTTPS** to protect data in transit:

#### Option 1: Using Let's Encrypt with Nginx (Recommended)

**1. Install Certbot and Nginx:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx nginx

# CentOS/RHEL
sudo yum install certbot python-certbot-nginx nginx
```

**2. Obtain SSL Certificate:**
```bash
# Replace yourdomain.com with your actual domain
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

**3. Configure Nginx as Reverse Proxy:**

Create `/etc/nginx/sites-available/secureprint`:
```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    # SSL certificates (managed by certbot)
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Proxy settings
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**4. Enable and Restart Nginx:**
```bash
sudo ln -s /etc/nginx/sites-available/secureprint /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

**5. Set up Auto-Renewal:**
```bash
# Test renewal
sudo certbot renew --dry-run

# Certbot automatically sets up a cron job/systemd timer
sudo systemctl status certbot.timer
```

**6. Configure Backend for Proxy:**

Update `backend/.env`:
```env
# Trust proxy headers
TRUST_PROXY=true
CORS_ORIGIN=https://yourdomain.com
```

**Resources:**
- [Let's Encrypt Documentation](https://letsencrypt.org/getting-started/)
- [Nginx Reverse Proxy Guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [Certbot Instructions](https://certbot.eff.org/instructions)

---

#### Option 2: Using Caddy (Automatic HTTPS)

**1. Install Caddy:**
```bash
# See: https://caddyserver.com/docs/install
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

**2. Configure Caddyfile:**

Create `/etc/caddy/Caddyfile`:
```
yourdomain.com {
    reverse_proxy localhost:5000
    encode gzip
    
    # Optional: Access logs
    log {
        output file /var/log/caddy/access.log
    }
}
```

**3. Restart Caddy:**
```bash
sudo systemctl restart caddy
```

Caddy **automatically** obtains and renews SSL certificates!

**Resources:**
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Caddy Reverse Proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy)

---

#### Option 3: Using ngrok for Testing with TLS

For quick testing with HTTPS (not for production):

**1. Install ngrok:**
```bash
# Download from https://ngrok.com/download
# Or via package manager
choco install ngrok          # Windows
brew install ngrok/ngrok/ngrok  # macOS
```

**2. Start HTTPS tunnel:**
```bash
# Automatically provides HTTPS
ngrok http 5000
```

**Output:**
```
Forwarding  https://abc123.ngrok.io -> http://localhost:5000
```

**3. Update mobile app:**
```dart
// mobile_app/lib/services/api_service.dart
final String baseUrl = 'https://abc123.ngrok.io';  // Uses HTTPS!
```

**4. Update backend CORS:**
```env
# backend/.env
CORS_ORIGIN=https://abc123.ngrok.io
```

**Note:** ngrok free tier provides random URLs. For persistent URLs, use paid plan.

---

#### Application HTTPS Configuration

If running backend directly with HTTPS (without reverse proxy):

**backend/.env:**
```env
NODE_ENV=production
USE_HTTPS=true
SSL_KEY_PATH=/path/to/privatekey.pem
SSL_CERT_PATH=/path/to/certificate.pem
HTTPS_PORT=443
```

**Note:** Running on port 443 requires root/admin privileges. Use reverse proxy instead (recommended).

---

#### HTTPS Checklist

- [ ] SSL certificates obtained (Let's Encrypt/Certbot)
- [ ] Reverse proxy configured (Nginx/Caddy)
- [ ] Auto-renewal enabled for certificates
- [ ] Backend trusts X-Forwarded-* headers
- [ ] CORS_ORIGIN updated to HTTPS URLs
- [ ] HTTP redirects to HTTPS (301)
- [ ] Mobile app baseUrl uses `https://`
- [ ] Test certificate validity: [SSL Labs](https://www.ssllabs.com/ssltest/)

---

## 📱 Mobile App Endpoints

The mobile app uses these API endpoints:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/auth/register` | POST | Create new user account |
| `/api/auth/login` | POST | Authenticate user |
| `/api/upload` | POST | Upload encrypted file |
| `/api/files` | GET | List uploaded files |
| `/health` | GET | Check server status |

---

## 🖥️ Desktop App Endpoints

The desktop app uses these API endpoints:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/auth/login` | POST | Authenticate owner |
| `/api/print/:fileId` | GET | Download file for printing |
| `/api/delete/:fileId` | POST | Delete printed file |
| `/api/files` | GET | List all files in queue |

---

## 🎓 Example Complete Session

### Friend's Terminal:

```bash
# Terminal 1: Start backend
C:\Prefinal\backend> docker-compose up
✓ Postgres started
✓ Backend started on port 5000

# Terminal 2: Start desktop app
C:\Prefinal\desktop_app> flutter run -d windows
✓ Desktop app running
✓ Logged in as owner
✓ Listening for new files
```

### Your Actions:

```
1. Open mobile app
2. Login: user@example.com / password123
3. Tap "Upload File"
4. Select "Invoice.pdf" (2.5 MB)
5. App shows: "Encrypting..."
6. App shows: "Uploading..."
7. App shows: "✓ Upload successful!"
8. File ID: abc123xyz
```

### Friend Sees:

```
Desktop App:
  ┌─────────────────────────────┐
  │ 🔔 New File Received        │
  ├─────────────────────────────┤
  │ File: Invoice.pdf           │
  │ Size: 2.5 MB                │
  │ From: user@example.com      │
  │ Status: Ready to print      │
  │                             │
  │ [Preview] [Print] [Delete]  │
  └─────────────────────────────┘
```

---

## 📞 Support & Documentation

- **Full Deployment Guide**: [DISTRIBUTED_DEPLOYMENT_GUIDE.md](DISTRIBUTED_DEPLOYMENT_GUIDE.md)
- **Quick Checklist**: [QUICK_SETUP_CHECKLIST.md](QUICK_SETUP_CHECKLIST.md)
- **Mobile Configuration**: [MOBILE_APP_CONFIG_GUIDE.md](MOBILE_APP_CONFIG_GUIDE.md)
- **Backend API Docs**: [backend/API_GUIDE.md](backend/API_GUIDE.md)
- **General Deployment**: [DEPLOYMENT.md](DEPLOYMENT.md)

---

## 🏁 Ready to Start?

1. **Friend**: Follow checklist in [DISTRIBUTED_DEPLOYMENT_GUIDE.md](DISTRIBUTED_DEPLOYMENT_GUIDE.md) (Part 1)
2. **You**: Follow checklist in [DISTRIBUTED_DEPLOYMENT_GUIDE.md](DISTRIBUTED_DEPLOYMENT_GUIDE.md) (Part 2)
3. **Both**: Test the complete flow (Part 3)

**Estimated Setup Time:** 15-20 minutes

---

**Let's get printing! 🖨️✨**
