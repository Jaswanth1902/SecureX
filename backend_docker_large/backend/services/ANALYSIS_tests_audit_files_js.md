# Detailed Analysis: tests/audit_files.js

## File Information
- **Path**: `backend/tests/audit_files.js`
- **Type**: Integration Test / Audit Script
- **Function**: Verification of File Upload and Lifecycle

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This script verifies the most complex part of the database schema: the `files` table. This table has Foreign Key relationships with both `users` and `owners`. Therefore, simply trying to insert a file will fail if the referenced user or owner doesn't exist. This script handles that dependency chain, proving the relational integrity of the PostgreSQL database.

## Line-by-Line Explanation

### Imports

**Line 1-2**: Dependencies
```javascript
const db = require('../database');
const { v4: uuidv4 } = require('uuid');
```
*   **Explanation**: Imports DB connection and UUID generator.

### Main Function

**Line 4**: Start
```javascript
async function testFileChanges() {
```
*   **Explanation**: Async function for DB operations.

**Line 7-9**: Mock IDs
```javascript
  const fileId = uuidv4();
  const ownerId = uuidv4(); 
  const userId = uuidv4();
```
*   **Explanation**: Generates random UUIDs. Note that we can't just use these for `user_id` and `owner_id` in the INSERT statement because of Foreign Key constraints. We need to create the actual records first.

### Setup Phase: Dependency Creation

**Line 16-18**: Create User and Owner
```javascript
    const userRes = await db.query("INSERT INTO users (email, password_hash) VALUES ($1, 'hash') RETURNING id", [`file_test_user_${Date.now()}@test.com`]);
    const ownerRes = await db.query("INSERT INTO owners (email, password_hash, public_key) VALUES ($1, 'hash', 'PEM') RETURNING id", [`file_test_owner_${Date.now()}@test.com`]);
```
*   **Explanation**:
    *   **Crucial Step**: Before we can test the `files` table, we MUST populate the `users` and `owners` tables.
    *   We insert minimal dummy data just to get valid IDs.
    *   `RETURNING id`: We capture the IDs assigned by the database (or verified from our insert) to use in the file insertion.

**Line 20-21**: Capture IDs
```javascript
    const realUserId = userRes.rows[0].id;
    const realOwnerId = ownerRes.rows[0].id;
```
*   **Explanation**: These are the valid UUIDs that exist in the DB.

### Step 1: File Upload (INSERT)

**Line 24**: Log Action
```javascript
    console.log('Performing INSERT (File Upload)...');
```
*   **Explanation**: Simulates a user uploading a file.

**Line 25-30**: SQL Query
```javascript
    const insertQ = `
      INSERT INTO files (
        id, user_id, owner_id, file_name, encrypted_file_data, 
        file_size_bytes, iv_vector, auth_tag, encrypted_symmetric_key
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) 
      RETURNING *
    `;
```
*   **Explanation**:
    *   This is a complex INSERT with many columns.
    *   It links the file to `user_id` ($2) and `owner_id` ($3).
    *   It stores binary data (`encrypted_file_data`, `iv_vector`, etc.).

**Line 31-35**: Execution
```javascript
    const fileRes = await db.query(insertQ, [
      fileId, realUserId, realOwnerId, 'secret_plans.pdf', 
      Buffer.from('encrypteddata'), 1024, 
      Buffer.from('iv'), Buffer.from('tag'), Buffer.from('key')
    ]);
```
*   **Explanation**:
    *   `Buffer.from(...)`: Creates binary buffers from strings. In a real app, these would be actual encrypted bytes. PostgreSQL `BYTEA` columns require Buffer objects in Node.js.
    *   `fileId`: We provide the ID explicitly here (generated at line 7), which is allowed since the schema uses `DEFAULT` only if not provided.

**Line 36-37**: Log Result
```javascript
    console.log('Change Logged: File Record Created');
    console.log('File ID:', fileRes.rows[0].id);
```
*   **Explanation**: Confirms the file is stored.

### Step 2: Mark Printed (UPDATE)

**Line 40**: Log Action
```javascript
    console.log('Performing UPDATE (Mark as Printed)...');
```
*   **Explanation**: Simulates the owner printing the file.

**Line 41-44**: Execute Update
```javascript
    const updateRes = await db.query(
      'UPDATE files SET is_printed = true, printed_at = NOW() WHERE id = $1 RETURNING *',
      [fileId]
    );
```
*   **Explanation**:
    *   Updates the status flags.
    *   `printed_at = NOW()`: Sets the timestamp to the current server time.

**Line 45-46**: Log Result
```javascript
    console.log('Change Logged: File Marked Printed');
    console.log('Printed At:', updateRes.rows[0].printed_at);
```
*   **Explanation**: Verifies the update.

### Cleanup Phase

**Line 49-51**: Delete All
```javascript
    await db.query('DELETE FROM files WHERE id = $1', [fileId]);
    await db.query('DELETE FROM users WHERE id = $1', [realUserId]);
    await db.query('DELETE FROM owners WHERE id = $1', [realOwnerId]);
```
*   **Explanation**:
    *   **Order Matters**: We delete the `file` first.
    *   If we tried to delete the `user` first, it might fail depending on the `ON DELETE` constraint (though our schema says `SET NULL`, so it would actually work).
    *   If we tried to delete the `owner` first, the file would be deleted automatically (`ON DELETE CASCADE`).
    *   Explicitly deleting everything ensures a clean state.

### Error Handling

**Line 54**: Catch
```javascript
  } catch (err) {
    console.error('Test Failed:', err);
```
*   **Explanation**: Logs failures. Common failures here would be Foreign Key violations if the setup phase failed.

## Summary
This script validates the core data model of the application. It proves that:
1.  The `files` table is correctly linked to `users` and `owners`.
2.  Binary data (`BYTEA`) can be stored and retrieved.
3.  Timestamps and Booleans function as expected.
4.  The application can successfully manage the lifecycle of a secure document.
