# 🔴 CRITICAL ISSUES FOUND - File Upload Flow

## **Quick Summary: What Happens When You Send a File**

When you send a file through the Flutter mobile app with Flask server running:

### **What SHOULD Happen:**

```
File → Encrypt (AES-256-GCM) → Encrypt Key (RSA) → Upload → Database
✅ Success: File stored securely
```

### **What ACTUALLY Happens:**

```
File → Encrypt (AES-256-GCM) → Encrypt Key (RSA) → Upload → 🔴 AUTH FAILS
❌ Error: 401 Unauthorized - "Invalid token"
```

---

## 🔴 **BLOCKER #1: Authentication Token Invalid**

### The Problem

**File:** `mobile_app/lib/screens/upload_screen.dart` line ~206

```dart
// TODO: In production, get real access token from UserService after login
// For now, using a test token
const accessToken = 'test-token-for-development';
debugPrint('⚠️  Using test access token (development mode)');
```

**What happens:**

1. Mobile app sends: `Authorization: Bearer test-token-for-development`
2. Flask receives request
3. `@token_required` decorator tries to verify token:

```python
# backend_flask/auth_utils.py
try:
    data = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
    # ❌ FAILS: 'test-token-for-development' is NOT a valid JWT
except jwt.InvalidTokenError:
    return jsonify({'error': True, 'message': 'Invalid token'}), 401
```

4. **Server returns 401 Unauthorized**
5. File is **NOT uploaded**
6. Database is **NOT updated**

---

## 🔴 **BLOCKER #2: No Database Connection**

### The Problem

**File:** `backend_flask/db.py` - Connection Pool Setup

Even if token validation passes, the upload will fail at database insert if:

#### **Check 1: Is PostgreSQL Running?**

```
Default config: localhost:5432
If not running: RuntimeError("Database connection is not available")
Response: 500 Internal Server Error
```

#### **Check 2: Are .env Credentials Correct?**

```env
DB_USER=postgres           # ← Is this correct?
DB_PASSWORD=postgres       # ← Is this correct?
DB_HOST=localhost          # ← Should this be different?
DB_PORT=5432              # ← Is PostgreSQL on this port?
DB_NAME=safecopy_db        # ← Does this database exist?
```

#### **Check 3: Is Table Created?**

```sql
-- File stores encrypted file_data as BYTEA
CREATE TABLE files (
  id UUID PRIMARY KEY,
  user_id UUID,
  owner_id UUID,
  file_name VARCHAR(255),
  encrypted_file_data BYTEA,  -- ← LARGE BINARY DATA
  file_size_bytes INTEGER,
  file_mime_type VARCHAR(100),
  iv_vector BYTEA,            -- ← 12 bytes
  auth_tag BYTEA,             -- ← 16 bytes
  encrypted_symmetric_key BYTEA, -- ← ~256 bytes
  created_at TIMESTAMP,
  is_deleted BOOLEAN,
  is_printed BOOLEAN,
  ...
);
```

If table doesn't exist: `psycopg2.ProgrammingError: relation "files" does not exist`
Response: 500 Internal Server Error

---

## 🟡 **ISSUE #3: Hardcoded Server IP**

### The Problem

**File:** `mobile_app/lib/services/api_service.dart` line 6

```dart
final String baseUrl = 'http://10.117.97.71:5000';  // Hardcoded IP
```

**Issues:**

- ❌ Hardcoded IP address (not flexible)
- ❌ HTTP only (not secure - should be HTTPS)
- ❌ Port 5000 only works if Flask running on that port
- ❌ If you run app on different device/network, won't work

**If server not at this address:**

- Request times out or fails to connect
- Mobile app shows: "Connection refused" or "Host unreachable"

---

## 🟡 **ISSUE #4: Missing Environment Variables**

### The Problem

**File:** `backend_flask/.env` (not shown in your files)

```env
# These need to be set:
JWT_SECRET=??                  # ← Used for token verification
NODE_ENV=??                    # ← development/production
PORT=??                        # ← Default 5000
DB_USER=??
DB_PASSWORD=??
DB_HOST=??
DB_PORT=??
DB_NAME=??
```

If `JWT_SECRET` is not set:

```python
JWT_SECRET = os.getenv('JWT_SECRET', 'default_secret_key_must_be_long')
# ↑ Falls back to default, which might not match token generation
```

---

## 📊 **What ACTUALLY Happens Step-by-Step**

### **Step 1-5: Mobile App (Works Fine) ✅**

```
1. User picks file from device
   ✅ File loaded into RAM

2. App generates AES-256 encryption key
   ✅ Key generated using Random.secure()

3. App encrypts file with AES-256-GCM
   ✅ Encrypted data created
   ✅ IV vector created (12 bytes)
   ✅ Auth tag created (16 bytes)

4. App fetches owner's public key
   ✅ GET /api/owners/public-key/{ownerId} → Success

5. App encrypts AES key with owner's RSA public key
   ✅ Encrypted key created (~256 bytes when encoded)
```

### **Step 6: Build Upload Request (Works) ✅**

```
Create HTTP Multipart request with:
├─ Headers:
│  └─ Authorization: Bearer test-token-for-development  ❌ INVALID
├─ Form fields:
│  ├─ file_name: "document.pdf"
│  ├─ iv_vector: "base64_encoded_iv"
│  ├─ auth_tag: "base64_encoded_auth_tag"
│  ├─ encrypted_symmetric_key: "base64_encoded_key"
│  └─ owner_id: "owner-uuid"
└─ File:
   └─ Encrypted file data (binary)
```

