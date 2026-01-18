# SafeCopy - Owner's Comprehensive Manual (Desktop Application)

**Version:** 1.0  
**Role:** Administrator / Host  
**System:** Windows Desktop Environment

---

## 📖 Table of Contents
1. [System Architecture Overview](#1-system-architecture-overview)
2. [Prerequisites & Installation](#2-prerequisites--installation)
3. [Deep Dive: Authentication & Security](#3-deep-dive-authentication--security)
4. [Dashboard Walkthrough](#4-dashboard-walkthrough)
5. [Network Configuration (Critical)](#5-network-configuration-critical)
6. [Advanced Troubleshooting](#6-advanced-troubleshooting)

---

## 1. System Architecture Overview
Understanding how SafeCopy works will help you manage it effectively.

SafeCopy operates on a **Client-Server model**:
- **The Server (You):** Your desktop computer runs the "Backend" (Flask) and the "Desktop App" (GUI). It acts as the vault where all files are physically stored.
- **The Client (Customer):** The mobile Android app sends files to your desktop over the network.

**Data Flow:**
1.  Mobile App initiates a connection -> Handshake with Desktop.
2.  User selects a file -> File interacts with the Encryption Layer.
3.  File is streamed over Wi-Fi -> Desktop receives and decrypts.
4.  File is saved to `C:\Users\...\SafeCopy\uploads`.

**Privacy Note:** Unlike cloud services (like Google Drive), data typically stays on your local network (unless you configure remote port forwarding). **You own the data/hardware.**

---

## 2. Prerequisites & Installation

### Hardware Requirements
- **CPU:** Standard Dual-core processor or better.
- **RAM:** 4GB minimum (8GB recommended for handling large file transfers).
- **Storage:** Sufficient SSD/HDD space for the files you intend to store.

### Software Dependencies
The provided installer/script (`run_desktop.bat`) handles most dependencies, but ensure:
- **Python 3.10+** is installed on the system.
- **Visual C++ Redistributables** (often needed for crypto libraries).

### First Run
1.  **Launch:** Execute `run_desktop.bat`. A command terminal may appear—**do not close it**; this is the backend server process.
2.  **Firewall Prompt:** Windows may ask to allow Python to communicate on private networks. Click **"Allow Access"**. If you skip this, mobile apps typically cannot find your desktop.

---

## 3. Deep Dive: Authentication & Security

### Why Google Login?
SafeCopy uses OAuth2 (Google Login) to verify identity without storing passwords on your machine.
- **Client ID/Secret:** These are "keys" that tell Google, "This request is coming from the official SafeCopy app."
- **Token Exchange:** When you log in, Google sends a secure token. This token is used to validate your session.

### File Security
- Files are transmitted using standard HTTP protocols (recommend upgrading to HTTPS for public networks).
- Files are stored in their native format in the `uploads` folder unless compression is enabled.

---

## 4. Dashboard Walkthrough

The Desktop Interface is your Command Center.

### A. Status Indicators
- **🟢 Server Online:** Backend is reachable. Mobile apps can connect.
- **🔴 Server Offline:** The background process stopped. Restart the application.
- **🟡 AUTH Required:** You must complete the Google Sign-in to unlock features.

### B. The Live Log Console
This black text box tells you the story of your server.
- `[INFO] New connection from 192.168.1.5`: A phone just opened the app.
- `[UPLOAD] starting file transfer...`: Data is moving.
- `[ERROR] Connection refused`: Usually a firewall issue.

### C. QR Code (If applicable)
Some versions display a QR code containing your Server IP. Mobile users can scan this to auto-configure their settings.

---

## 5. Network Configuration (Critical)

This is the #1 reason for "It's not working" reports.

### The "Same Network" Rule
For the easiest setup, your Desktop and the Phone **MUST be on the same Wi-Fi network**.
- **Desktop IP:** The dashboard displays an IP like `192.168.x.x`.
- **Mobile Config:** The user must enter this *exact* IP in their app settings.

### Static IP (Recommended)
Routers often change your computer's IP address when you reboot.
- **Pro Tip:** Set a "Static IP" for your desktop in your router settings. This ensures your customers/family don't have to keep updating the settings on their phones.

---

## 6. Advanced Troubleshooting

### Scenario: "The App says 'Server Unreachable'"
1.  **Ping Test:** On the desktop, open Command Prompt (`cmd`) and type `ipconfig`. Confirm your IPv4 address matches what is in the app.
2.  **Firewall Check:**
    -  Press `Win` key, type "Firewall & network protection".
    -  Click "Allow an app through firewall".
    -  Look for `python.exe` or `SafeCopy`. Ensure both "Private" and "Public" are checked.

### Scenario: "Google Login fails with 400 Error"
- This usually means the **Redirect URI** is mismatched.
- Ensure your `.env` file lists `http://127.0.0.1:5000/callback` (or configured port) as the authorized redirect URI.
- Confirm your Google Cloud Console settings match this URI exactly.

### Scenario: "Upload stops halfway"
- **Disk Space:** Check if your C: drive is full.
- **Sleep Mode:** ensuring your computer didn't go to sleep during the transfer. Set "Sleep" to "Never" when running a server.

---
**Need Support?**
Check the `logs/` directory in the installation folder for `app.log`. This file contains the raw technical data needed for developers to diagnose bugs.
