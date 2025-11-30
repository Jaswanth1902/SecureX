# Detailed Analysis: routes/auth.js

## File Information
- **Path**: `backend/routes/auth.js`
- **Type**: API Routes
- **Function**: User Authentication & Session Management

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This file defines the HTTP endpoints for user authentication. It handles the complete lifecycle of a user session:
1.  **Registration**: Creating a new account.
2.  **Login**: Verifying credentials and issuing tokens.
3.  **Token Refresh**: Issuing new access tokens when old ones expire.
4.  **Logout**: Invalidating sessions.

It interacts heavily with the `AuthService` for logic and the `database` for persistence.

## Line-by-Line Explanation

### Imports

**Line 1-4**: Dependencies
```javascript
const express = require("express");
const router = express.Router();
const db = require("../database");
const AuthService = require("../services/authService");
```
*   **Explanation**:
    *   `express.Router()`: Creates a modular, mountable route handler.
    *   `db`: Imports the database connection to run SQL queries.
    *   `AuthService`: Imports the service layer that handles business logic like hashing and token generation.

### Registration Endpoint

**Line 7**: Route Definition
```javascript
router.post("/register", async (req, res) => {
```
*   **Explanation**: Defines a POST route at `/register`. Since this file is mounted at `/api/auth` in `server.js`, the full URL is `POST /api/auth/register`.

**Line 8-13**: Input Validation
```javascript
  try {
    const { email, password, full_name } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: "email and password required" });
    }
```
*   **Explanation**: Destructures the request body and checks for required fields. Returns 400 Bad Request if missing.

**Line 15-22**: Format Validation
```javascript
    if (!AuthService.validateEmail(email)) {
      return res.status(400).json({ error: "Invalid email format" });
    }

    const { isValid, errors } = AuthService.validatePassword(password);
    if (!isValid) {
      return res.status(400).json({ error: "Weak password", details: errors });
    }
```
*   **Explanation**: Calls static methods on `AuthService` to validate the email format and password strength (e.g., min length, special chars).

**Line 25**: Password Hashing
```javascript
    const passwordHash = await AuthService.hashPassword(password);
```
*   **Explanation**: Hashes the password using bcrypt. **Crucial**: We never store the plain password.

**Line 27-39**: Database Insertion
```javascript
    const insertQ = `
      INSERT INTO users (email, password_hash, full_name)
      VALUES ($1, $2, $3)
      RETURNING id, email, full_name, created_at
    `;

    let result;
    try {
      result = await db.query(insertQ, [
        email,
        passwordHash,
        full_name || null,
      ]);
    }
```
*   **Explanation**:
    *   Defines the SQL query to insert the new user.
    *   `RETURNING ...`: PostgreSQL feature to return the created row immediately, saving a second SELECT query.
    *   Executes the query with parameterized values (`$1, $2, $3`) to prevent SQL Injection.

**Line 40-45**: Duplicate Handling
```javascript
    } catch (dbError) {
      if (dbError.code === '23505') { // Unique violation
        return res.status(409).json({ error: "User already exists" });
      }
      throw dbError;
    }
```
*   **Explanation**: Catches database errors. Code `23505` is the PostgreSQL error code for "unique constraint violation" (i.e., email already exists). Returns 409 Conflict.

**Line 48-50**: Token Generation
```javascript
    const payload = { sub: user.id, email: user.email, role: "user" };
    const accessToken = AuthService.generateAccessToken(payload);
    const refreshToken = AuthService.generateRefreshToken(payload);
```
*   **Explanation**:
    *   Creates the JWT payload. `sub` (subject) is the standard claim for User ID.
    *   Generates both access (short-lived) and refresh (long-lived) tokens.

**Line 53-59**: Session Storage
```javascript
    const hashedRefresh = AuthService.hashToken(refreshToken);
    const expiresAt = new Date(Date.now() + 7 * 24 * 3600 * 1000); // 7 days
    await db.query(
      `INSERT INTO sessions (user_id, token_hash, refresh_token_hash, expires_at, refresh_expires_at, is_valid)
       VALUES ($1, $2, $3, $4, $4, true)`,
      [user.id, AuthService.hashToken(accessToken), hashedRefresh, expiresAt]
    );
```
*   **Explanation**:
    *   Hashes the refresh token before storing it. If the database is leaked, attackers cannot use the hashes to impersonate users.
    *   Stores the session in the `sessions` table. This allows us to revoke sessions later (e.g., "Log out of all devices").

