# Environment Configuration Troubleshooting Guide

## Common Issues & Solutions

### Issue 1: "Connection refused on port 5000"

**Error Message:**
```
ClientException with SocketException: The remote computer refused the network connection.
```

**Causes:**
1. Backend server not running
2. Port 5000 in use by another process
3. Firewall blocking localhost

**Solutions:**

**Check if backend is running:**
```powershell
netstat -ano | findstr :5000
```
If nothing appears, backend is not running.

**Start backend:**
```powershell
cd backend_flask_small
& "C:\Users\psabh\AppData\Local\Programs\Python\Python313\python.exe" app.py
```

**If port already in use:**
```powershell
# Find process using port 5000
netstat -ano | findstr :5000

# Kill the process (replace PID)
taskkill /PID <PID> /F

# Or change PORT in .env to 5001
```

**Check firewall:**
- Windows Defender Firewall → Allow an app through firewall
- Ensure Python is listed and enabled
- Allow localhost connections

---

### Issue 2: "ModuleNotFoundError: No module named 'flask'"

**Error Message:**
```
ModuleNotFoundError: No module named 'flask'
```

**Cause:** Python dependencies not installed

**Solution:**
```powershell
cd backend_flask_small

# Install all requirements
& "C:\Users\psabh\AppData\Local\Programs\Python\Python313\python.exe" -m pip install -r requirements.txt
```

**Verify installation:**
```powershell
& "C:\Users\psabh\AppData\Local\Programs\Python\Python313\python.exe" -m pip list | findstr flask
```

---

### Issue 3: "Python: command not found"

**Error Message:**
```
The term 'python' is not recognized as a cmdlet, function, script file, or operable program.
```

**Cause:** Python not in PATH

**Solution 1 - Use full path (Recommended):**
```powershell
& "C:\Users\psabh\AppData\Local\Programs\Python\Python313\python.exe" app.py
```

**Solution 2 - Add Python to PATH:**
1. Settings → System → Environment Variables
2. Click "Environment Variables" button
3. Add: `C:\Users\psabh\AppData\Local\Programs\Python\Python313` to Path
4. Restart PowerShell
5. Test: `python --version`

**Solution 3 - Create Python alias (PowerShell):**
```powershell
# Add to PowerShell profile
Add-Content $PROFILE 'Set-Alias python "C:\Users\psabh\AppData\Local\Programs\Python\Python313\python.exe"'

# Reload profile
. $PROFILE
```

---

### Issue 4: "Unexpected token in JSON at position 0"

**Possible Cause:** Backend returned HTML error page instead of JSON

**Check what backend returned:**
```powershell
curl -v http://localhost:5000/api/owners/login
```

**Solutions:**
1. Verify backend is fully started (wait 2-3 seconds)
2. Check .env file exists and is valid
3. Check database.sqlite exists
4. Review backend console for errors

---

### Issue 5: "CORS error" or "Access-Control-Allow-Origin missing"

**Browser Console Error:**
```
Access to XMLHttpRequest at 'http://localhost:5000/...' from origin 'http://...' 
has been blocked by CORS policy
```

**Check .env CORS settings:**
```ini
CORS_ORIGIN=http://localhost:3000,http://127.0.0.1:5000
```

**Solution:**
1. Verify CORS_ORIGIN includes your app URL
2. Update .env if needed
3. Restart backend: `Ctrl+C` then rerun app.py

---

### Issue 6: "database.sqlite: file not found"

**Cause:** Database file doesn't exist or wrong path

**Check database location:**
```powershell
cd backend_flask_small
ls -la database.sqlite
```

**Solutions:**

**If file doesn't exist:**
```powershell
# Backend will auto-create on first run
# Just run app.py:
& "C:\Users\psabh\AppData\Local\Programs\Python\Python313\python.exe" app.py

# Wait for message: "Using existing SQLite database at:"
```

**If path is wrong (wrong directory):**
```powershell
# Verify you're in backend_flask_small directory
cd backend_flask_small
pwd  # Should show: C:\Users\psabh\SecureX\backend_flask_small
```

---

### Issue 7: "JWT_SECRET must be a string"

**Error Message:**
```
KeyError: 'JWT_SECRET'
```

**Cause:** JWT_SECRET not in .env or not loaded

**Check .env:**
```powershell
cat backend_flask_small/.env | findstr JWT_SECRET
```

**Should show:**
```
JWT_SECRET=default_secret_key_must_be_long_and_strong_for_production_use_only
```

**Solutions:**
1. Create/recreate .env (see ENVIRONMENT_SETUP_GUIDE.md)
2. Ensure no blank lines or spaces around `=`
3. Restart backend to reload .env

---

### Issue 8: "No route or endpoint found for ..."

**Error Response:**
```json
{
  "error": true,
  "statusCode": 404,
  "message": "Endpoint not found"
}
```

**Causes:**
1. Wrong endpoint URL
2. Wrong HTTP method (GET vs POST)
3. Backend routes not properly registered

**Verify endpoints:**
```powershell
# Test health endpoint
curl http://localhost:5000/health

# Test login endpoint
curl -X POST http://localhost:5000/api/owners/login `
  -H "Content-Type: application/json" `
  -d '{"email":"test@example.com","password":"test"}'
```

**See API_REFERENCE.md for all endpoint URLs**

---

### Issue 9: "Port already in use - Address already in use"

**Error Message:**
```
OSError: [Errno 48] Address already in use
```

**Cause:** Another process using port 5000

