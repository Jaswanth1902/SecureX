# Desktop App Backend API Reference

## Base URL
```
http://localhost:5000
```

## Authentication Endpoints

### POST /api/owners/register
Register a new owner account.

**Request:**
```json
{
  "email": "owner@example.com",
  "password": "secure_password",
  "full_name": "Owner Name",
  "public_key": "-----BEGIN RSA PUBLIC KEY-----\n...\n-----END RSA PUBLIC KEY-----"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "accessToken": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refreshToken": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "owner": {
    "id": 1,
    "email": "owner@example.com",
    "full_name": "Owner Name",
    "created_at": "2024-12-04T12:00:00Z"
  }
}
```

### POST /api/owners/login
Authenticate and receive access token.

**Request:**
```json
{
  "email": "owner@example.com",
  "password": "secure_password"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "accessToken": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refreshToken": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "owner": {
    "id": 1,
    "email": "owner@example.com",
    "full_name": "Owner Name"
  }
}
```

**Error (401 Unauthorized):**
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

## File Management Endpoints

### GET /api/files
List all files for the authenticated owner.

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Response (200 OK):**
```json
{
  "files": [
    {
      "file_id": "file123",
      "file_name": "document.pdf",
      "uploaded_at": "2024-12-04T10:30:00Z",
      "status": "pending",
      "size": 1024000
    }
  ],
  "count": 1
}
```

**Error (401 Unauthorized):**
```json
{
  "error": true,
  "message": "Token missing or invalid"
}
```

### GET /api/print/{fileId}
Retrieve encrypted file data for printing.

**URL Parameters:**
- `fileId` - The unique file identifier

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Response (200 OK):**
```json
{
  "file_id": "file123",
  "file_name": "document.pdf",
  "encrypted_file_data": "base64_encoded_encrypted_data",
  "iv_vector": "base64_encoded_iv",
  "auth_tag": "base64_encoded_auth_tag",
  "encrypted_symmetric_key": "base64_encoded_rsa_encrypted_key"
}
```

The encrypted_file_data is encrypted with:
- Algorithm: AES-256-GCM
- IV: 12 bytes (included as iv_vector)
- Auth Tag: 16 bytes (included as auth_tag)
- Key: AES-256 symmetric key, encrypted with RSA public key

**Error Responses:**
- 404 Not Found: File not found
- 401 Unauthorized: Invalid token

### POST /api/delete/{fileId}
Delete a file from the server.

**URL Parameters:**
- `fileId` - The unique file identifier

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "File deleted successfully"
}
```

**Error Responses:**
- 404 Not Found: File not found
- 401 Unauthorized: Invalid token

## Notification Endpoints

### GET /api/events/stream
Server-Sent Events (SSE) stream for real-time notifications.

**Headers:**
```
Authorization: Bearer <accessToken>
Accept: text/event-stream
```

**Response (200 OK - Stream):**
```
event: new_file
data: {"file_id": "file456", "file_name": "new_document.pdf"}

event: file_processed
data: {"file_id": "file123", "status": "printed"}

event: file_deleted
data: {"file_id": "file789"}
```

**Event Types:**
- `new_file`: New file uploaded for this owner
- `file_processed`: File has been printed/processed
- `file_deleted`: File has been deleted
- `error`: Server error (closes connection)

## Health Check

### GET /health
Check backend server health.

**Response (200 OK):**
```json
{
  "status": "OK",
  "environment": "development"
}
```

## Error Handling

All endpoints return consistent error responses:

### 400 Bad Request
```json
{
  "error": true,
  "statusCode": 400,
  "message": "Invalid request data"
}
```

### 401 Unauthorized
```json
{
  "error": true,
  "statusCode": 401,
  "message": "Token missing or invalid"
}
```

### 404 Not Found
```json
{
  "error": true,
  "statusCode": 404,
  "message": "Endpoint not found"
}
```

### 500 Internal Server Error
```json
{
  "error": true,
  "statusCode": 500,
  "message": "Internal Server Error"
}
```

## Authentication Flow

1. **Register/Login**: POST to `/api/owners/register` or `/api/owners/login`
2. **Receive Tokens**: Get `accessToken` and `refreshToken` in response
3. **Use Access Token**: Include in all subsequent requests: `Authorization: Bearer <accessToken>`
4. **Token Expiry**: Access tokens expire in 15 minutes
5. **Refresh Token**: Use refreshToken to obtain new accessToken (if endpoint exists)

## File Decryption Flow

1. Call GET `/api/print/{fileId}` with valid accessToken
2. Receive encrypted file data with RSA-encrypted AES key
3. Decrypt symmetric key using owner's RSA private key
4. Decrypt file data using AES-256-GCM with:
   - Symmetric key (decrypted in step 3)
   - IV (provided as iv_vector)
   - Auth tag (provided as auth_tag)
5. Save or print decrypted file

## Rate Limiting

Currently: No rate limiting implemented
Recommendation: Implement rate limiting for production

## CORS Configuration

**Allowed Origins:**
- http://localhost:3000
- http://127.0.0.1:5000

**Credentials:**
- true (cookies included in requests)

## Testing with curl

```bash
# Health check
curl http://localhost:5000/health

# Register
curl -X POST http://localhost:5000/api/owners/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"pass","full_name":"Test","public_key":"key"}'

# Login
curl -X POST http://localhost:5000/api/owners/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"pass"}'

# List files
curl http://localhost:5000/api/files \
  -H "Authorization: Bearer <token>"

# Get file
curl http://localhost:5000/api/print/file123 \
  -H "Authorization: Bearer <token>"

# Delete file
curl -X POST http://localhost:5000/api/delete/file123 \
  -H "Authorization: Bearer <token>"
```

## Important Notes

1. All timestamps are in UTC/ISO 8601 format
2. All binary data is base64 encoded in JSON responses
3. File IDs are unique identifiers assigned by backend
4. Access tokens must be included in Authorization header
5. Token format: `Authorization: Bearer <token>` (note the space after Bearer)
6. All requests must include appropriate Content-Type headers
7. HTTPS should be used in production
