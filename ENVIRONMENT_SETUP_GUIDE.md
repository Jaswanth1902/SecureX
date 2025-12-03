# Desktop App Environment Setup Guide

## Overview
The SafeCopy Desktop Application is a Windows-based owner dashboard that connects to a Flask backend server running on `localhost:5000`.

## Prerequisites

### Backend Requirements
- Python 3.7+ (tested with Python 3.13)
- Flask and dependencies (see backend_flask_small/requirements.txt)
- SQLite (included with Python)
- Port 5000 must be available

### Desktop App Requirements  
- Flutter 3.10+
- Windows SDK for desktop development
- Dependencies: provider, http, cryptography, printing, pdf, path_provider, window_manager, encrypt, pointycastle

## Environment Configuration

### Backend Server (.env file)

Create file: `backend_flask_small/.env`

```ini
PORT=5000
HOST=0.0.0.0
NODE_ENV=development
DB_FILE=database.sqlite
JWT_SECRET=default_secret_key_must_be_long_and_strong_for_production_use_only
MAX_FILE_SIZE=100mb
UPLOAD_DIR=./uploads
DEBUG=True
```

**Key Variables:**
- `PORT`: Must be 5000 (desktop app expects this)
- `NODE_ENV`: Set to 'development' for debug output
- `JWT_SECRET`: Used for token signing (change for production)
- `DB_FILE`: SQLite database file path

### Desktop App Configuration (Hardcoded)

The desktop app has hardcoded backend URLs in service files:

**api_service.dart:**
```dart
final String baseUrl = 'http://localhost:5000';
```

**auth_service.dart:**
```dart
final String baseUrl = 'http://localhost:5000';
```

**notification_service.dart:**
```dart
final String baseUrl = 'http://localhost:5000';
```

#### To Change Backend URL:
Edit the following files if you need to use a different server:
1. `lib/services/api_service.dart` - Line 6
2. `lib/services/auth_service.dart` - Line 8
3. `lib/services/notification_service.dart` - Line 6

## Running the Application

### Step 1: Start the Backend Server

```powershell
# Navigate to backend directory
cd C:\Users\psabh\SecureX\backend_flask_small

# Run with Python directly
& "C:\Users\psabh\AppData\Local\Programs\Python\Python313\python.exe" app.py
```

Expected output:
```
Using existing SQLite database at: c:\Users\psabh\SecureX\backend_flask_small\
Server running on http://0.0.0.0:5000
 * Running on http://127.0.0.1:5000
 * Running on http://10.238.102.190:5000
```

### Step 2: Verify Backend is Running

```powershell
# Check if port 5000 is listening
netstat -ano | findstr :5000

# Or test with curl
curl http://localhost:5000/health
```

Expected response:
```json
{"status": "OK", "environment": "development"}
```

### Step 3: Run the Desktop App

```powershell
# Navigate to desktop_app directory
cd C:\Users\psabh\SecureX\desktop_app

# Run in debug mode
flutter run -d windows

# Or build for release
flutter build windows --release
```

## Database Setup

The backend automatically uses SQLite with file `database.sqlite`.

### Manage Database

```powershell
# Check database status
python check_db.py

# Reset and register new owner
python reset_and_register.py

# List owners
python list_owners.py

# Dump database
python dump_db.py
```

### Test Users

Pre-configured test accounts:
- **Owner Email**: Check `owner_account_info.txt`
- **Test User 001**: See `test_owner_001_info.txt`

## Troubleshooting

### Error: "Connection refused on port 5000"
- **Solution**: Start the backend server first (Step 1)
- Verify: `netstat -ano | findstr :5000`

### Error: "ModuleNotFoundError: No module named 'flask'"
- **Solution**: Install dependencies
```powershell
cd backend_flask_small
& "C:\Users\psabh\AppData\Local\Programs\Python\Python313\python.exe" -m pip install -r requirements.txt
```

### Error: "Port 5000 already in use"
- **Solution**: Kill existing process or change PORT in .env
```powershell
# Find process using port 5000
netstat -ano | findstr :5000

# Kill process (replace PID with actual)
taskkill /PID <PID> /F

# Or change port in .env and backend config
```

### Desktop App won't connect
- Ensure backend is running: `curl http://localhost:5000/health`
- Check firewall allows localhost connections
- Verify no VPN blocking localhost
- Check Windows firewall settings for Python

## Network Access

The backend listens on:
- `http://127.0.0.1:5000` - localhost only
- `http://10.238.102.190:5000` - network interface (your machine IP)
- `http://0.0.0.0:5000` - binds to all interfaces

The desktop app always connects to `http://localhost:5000`.

## Production Considerations

For production deployment:
1. Change `JWT_SECRET` to a strong random value
2. Set `NODE_ENV=production`
3. Use a proper WSGI server instead of Flask dev server (gunicorn, waitress)
4. Configure CORS appropriately for your domain
5. Use HTTPS instead of HTTP
6. Store sensitive configuration in environment variables, not .env files
7. Implement proper database backups

## Architecture Diagram

```
┌─────────────────────────────────────┐
│  Desktop App (Windows/Flutter)      │
│  ├─ AuthService                     │
│  ├─ ApiService                      │
│  ├─ NotificationService             │
│  ├─ EncryptionService               │
│  └─ KeyService                      │
└────────────────┬────────────────────┘
                 │ HTTP
                 │ (port 5000)
                 ▼
┌─────────────────────────────────────┐
│  Backend Server (Flask/Python)      │
│  ├─ /api/owners/* (auth)            │
│  ├─ /api/files (file mgmt)          │
│  ├─ /api/print/* (file retrieval)   │
│  ├─ /api/events/stream (SSE)        │
│  └─ Database (SQLite)               │
└─────────────────────────────────────┘
```

## Files Overview

### Backend (`backend_flask_small/`)
- `app.py` - Main Flask application
- `.env` - Environment configuration (created)
- `requirements.txt` - Python dependencies
- `database.sqlite` - SQLite database
- `routes/` - API endpoints
- `*_account_info.txt` - Credential files for test users

### Desktop App (`desktop_app/`)
- `lib/main.dart` - Application entry point
- `lib/services/` - Service layer (api, auth, encryption, etc.)
- `lib/screens/` - UI screens
- `lib/models/` - Data models
- `pubspec.yaml` - Flutter dependencies
- `pubspec.lock` - Locked dependency versions

## Support

For issues:
1. Check logs: Backend logs to console, app logs via Flutter DevTools
2. Verify .env configuration
3. Ensure backend and app use compatible API versions
4. Check Windows Firewall settings
5. Verify Python installation and packages