**Solution 1 - Use different port:**
```ini
# In backend_flask_small/.env
PORT=5001

# Then run:
& "C:\Users\psabh\AppData\Local\Programs\Python\Python313\python.exe" app.py

# BUT: Desktop app expects port 5000!
# You'll need to edit desktop app and rebuild
```

**Solution 2 - Kill existing process:**
```powershell
# Find what's using port 5000
netstat -ano | findstr LISTENING | findstr :5000

# Kill process (replace PID with actual number)
taskkill /PID <PID> /F

# Verify it's gone
netstat -ano | findstr :5000
```

**Solution 3 - Wait and retry:**
- Sometimes Windows holds onto sockets
- Wait 60 seconds and try again

---

### Issue 10: "Desktop app starts but shows login error"

**Symptoms:**
- App launches but immediately shows error
- "No private key found" or "Login failed"

**Causes:**
1. Backend not responding
2. Backend crashed
3. Invalid credentials
4. Database corruption

**Debugging:**

**Step 1 - Check backend is running:**
```powershell
curl http://localhost:5000/health
```

**Step 2 - Check console output:**
- Look at backend console for error messages
- Look for "OSError: [Errno 48] Address already in use"
- Look for database errors

**Step 3 - Reset database:**
```powershell
cd backend_flask_small

# Option 1: Create new owner
python create_owner_account.py

# Option 2: Use test account
cat owner_account_info.txt
```

**Step 4 - Check .env values:**
```powershell
cat .env | findstr -v "^#"
```

---

### Issue 11: "Flutter: connection timeout"

**Error Message:**
```
SocketException: Connection failed (OS Error: A connection attempt failed...)
```

**Causes:**
1. Backend not running
2. Wrong IP/port in code
3. Firewall blocking

**Verify code has correct URL:**
```powershell
# Check api_service.dart
Select-String "baseUrl" desktop_app/lib/services/api_service.dart
```

Should show: `final String baseUrl = 'http://localhost:5000';`

**If URL is different:**
1. Edit api_service.dart
2. Change to: `'http://localhost:5000'`
3. Rebuild: `flutter clean && flutter run -d windows`

---

### Issue 12: "Token expired or invalid"

**Error Response:**
```json
{
  "error": true,
  "message": "Token missing or invalid"
}
```

**Causes:**
1. Access token expired (15 minutes)
2. Wrong token format
3. Token modified

**Solution:**
- Log out and log back in
- The app should handle token refresh automatically
- Check JWT_SECRET hasn't changed

---

## Environment Variables Reference

### Required (.env)
```ini
PORT=5000                    # Backend port
HOST=0.0.0.0               # Listen on all interfaces
NODE_ENV=development        # For debug output
JWT_SECRET=<strong_key>     # Token signing key
DB_FILE=database.sqlite     # SQLite database file
```

### Optional (.env)
```ini
DEBUG=True                  # Enable debug mode
LOG_LEVEL=DEBUG             # Logging level
MAX_FILE_SIZE=100mb         # Max upload size
UPLOAD_DIR=./uploads        # Upload directory
ENCRYPTION_KEY=<key>        # Encryption key
CORS_ORIGIN=http://localhost  # CORS allowed origins
```

---

## Verification Commands

```powershell
# Check Python installation
& "C:\Users\psabh\AppData\Local\Programs\Python\Python313\python.exe" --version

# Check pip packages
& "C:\Users\psabh\AppData\Local\Programs\Python\Python313\python.exe" -m pip list

# Check if port 5000 is listening
netstat -ano | findstr :5000

# Test backend health
curl http://localhost:5000/health

# Test backend is responding
curl -v http://localhost:5000/api/owners/login

# Check .env file
cat backend_flask_small/.env

# List database files
ls -la backend_flask_small/database.sqlite

# Check desktop app config
Select-String "baseUrl" desktop_app/lib/services/*.dart
```

---

## Getting Help

1. **Check logs:**
   - Backend: Console output while running
   - Desktop app: Flutter DevTools → Console
   - Windows Event Viewer → Applications and Services Logs

2. **Enable debug mode:**
   - Add `DEBUG=True` to .env
   - Add `debug: true` flags to app

3. **Document the error:**
   - Full error message (copy-paste)
   - Screenshot of error
   - Backend console output
   - Desktop app console output
   - Steps to reproduce

4. **Reference documentation:**
   - ENVIRONMENT_SETUP_GUIDE.md
   - API_REFERENCE.md
   - DESKTOP_APP_CONFIG.md

---

## Quick Reset (Nuclear Option)

If everything is broken:

```powershell
# 1. Kill any running processes
taskkill /F /IM python.exe

# 2. Clean up
cd backend_flask_small
rm database.sqlite
rm -r __pycache__
rm -r .pytest_cache

# 3. Verify .env exists and is correct
# (Should already be there)

# 4. Reinstall Python packages
& "C:\Users\psabh\AppData\Local\Programs\Python\Python313\python.exe" -m pip install --upgrade pip
& "C:\Users\psabh\AppData\Local\Programs\Python\Python313\python.exe" -m pip install -r requirements.txt

# 5. Start fresh
& "C:\Users\psabh\AppData\Local\Programs\Python\Python313\python.exe" app.py

# 6. In new terminal, rebuild and run Flutter app
cd desktop_app
flutter clean
flutter pub get
flutter run -d windows
```

---

**Still having issues?** Check:
1. ENVIRONMENT_SETUP_GUIDE.md (comprehensive guide)
2. ENV_COMPATIBILITY_CHECKLIST.md (configuration checklist)
3. API_REFERENCE.md (API endpoint details)
4. Backend console output (most errors logged there)