**Line 61-68**: Response
```javascript
    res
      .status(201)
      .json({
        success: true,
        accessToken,
        refreshToken,
        user: { id: user.id, email: user.email, full_name: user.full_name },
      });
```
*   **Explanation**: Returns 201 Created with the tokens and user info.

### Login Endpoint

**Line 85**: Route Definition
```javascript
router.post("/login", async (req, res) => {
```
*   **Explanation**: `POST /api/auth/login`.

**Line 91-94**: User Lookup
```javascript
    const q = `SELECT id, email, password_hash, full_name FROM users WHERE email = $1`;
    const result = await db.query(q, [email]);
    if (result.rows.length === 0)
      return res.status(401).json({ error: "Invalid credentials" });
```
*   **Explanation**: Finds the user by email. If not found, returns 401 Unauthorized.

**Line 97-98**: Password Verification
```javascript
    const ok = await AuthService.comparePassword(password, user.password_hash);
    if (!ok) return res.status(401).json({ error: "Invalid credentials" });
```
*   **Explanation**: Uses `bcrypt.compare` to verify the password.

**Line 100-111**: Session Creation
*   **Explanation**: Similar to registration, generates tokens and creates a new session record.

### Refresh Token Endpoint

**Line 128**: Route Definition
```javascript
router.post("/refresh-token", async (req, res) => {
```
*   **Explanation**: `POST /api/auth/refresh-token`. Used when the access token expires.

**Line 136-139**: Token Verification
```javascript
      payload = AuthService.verifyRefreshToken(refreshToken);
```
*   **Explanation**: Verifies the signature of the refresh token.

**Line 142-148**: Session Lookup
```javascript
    const hashed = AuthService.hashToken(refreshToken);
    const q =
      "SELECT id AS session_id, user_id FROM sessions WHERE refresh_token_hash = $1 AND is_valid = true AND refresh_expires_at > NOW() LIMIT 1";
```
*   **Explanation**:
    *   Hashes the incoming token to match against the database.
    *   Checks if the session exists, is valid (not revoked), and has not expired.
    *   **Security**: This is "Refresh Token Rotation". We validate the token against the DB state.

**Line 158-170**: Token Rotation
```javascript
    const accessToken = AuthService.generateAccessToken(newPayload);
    const newRefresh = AuthService.generateRefreshToken(newPayload);

    // Update only the specific session record
    await db.query(
      "UPDATE sessions SET refresh_token_hash = $1, token_hash = $2 WHERE user_id = $3 AND id = $4",
      [AuthService.hashToken(newRefresh), AuthService.hashToken(accessToken), userId, sessionId]
    );
```
*   **Explanation**:
    *   Generates a *new* pair of tokens.
    *   Updates the existing session record with the new hashes.
    *   The old refresh token is now invalid. If an attacker stole it, they can only use it once.

### Logout Endpoint

**Line 186**: Route Definition
```javascript
router.post("/logout", async (req, res) => {
```
*   **Explanation**: `POST /api/auth/logout`.

**Line 192-196**: Revocation
```javascript
    const hashed = AuthService.hashToken(refreshToken);
    await db.query(
      "UPDATE sessions SET is_valid = false, revoked_at = NOW() WHERE refresh_token_hash = $1",
      [hashed]
    );
```
*   **Explanation**:
    *   Hashes the token to find the session.
    *   Sets `is_valid = false`. This effectively kills the session. Even if the refresh token is still valid by signature, the server will reject it because of the DB check.

## Summary
This file implements a robust, secure authentication flow using JWTs and Database Sessions. It follows OWASP best practices by:
1.  Hashing passwords with bcrypt.
2.  Using short-lived access tokens and long-lived refresh tokens.
3.  Implementing Refresh Token Rotation.
4.  Storing only hashes of tokens in the database.
