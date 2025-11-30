# File Upload Flow Analysis - SafeCopy System

## Overview

When you send a file through the Flutter mobile app to the running Flask server, here's the complete process:

---

## 📱 MOBILE APP (Flutter) - Upload Flow

### **Phase 1: File Selection**

**Location:** `mobile_app/lib/screens/upload_screen.dart` - `pickFile()` function

```
User taps "Pick File"
    ↓
FilePicker shows file browser (Android Storage Access Framework)
    ↓
User selects file (PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX, TXT)
    ↓
File is read as Uint8List bytes (via file.bytes or File.readAsBytes())
    ↓
File metadata stored in state:
  - selectedFileName: String
  - selectedFileSize: int
  - selectedFileBytes: Uint8List
```

**What happens:**

- File picker uses SAF (Storage Access Framework) - no manual permissions needed
- File data is loaded entirely into memory as `Uint8List`
- Maximum file size is limited by available RAM

---

### **Phase 2: Encryption on Mobile**

**Location:** `mobile_app/lib/screens/upload_screen.dart` - `encryptAndUploadFile()` function

#### **Step 2.1: Generate AES-256 Key**

```
EncryptionService.generateAES256Key()
    ↓
Generates 32 random bytes using Random.secure()
    ↓
Result: 256-bit AES key (never leaves the app)
```

#### **Step 2.2: Encrypt File with AES-256-GCM**

**Location:** `mobile_app/lib/services/encryption_service.dart`

```
encryptFileAES256(fileData, aesKey)
    ↓
1. Generate 12-byte random IV (Initialization Vector)
   - Required for AES-GCM mode
    ↓
2. Use package:cryptography AesGcm.with256bits()
    ↓
3. Encrypt file data
    ↓
4. Generate authentication tag (for integrity checking)
    ↓
Returns:
  - encrypted: Uint8List (encrypted file)
  - iv: Uint8List (12 bytes)
  - authTag: Uint8List (16 bytes)
  - key: Uint8List (32 bytes - the AES key)
```

**Encryption Details:**

- Algorithm: AES-256-GCM (Galois/Counter Mode)
- IV size: 12 bytes (nonce)
- Auth tag size: 16 bytes (for authenticated encryption)
- Encrypted file size: ≈ original file size

#### **Step 2.3: Encrypt the AES Key with RSA-2048-OAEP**

```
User enters Owner ID
    ↓
App calls: apiService.getOwnerPublicKey(ownerId)
    ↓
Backend returns owner's public key (RSA-2048)
    ↓
encryptSymmetricKeyRSA(aesKey, publicKeyPem)
    ↓
1. Parse RSA public key from PEM format
2. Use package:encrypt RSA encrypter
3. Algorithm: RSA-2048-OAEP with SHA-256
4. Encrypt the 32-byte AES key
    ↓
Returns: Base64-encoded encrypted key (≈256 bytes when encoded)
```

**Why two layers?**

- AES-256-GCM: Fast, encrypts large files efficiently
- RSA-2048-OAEP: Encrypts the AES key with owner's public key
- Only owner (with private key) can decrypt the AES key to access the file

---

### **Phase 3: Upload to Server**

**Location:** `mobile_app/lib/screens/upload_screen.dart` - `uploadEncryptedFile()` function

```
Create HTTP Multipart Request to: http://10.117.97.71:5000/api/upload
    ↓
Set headers:
  - Authorization: Bearer <access-token>

Form fields:
  - file_name: String (original filename)
  - iv_vector: base64(IV) - 12 bytes encoded
  - auth_tag: base64(authTag) - 16 bytes encoded
  - encrypted_symmetric_key: base64(encrypted AES key) - ~256 bytes encoded
  - owner_id: String (owner's user ID)
    ↓
File binary:
  - 'file': encrypted file data (binary)
    ↓
POST request sent to server
```

**What's being sent:**

