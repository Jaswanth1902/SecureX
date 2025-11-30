# Detailed Analysis: routes/files.js

## File Information
- **Path**: `backend/routes/files.js`
- **Type**: API Routes
- **Function**: File Upload, Listing, Download, and Deletion

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This file handles the core functionality of the Secure File Printing System. It allows:
1.  **Users** to upload encrypted files.
2.  **Owners** to download encrypted files for printing.
3.  **Owners** to mark files as printed (which deletes them).
4.  **Both** to list files they have access to.

It uses `multer` for handling file uploads in memory before saving them to the database.

## Line-by-Line Explanation

### Imports and Setup

**Line 9-14**: Imports
```javascript
const express = require("express");
const router = express.Router();
const multer = require("multer");
const { v4: uuidv4 } = require("uuid");
const db = require("../database");
const { verifyToken, verifyRole } = require("../middleware/auth");
```
*   **Explanation**:
    *   `multer`: Middleware for handling `multipart/form-data`.
    *   `uuidv4`: Generates unique IDs for files.
    *   `verifyToken`, `verifyRole`: Custom middleware to protect routes.

**Line 17-22**: Multer Configuration
```javascript
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 500 * 1024 * 1024, // 500MB max
  },
});
```
*   **Explanation**:
    *   `storage: multer.memoryStorage()`: Stores uploaded files in RAM (as a Buffer) instead of writing to disk. This is faster and more secure for our use case since we immediately encrypt/save to DB.
    *   `limits`: Sets a hard limit of 500MB to prevent Denial of Service (DoS) attacks.

### Upload Endpoint

**Line 28**: Route Definition
```javascript
router.post("/upload", verifyToken, upload.single("file"), async (req, res) => {
```
*   **Explanation**:
    *   `POST /api/upload`.
    *   `verifyToken`: Ensures user is logged in.
    *   `upload.single("file")`: Tells multer to look for a form field named "file".

**Line 30-43**: File Validation
```javascript
    if (!req.file) {
      return res.status(400).json({ error: "No file provided" });
    }
    // ... size checks ...
```
*   **Explanation**: Checks if a file was actually uploaded and if it meets size requirements.

**Line 45-62**: Metadata Validation
```javascript
    if (!req.body.file_name) { ... }
    if (!req.body.iv_vector) { ... }
    if (!req.body.auth_tag) { ... }
```
*   **Explanation**:
    *   Validates that the client sent all necessary encryption metadata.
    *   `iv_vector`: The Initialization Vector used for AES encryption.
    *   `auth_tag`: The GCM authentication tag to verify integrity.
    *   **Crucial**: The server *cannot* decrypt the file without these.

**Line 65-68**: Owner Validation
```javascript
    const ownerId = req.body.owner_id;
    if (!ownerId) {
      return res.status(400).json({ error: "owner_id is required" });
    }
```
*   **Explanation**: The user must specify *who* this file is for.

**Line 78-80**: Buffer Conversion
```javascript
    const ivBuffer = Buffer.from(req.body.iv_vector, "base64");
    const authTagBuffer = Buffer.from(req.body.auth_tag, "base64");
    const encryptedKeyBuffer = Buffer.from(req.body.encrypted_symmetric_key, "base64");
```
*   **Explanation**: The client sends binary data as Base64 strings (JSON doesn't support binary). We convert them back to Buffers for storage.

**Line 84-100**: Database Insert
```javascript
      const query = `
      INSERT INTO files (
        id, user_id, owner_id, file_name, encrypted_file_data, ...
      ) VALUES ($1, $2, $3, $4, $5, ...)
      RETURNING id, file_name, file_size_bytes, created_at
    `;
```
*   **Explanation**: Inserts the file record. `req.file.buffer` contains the actual encrypted file data.

**Line 136-190**: Fallback Mechanism
```javascript
    } catch (dbError) {
      // ... fallback to disk storage ...
```
*   **Explanation**:
    *   This block handles the case where the database is down or refuses the connection.
    *   It saves the file to a local `uploads/` directory instead.
    *   **Note**: This is primarily for development/debugging reliability. In a strict production environment, we might prefer to fail hard.

### List Files Endpoint

**Line 206**: Route Definition
```javascript
router.get("/files", verifyToken, async (req, res) => {
```
*   **Explanation**: `GET /api/files`.

**Line 210-238**: Role-Based Querying
```javascript
    if (req.user && req.user.role === "user") {
      // Show files uploaded BY this user
    } else if (req.user && req.user.role === "owner") {
      // Show files sent TO this owner
    } else {
      // Admin view (all files)
    }
```
*   **Explanation**:
    *   Dynamically constructs the SQL query based on the user's role.
    *   **Privacy**: Users can only see their own files. Owners can only see files assigned to them.

### Download/Print Endpoint

**Line 275-279**: Route Definition
```javascript
router.get(
  "/print/:file_id",
  verifyToken,
  verifyRole(["owner"]),
  async (req, res) => {
```
*   **Explanation**:
    *   `GET /api/print/:file_id`.
    *   `verifyRole(["owner"])`: **Critical Security Control**. Only owners can access this route. Regular users cannot download files, even their own (once uploaded, it's "sent").

**Line 318-325**: Ownership Check
```javascript
      if (req.user && req.user.role === "owner") {
        if (file.owner_id && file.owner_id !== req.user.sub) {
          return res.status(403).json({ ... });
        }
      }
```
*   **Explanation**: Even if you are an owner, you can't download files meant for *other* owners.

**Line 336-359**: Response
```javascript
      res.json({
        success: true,
        encrypted_file_data: file.encrypted_file_data.toString("base64"),
        iv_vector: file.iv_vector.toString("base64"),
        // ...
      });
```
*   **Explanation**: Returns the encrypted blob and metadata. The client app (Desktop App) will use these to decrypt the file locally.

### Delete Endpoint

**Line 378-382**: Route Definition
```javascript
router.post(
  "/delete/:file_id",
  verifyToken,
  verifyRole(["owner"]),
  async (req, res) => {
```
*   **Explanation**: `POST /api/delete/:file_id`.

**Line 429-438**: Soft Delete
```javascript
      const deleteQuery = `
      UPDATE files
      SET 
        is_deleted = true,
        deleted_at = NOW(),
        is_printed = true,
        printed_at = NOW()
      WHERE id = $1
      RETURNING id, file_name, deleted_at
    `;
```
*   **Explanation**:
    *   We don't actually `DELETE FROM files`. We perform a "soft delete" by setting `is_deleted = true`.
    *   **Why**: Audit trails. We want to keep a record that "File X was printed by Owner Y at Time Z".
    *   The application logic (List Files) filters out deleted files, so they appear gone to the user.

## Summary
This file implements the core business logic. It securely handles binary data, enforces strict access controls, and ensures that the server acts as a zero-knowledge store (it never sees the plaintext file).
