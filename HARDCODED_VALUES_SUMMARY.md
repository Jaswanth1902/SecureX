# SafeCopy - Hardcoded Values Summary

## Mobile App IP Configuration

### Current Configuration
**Location:** `mobile_app/lib/services/api_service.dart` (Line 11)

```dart
final String baseUrl = 'http://10.83.12.71:5000'; // Updated to match WiFi IP from ipconfig
```

### ✅ Fixed Issues
1. **print_screen.dart** - Line 61: Changed to use `apiService.baseUrl`
2. **print_screen.dart** - Line 113: Changed to use `apiService.baseUrl`

All mobile app HTTP requests now correctly use the centralized `apiService.baseUrl` configuration.

---

## How to Update Server IP

To connect the mobile app to a different server IP address:

### Option 1: Edit the Source Code (Current Method)
1. Open `mobile_app/lib/services/api_service.dart`
2. Update line 11:
   ```dart
   final String baseUrl = 'http://YOUR_IP_HERE:5000';
   ```
3. Rebuild the app: `flutter build apk`

### Option 2: Use Environment File (Recommended for Production)
Create a configuration file that can be changed without rebuilding:

1. Create `mobile_app/lib/config/api_config.dart`:
   ```dart
   class ApiConfig {
     static const String baseUrl = String.fromEnvironment(
       'API_BASE_URL',
       defaultValue: 'http://10.83.12.71:5000',
     );
   }
   ```

2. Update `api_service.dart`:
   ```dart
   import '../config/api_config.dart';
   
   class ApiService {
     final String baseUrl = ApiConfig.baseUrl;
   ```

3. Build with custom URL:
   ```bash
   flutter build apk --dart-define=API_BASE_URL=http://192.168.1.100:5000
   ```

---

## Backend Test User ID

### Current Issue
**Location:** `backend_flask/routes/files.py` (Line 40)

```python
user_id = 'test-user-id-for-development' # Hardcoded for testing
```

### Status
This is commented as "Disabled for testing" because token authentication is currently disabled on the upload endpoint (Line 12):
```python
@files_bp.route('/upload', methods=['POST'])
# @token_required  <-- Disabled for testing
def upload_file():
```

### Recommendation
**For Production:**
1. Uncomment `@token_required` decorator
2. Remove hardcoded user_id
3. Use the authenticated user ID from token:
   ```python
   user_id = g.user['sub']
   ```

**For Testing:**
- Keep current setup but add environment variable:
  ```python
  user_id = os.getenv('TEST_USER_ID', 'test-user-id-for-development')
  ```

---

## Desktop App Configuration

**Location:** `desktop_app/lib/services/api_service.dart` (Line 6)
```dart
final String baseUrl = 'http://localhost:5000';
```

This is correct for a desktop app running on the same machine as the server.

---

## Quick Reference - Current Server IPs

| Component | IP Address | Port | Configurable? |
|-----------|------------|------|---------------|
| Mobile App API | `10.83.12.71` | 5000 | Yes - Edit `api_service.dart` |
| Desktop App API | `localhost` | 5000 | Yes - Edit `api_service.dart` |
| Backend Server | `0.0.0.0` (all interfaces) | 5000 | Yes - Set `PORT` env variable |

---

## Testing with Different IPs

### Find Your Current IP:
```bash
# Windows
ipconfig

# Linux/Mac
ifconfig
```

Look for your WiFi adapter's IPv4 address (e.g., `192.168.1.x` or `10.x.x.x`)

### Update Mobile App:
1. Edit `mobile_app/lib/services/api_service.dart`
2. Change `baseUrl` to your IP
3. Rebuild: `flutter build apk`
4. Install: `flutter install --device-id=YOUR_DEVICE_ID`

### Verify Connection:
- Mobile app can access: `http://YOUR_IP:5000/health`
- Backend should show incoming requests in console