- Encrypted file (can't be read by server)
- Encryption metadata (IV, auth tag, encrypted key)
- Owner ID (to identify who should decrypt it)
- JWT access token (for authentication)
- **Access Token Issue:** Currently hardcoded as `'test-token-for-development'` ⚠️

---

## 🔧 BACKEND (Flask) - Receive & Store Flow

### **Phase 1: Authentication Check**

**Location:** `backend_flask/routes/files.py` - `upload_file()` function

```
@token_required decorator (from auth_utils.py)
    ↓
1. Extract Bearer token from Authorization header
2. Verify JWT signature using JWT_SECRET
3. Decode token payload:
   - sub (user_id)
   - email
   - role
   - exp (expiration)
    ↓
If token invalid/expired:
  → Return 401 Unauthorized
    ↓
If valid:
  → Store decoded data in g.user
  → Continue to upload_file()
```

**Current Issue:** The mobile app sends a hardcoded test token, which will **FAIL** at this stage if:

- JWT_SECRET doesn't match what's used to generate the token
- The token format is invalid
- Result: **401 Unauthorized error** ❌

---

### **Phase 2: Validate Uploaded Data**

```
Check if 'file' in request.files
    ↓
Extract form fields:
  - file_name
  - iv_vector (base64)
  - auth_tag (base64)
  - encrypted_symmetric_key (base64)
  - owner_id
    ↓
Validate all required fields present
    ↓
If any missing:
  → Return 400 Bad Request
    ↓
Decode Base64 fields back to bytes:
  - iv_vector = base64.b64decode(iv_vector_b64)
  - auth_tag = base64.b64decode(auth_tag_b64)
  - encrypted_key = base64.b64decode(encrypted_symmetric_key_b64)
  - file_data = file.read()
    ↓
Calculate file size
Get MIME type (or default to 'application/octet-stream')
```

---

### **Phase 3: Generate File ID & Store in Database**

```
Generate UUID: file_id = uuid.uuid4()
    ↓
Extract user_id from g.user['sub']
    ↓
Database INSERT query:
  INSERT INTO files (
    id,                      → UUID
    user_id,                 → From JWT token
    owner_id,                → From form field
    file_name,               → Original filename
    encrypted_file_data,     → Full encrypted binary (stored as BLOB)
    file_size_bytes,         → Size of encrypted data
    file_mime_type,          → MIME type
    iv_vector,               → Binary (12 bytes)
    auth_tag,                → Binary (16 bytes)
    encrypted_symmetric_key, → Binary (~256 bytes)
    created_at,              → NOW()
    is_deleted               → false
  ) VALUES (...)
    ↓
Database returns:
  - file_id
  - created_at timestamp
    ↓
Response sent to mobile app (HTTP 201 Created):
{
  "success": true,
  "file_id": "550e8400-e29b-41d4-a716-446655440000",
  "file_name": "document.pdf",
  "file_size_bytes": 1024000,
  "uploaded_at": "2025-11-30T10:30:45.123456",
  "message": "File uploaded successfully"
}
```

---

## 🗄️ Database Storage

### **PostgreSQL Files Table**

```sql
CREATE TABLE files (
  id UUID PRIMARY KEY,
  user_id UUID,                           -- User who uploaded (from JWT)
  owner_id UUID,                          -- Owner who will print
  file_name VARCHAR(255),                 -- Original filename
  encrypted_file_data BYTEA,              -- ENTIRE file encrypted (can be large)
  file_size_bytes INTEGER,                -- Size in bytes
  file_mime_type VARCHAR(100),            -- e.g., 'application/pdf'
  iv_vector BYTEA,                        -- 12 bytes
  auth_tag BYTEA,                         -- 16 bytes (for GCM authentication)
  encrypted_symmetric_key BYTEA,          -- ~256 bytes (RSA encrypted AES key)
  created_at TIMESTAMP,                   -- Upload time
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP,
  is_deleted BOOLEAN,
  is_printed BOOLEAN,
  printed_at TIMESTAMP
);
```

**What's stored:**

- Entire encrypted file (binary data)
- All encryption metadata needed for owner to decrypt
- Owner can decrypt using their private key → get AES key → decrypt file

---

## ⚠️ CURRENT ISSUES & PROBLEMS

### **Issue 1: Authentication Token ❌ CRITICAL**

```
Mobile app sends: 'test-token-for-development'
Flask expects: Valid JWT token signed with JWT_SECRET

Status: WILL FAIL with 401 Unauthorized
```

**The token validation flow:**

```python
# In auth_utils.py:token_required
token = 'test-token-for-development'  # What mobile app sends

try:
    data = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
    # This will FAIL because:
    # 1. Token is not a valid JWT
    # 2. Even if it was, it wasn't signed with same JWT_SECRET
except jwt.InvalidTokenError:
    return jsonify({'error': True, 'message': 'Invalid token'}), 401
```

**Solution needed:**

- Mobile app needs proper authentication flow
- User should login with credentials
- Backend generates real JWT token
- Mobile app stores token in secure storage
- Mobile app uses real token for uploads

---

### **Issue 2: Database Connection**

```
Backend tries to connect to PostgreSQL on:
  - Host: localhost (default)
  - Port: 5432 (default)
  - User: postgres (default)
  - Password: postgres (default)
  - Database: safecopy_db

If database not running or credentials wrong:
  → Upload will fail with 500 Internal Server Error
```

**Check:**

```bash
# Is PostgreSQL running?
# Is the database created?
# Are credentials correct in .env file?
```

---

### **Issue 3: psycopg2 (PostgreSQL driver)**

```
If psycopg2 not installed:
  - Flask app starts but shows warning
  - Upload fails when trying to execute DB query
  - Error: RuntimeError("Database connection is not available...")
```

**Required:** Windows build tools for psycopg2 compilation, OR use psycopg2-binary

---

### **Issue 4: File Size Limits**

```
Mobile app loads entire file into RAM
If file > available RAM: App crashes

Flask/Werkzeug default MAX_CONTENT_LENGTH = 16 MB
If encrypted file > 16 MB: Upload rejected with 413 Request Entity Too Large
```

---

## 🔄 Complete Flow Summary

```
MOBILE APP                          FLASK SERVER                    DATABASE
─────────────────────────────────────────────────────────────────────────────

1. User picks file
   ↓
2. File loaded to RAM (Uint8List)
   ↓
3. Generate AES-256 key
   ↓
4. Encrypt file with AES-256-GCM
   ↓
5. Get owner's public key ─────────→ /api/owners/public-key/{ownerId}
                                     ←─────── Return RSA public key
   ↓
6. Encrypt AES key with RSA
   ↓
7. Build multipart request:
   - Bearer token: 'test-token-for-development'
   - Form: file_name, iv_vector, auth_tag, encrypted_symmetric_key, owner_id
   - Binary: encrypted file data
   ↓
8. POST /api/upload ────────────────→ @token_required decorator
                                      ├─ Extract token
                                      ├─ Verify JWT
                                      └─ [FAILS - invalid token]

                                      If valid:
                                      ├─ Validate form fields
                                      ├─ Generate UUID
                                      ├─ INSERT into files table ───→ ✅ Store encrypted data
                                      ├─ COMMIT
                                      └─ Return file_id + created_at
                                      ←─────── HTTP 201 + JSON response
   ↓
9. Display success with file_id


Database now contains:
├─ Encrypted file (binary, unreadable)
├─ IV vector (for decryption)
├─ Auth tag (for integrity verification)
├─ Encrypted AES key (only owner can decrypt with private key)
└─ Metadata (filename, size, owner, user, timestamps)
```

---

## 🎯 Expected Behavior vs Actual Behavior

### **Expected (if everything works):**

1. ✅ File encrypted on mobile
2. ✅ Auth token validated
3. ✅ Data stored in DB
4. ✅ Return success with file_id
5. ✅ File ready for owner to decrypt and print

### **Actual (current state):**

1. ✅ File encrypted on mobile
2. ❌ **Auth token validation FAILS** (401 Unauthorized)
3. ❌ Request never reaches upload logic
4. ❌ Database not updated
5. ❌ Error returned to mobile app

---

## 🔧 What Needs to Be Fixed

1. **Implement real authentication flow**

   - Login endpoint that returns real JWT
   - Store token securely on mobile
   - Use real token for uploads

2. **Verify database connection**

   - Ensure PostgreSQL is running
   - Check .env credentials
   - Run migrations/create tables

3. **Handle file size limits**

   - Set appropriate MAX_CONTENT_LENGTH
   - Stream uploads instead of loading all at once

4. **Add error handling**

   - Database errors
   - Network errors
   - File system errors

5. **Logging & Monitoring**
   - Add detailed logs on both sides
   - Monitor upload progress
   - Handle connection timeouts

---

## 📊 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     MOBILE APP                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 1. Pick File                                            │   │
│  │ 2. Generate AES-256 key                                 │   │
│  │ 3. Encrypt file: AES-256-GCM                            │   │
│  │ 4. Fetch owner's RSA public key                         │   │
│  │ 5. Encrypt AES key with RSA                             │   │
│  │ 6. Build multipart request with:                        │   │
│  │    - Encrypted file (binary)                            │   │
│  │    - IV (12 bytes)                                      │   │
│  │    - Auth tag (16 bytes)                                │   │
│  │    - Encrypted AES key (RSA encrypted)                  │   │
│  │    - Owner ID                                           │   │
│  │    - JWT token                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                    POST /api/upload
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FLASK SERVER                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 1. @token_required - Verify JWT                         │   │
│  │ 2. Validate all form fields present                     │   │
│  │ 3. Decode Base64 fields to binary                       │   │
│  │ 4. Read encrypted file data                             │   │
│  │ 5. Generate UUID for file                               │   │
│  │ 6. Get user_id from JWT token                           │   │
│  │ 7. INSERT INTO files table                              │   │
│  │ 8. COMMIT transaction                                   │   │
│  │ 9. Return 201 + file_id                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                    Insert encrypted data
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   PostgreSQL DATABASE                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ files TABLE                                             │   │
│  │  ├─ id: UUID                                            │   │
│  │  ├─ user_id: UUID (who uploaded)                        │   │
│  │  ├─ owner_id: UUID (who will print)                     │   │
│  │  ├─ file_name: VARCHAR                                  │   │
│  │  ├─ encrypted_file_data: BYTEA (entire file encrypted)  │   │
│  │  ├─ file_size_bytes: INTEGER                            │   │
│  │  ├─ file_mime_type: VARCHAR                             │   │
│  │  ├─ iv_vector: BYTEA (12 bytes)                         │   │
│  │  ├─ auth_tag: BYTEA (16 bytes)                          │   │
│  │  ├─ encrypted_symmetric_key: BYTEA (RSA encrypted)      │   │
│  │  ├─ created_at: TIMESTAMP                               │   │
│  │  └─ ...other fields                                     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Testing Checklist

- [ ] Is Flask server running? `python backend_flask/app.py`
- [ ] Is PostgreSQL running? Check port 5432
- [ ] Are .env credentials correct?
- [ ] Is mobile app pointing to correct server IP (10.117.97.71:5000)?
- [ ] Is proper JWT token being sent?
- [ ] Can you see POST request in Flask logs?
- [ ] Is database table created with schema?
- [ ] Do you see any errors in Flask console?
