# Detailed Analysis: tests/audit_sessions.js

## File Information
- **Path**: `backend/tests/audit_sessions.js`
- **Type**: Integration Test / Audit Script
- **Function**: Verification of Session Management

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This script verifies the `sessions` table, which is critical for the security of the application. It tests:
1.  **Session Creation**: Storing token hashes.
2.  **Token Rotation**: Updating hashes when tokens are refreshed.
3.  **Revocation**: Invalidating sessions on logout.
4.  **Cascade Delete**: Ensuring sessions are wiped when the user is deleted.

## Line-by-Line Explanation

### Imports

**Line 1-3**: Dependencies
```javascript
const db = require('../database');
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');
```
*   **Explanation**:
    *   `crypto`: Used to generate SHA-256 hashes. We *never* store raw tokens in the DB, only hashes.

### Main Function

**Line 5**: Start
```javascript
async function testSessionChanges() {
```
*   **Explanation**: Async entry point.

### Setup

**Line 11-12**: Create User
```javascript
    const userRes = await db.query("INSERT INTO users (email, password_hash) VALUES ($1, 'hash') RETURNING id", [testEmail]);
    const userId = userRes.rows[0].id;
```
*   **Explanation**: Sessions must belong to a user (Foreign Key).

### Step 1: Create Session (INSERT)

**Line 15**: Log Action
```javascript
    console.log('Performing INSERT (Create Session)...');
```
*   **Explanation**: Simulates a login event.

**Line 16-17**: Hash Generation
```javascript
    const tokenHash = crypto.createHash('sha256').update('access_token').digest('hex');
    const refreshHash = crypto.createHash('sha256').update('refresh_token').digest('hex');
```
*   **Explanation**: Simulates the hashing process that `AuthService` performs.

**Line 21-24**: Execute Insert
```javascript
    const insertRes = await db.query(
      `INSERT INTO sessions (user_id, token_hash, refresh_token_hash, expires_at, refresh_expires_at) 
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [userId, tokenHash, refreshHash, expiresAt, refreshExpiresAt]
    );
```
*   **Explanation**: Stores the session. Note that `is_valid` defaults to `true`.

### Step 2: Rotate Token (UPDATE)

**Line 30**: Log Action
```javascript
    console.log('Performing UPDATE (Rotate Token)...');
```
*   **Explanation**: Simulates the `/refresh-token` endpoint.

**Line 32-35**: Execute Update
```javascript
    const updateRes = await db.query(
      'UPDATE sessions SET refresh_token_hash = $1 WHERE id = $2 RETURNING *',
      [newRefreshHash, sessionId]
    );
```
*   **Explanation**: Updates the hash. This invalidates the old refresh token.

### Step 3: Revoke (UPDATE)

**Line 40**: Log Action
```javascript
    console.log('Performing UPDATE (Revoke)...');
```
*   **Explanation**: Simulates `/logout`.

**Line 41-44**: Execute Update
```javascript
    await db.query(
      'UPDATE sessions SET is_valid = false, revoked_at = NOW() WHERE id = $1',
      [sessionId]
    );
```
*   **Explanation**: Soft deletes the session. It still exists in DB for audit, but `is_valid=false` prevents it from being used.

### Step 4: Cascade Delete

**Line 48-49**: Delete User
```javascript
    console.log('Performing DELETE (User)...');
    await db.query('DELETE FROM users WHERE id = $1', [userId]);
```
*   **Explanation**: Deletes the parent user.

**Line 52-53**: Verify
```javascript
    const check = await db.query('SELECT * FROM sessions WHERE id = $1', [sessionId]);
    if (check.rows.length === 0) {
```
*   **Explanation**:
    *   Checks if the session is gone.
    *   **Success**: `ON DELETE CASCADE` worked.
    *   **Failure**: Schema is wrong.

## Summary
This script validates the security lifecycle of user sessions. It ensures that we can securely store, rotate, and revoke access credentials, and that we don't leave orphaned sessions when users are deleted.
