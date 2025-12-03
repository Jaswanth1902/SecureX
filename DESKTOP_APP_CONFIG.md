# Desktop App Configuration
# =========================
# This file documents the configuration for the SafeCopy Desktop Application

## Backend Server Configuration
- Backend URL: http://localhost:5000
- Port: 5000
- Host: 0.0.0.0 (listens on all interfaces)
- Environment: development

## API Endpoints Used
The desktop app uses the following endpoints:

1. **Authentication**
   - POST /api/owners/login - User login
   - POST /api/owners/register - User registration

2. **File Management**
   - GET /api/files - List all files
   - GET /api/print/{fileId} - Get file for printing
   - POST /api/delete/{fileId} - Delete a file

3. **Notifications**
   - GET /api/events/stream - Server-Sent Events (SSE) for real-time notifications

## Database
- Type: SQLite
- File: database.sqlite (located in backend_flask_small directory)
- Automatically created on first run

## Service Dependencies (Dart/Flutter)

### AuthService (lib/services/auth_service.dart)
- Handles user login and registration
- Manages access tokens
- Uses: http package

### ApiService (lib/services/api_service.dart)
- Handles file listing, retrieval, and deletion
- Uses: http package

### NotificationService (lib/services/notification_service.dart)
- Maintains connection to SSE stream
- Broadcasts real-time events
- Uses: http package, StreamController

### EncryptionService (lib/services/encryption_service.dart)
- Handles file decryption with AES-256-GCM
- Uses: cryptography, encrypt, pointycastle packages

### KeyService (lib/services/key_service.dart)
- Manages RSA key pair generation and storage
- Handles public key PEM export
- Uses: pointycastle package

## Important: Connection Flow

1. Backend server must be running on port 5000 before launching the desktop app
2. Desktop app authenticates with backend using /api/owners/login
3. Upon successful login, app receives access token
4. All subsequent requests include the access token in Authorization header
5. Real-time notifications are received via /api/events/stream

## Development Setup Checklist

- [ ] Backend server running: `python app.py` on port 5000
- [ ] SQLite database initialized (database.sqlite)
- [ ] All required Python packages installed (see requirements.txt)
- [ ] Desktop app built: `flutter build windows` or running in debug mode
- [ ] Ensure firewall allows localhost:5000 connections