### **Step 7: Flask Receives Request (Fails) ❌**

```
POST /api/upload
  ↓
@token_required decorator runs
  ↓
Extract token: 'test-token-for-development'
  ↓
Try: jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
  ↓
❌ jwt.InvalidTokenError: Not a valid JWT
  ↓
Response: HTTP 401 Unauthorized
{
  "error": true,
  "message": "Invalid token"
}
```

### **Result:**

- 🔴 Upload **FAILS** before any database operation
- 🔴 File **NOT stored**
- 🔴 Mobile app shows error dialog

---

## 🔧 **How to Test/Debug**

### **Test 1: Check Flask Server Status**

```bash
# Terminal 1: Start Flask
cd backend_flask
python app.py

# Should see:
# Server running on http://0.0.0.0:5000
# Connection pool created successfully
```

### **Test 2: Check Database Connection**

```bash
# Terminal 2: Test database
psql -U postgres -h localhost -d safecopy_db -c "SELECT COUNT(*) FROM files;"

# If fails: Database not running or credentials wrong
# If works: Database is connected
```

### **Test 3: Manually Test Upload API**

```bash
# Using curl or Postman:
POST http://10.117.97.71:5000/api/upload
Headers:
  Authorization: Bearer test-token-for-development
  Content-Type: multipart/form-data

Form data:
  file_name: test.pdf
  owner_id: 550e8400-e29b-41d4-a716-446655440000
  iv_vector: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==
  auth_tag: AAAAAAAAAAAAAAAAAAAAAA==
  encrypted_symmetric_key: AAAAAA==
  file: <binary data>

Expected response: 401 Unauthorized
{
  "error": true,
  "message": "Invalid token"
}
```

### **Test 4: Check Mobile App Logs**

```
In Flutter app, check debug console:
📤 Uploading to: http://10.117.97.71:5000/api/upload
📥 Response status: 401
📥 Response: {"error": true, "message": "Invalid token"}
```

---

## ✅ **How to Fix**

### **Fix #1: Implement Real Authentication (CRITICAL)**

1. **Create Login endpoint** (already exists)

   ```python
   # backend_flask/routes/auth.py
   POST /api/auth/register  # Register user
   POST /api/auth/login     # Login with password → get JWT token
   ```

2. **Mobile app needs to login first**

   ```dart
   // mobile_app/lib/screens/login_screen.dart

   // Step 1: Register or Login
   var response = await http.post(
     Uri.parse('$baseUrl/api/auth/login'),
     body: {'email': email, 'password': password}
   );

   // Step 2: Extract token
   final token = jsonDecode(response.body)['accessToken'];

   // Step 3: Store token securely
   await FlutterSecureStorage().write(key: 'auth_token', value: token);

   // Step 4: Use token for uploads
   const accessToken = await FlutterSecureStorage().read(key: 'auth_token');
   ```

3. **Replace hardcoded token**

   ```dart
   // BEFORE (broken):
   const accessToken = 'test-token-for-development';

   // AFTER (fixed):
   final accessToken = await _getStoredToken();
   if (accessToken == null) {
     showErrorDialog('Not logged in. Please login first.');
     return;
   }
   ```

### **Fix #2: Verify Database Connection**

```bash
# Check PostgreSQL is running
# Check .env file has correct credentials
# Check database and table exist
# Check network connectivity between Flask and database
```

### **Fix #3: Use Proper Configuration**

- [ ] Set JWT_SECRET in .env
- [ ] Verify DB credentials in .env
- [ ] Use environment-specific configs
- [ ] Remove hardcoded IPs (use settings)

---

## 📈 **Full Success Flow (After Fixes)**

```
User logs in
  ↓
JWT token generated and stored securely
  ↓
User picks file
  ↓
File encrypted (AES-256-GCM)
  ↓
AES key encrypted (RSA)
  ↓
Upload request with VALID token
  ↓
Flask validates token ✅
  ↓
Database INSERT succeeds ✅
  ↓
File stored securely in database ✅
  ↓
Success response returned ✅
  ↓
Mobile app shows file ID ✅
  ↓
Owner can later download and decrypt file ✅
```

---

## 📋 **Immediate Action Items**

| Item                      | Status   | Action                                   |
| ------------------------- | -------- | ---------------------------------------- |
| Flask server running?     | 🔴 Check | Start with `python backend_flask/app.py` |
| PostgreSQL running?       | 🔴 Check | Start PostgreSQL service                 |
| Database created?         | 🔴 Check | Run migrations/create tables             |
| .env configured?          | 🔴 Check | Set JWT_SECRET, DB credentials           |
| Login endpoint working?   | 🔴 Check | Test with `/api/auth/login`              |
| JWT token generation?     | 🔴 Check | Verify token format and signature        |
| Mobile app getting token? | 🔴 Check | Add login flow to app                    |
| Mobile app using token?   | 🔴 Check | Replace hardcoded token                  |
| Upload test?              | 🔴 Check | Use valid token for test request         |

---

## 🎯 **Bottom Line**

**Currently:** ❌ Upload fails immediately with 401 Unauthorized because mobile app sends invalid test token

**After fix:** ✅ Upload will succeed, encrypt securely, and store in database

**Key changes needed:**

1. Implement user login → get real JWT token
2. Mobile app stores and uses real token
3. Verify database is running and accessible
4. Set environment variables correctly

See `FILE_UPLOAD_FLOW_ANALYSIS.md` for detailed technical flow.
