# Detailed Analysis: routes/owners.js

## File Information
- **Path**: `backend/routes/owners.js`
- **Type**: API Routes
- **Function**: Owner Management & Public Key Distribution

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This file handles the registration and authentication of "Owners" (Print Shop Owners). The key difference between a User and an Owner is that **Owners have an RSA Keypair**.
1.  **Registration**: Owner submits their **Public Key** along with their details.
2.  **Public Key Retrieval**: Users need to fetch an Owner's public key to encrypt files for them.
3.  **Login**: Standard JWT login, similar to users.

## Line-by-Line Explanation

### Imports

**Line 1-5**: Dependencies
```javascript
const express = require("express");
const router = express.Router();
const db = require("../database");
const AuthService = require("../services/authService");
const { verifyToken, verifyRole } = require("../middleware/auth");
```
*   **Explanation**: Standard imports. Note `verifyRole` is used to protect owner-specific routes.

### Security Note

**Line 7-14**: Comment Block
```javascript
// ========================================
// SECURITY NOTE: Private Key Handling
// ========================================
// Private keys are NEVER generated or stored on the server.
```
*   **Explanation**: This is a critical architectural decision. The server is "Zero Knowledge". If the server generated the keys, it would theoretically have access to the private key. By forcing client-side generation, we ensure only the owner has the private key.

### Registration Endpoint

**Line 18**: Route Definition
```javascript
router.post("/register", async (req, res) => {
```
*   **Explanation**: `POST /api/owners/register`.

**Line 26-32**: Public Key Validation
```javascript
    if (!public_key) {
      return res.status(400).json({
        error: "public_key is required",
        message: "You must generate an RSA-2048 keypair client-side...",
      });
    }
```
*   **Explanation**: Enforces that a public key is provided.

**Line 39-44**: PEM Format Check
```javascript
    if (!public_key.startsWith("-----BEGIN PUBLIC KEY-----")) {
      return res.status(400).json({
        error: "invalid_public_key_format",
        message: "Public key must be in PEM format (SPKI)",
      });
    }
```
*   **Explanation**: Basic string check to ensure the key looks like a valid PEM encoded RSA public key.

**Line 55-59**: Database Insertion
```javascript
    const insertQ = `
      INSERT INTO owners (email, password_hash, full_name, public_key)
      VALUES ($1, $2, $3, $4)
      RETURNING id, email, full_name, created_at
    `;
```
*   **Explanation**: Stores the owner record, including the public key, in the `owners` table.

**Line 69-80**: Session Creation
*   **Explanation**: Automatically logs the owner in after registration by generating tokens and creating a session.

### Login Endpoint

**Line 104**: Route Definition
```javascript
router.post("/login", async (req, res) => {
```
*   **Explanation**: `POST /api/owners/login`.

**Line 111-114**: Owner Lookup
```javascript
    const result = await db.query(
      "SELECT id, email, password_hash, full_name FROM owners WHERE email = $1",
      [email]
    );
```
*   **Explanation**: Queries the `owners` table (distinct from `users` table).

**Line 125**: Payload Role
```javascript
    const payload = { sub: owner.id, email: owner.email, role: "owner" };
```
*   **Explanation**: Sets the `role` claim in the JWT to "owner". This is what `verifyRole(['owner'])` checks later.

### Public Key Endpoint

**Line 158**: Route Definition
```javascript
router.get("/public-key/:ownerId", async (req, res) => {
```
*   **Explanation**: `GET /api/owners/public-key/:ownerId`.
*   **Access**: Public. No `verifyToken` middleware. Any user needs to be able to call this to get the key for encryption.

**Line 167-170**: Database Query
```javascript
    const result = await db.query(
      "SELECT public_key FROM owners WHERE id = $1",
      [ownerId]
    );
```
*   **Explanation**: Fetches only the `public_key` column.

**Line 175**: Response
```javascript
    res.json({ success: true, public_key: result.rows[0].public_key });
```
*   **Explanation**: Returns the PEM string.

### Profile Endpoint

**Line 191**: Route Definition
```javascript
router.get("/me", verifyToken, verifyRole(["owner"]), async (req, res) => {
```
*   **Explanation**: `GET /api/owners/me`.
*   **Access**: Protected. Only logged-in owners can see their own profile.

**Line 195-198**: Query
```javascript
    const result = await db.query(
      "SELECT id, email, full_name, created_at FROM owners WHERE id = $1",
      [ownerId]
    );
```
*   **Explanation**: Returns profile info. Note that we do *not* return the password hash.

## Summary
This file manages the identity of the "Receivers" in our system. The most important aspect is the handling of the **Public Key**. By storing it in the database and exposing it via an API, we create a simple Public Key Infrastructure (PKI) where users can securely send messages (files) to owners without ever having exchanged secrets beforehand.
