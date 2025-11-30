# Detailed Analysis: tests/audit_owners.js

## File Information
- **Path**: `backend/tests/audit_owners.js`
- **Type**: Integration Test / Audit Script
- **Function**: Verification of Owner Management

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This script verifies the `owners` table. Owners are a distinct entity from Users in this system. They represent the Print Shops. The critical piece of data for an owner is their **Public Key**, which is stored as a `TEXT` field. This script ensures that we can store and update this key, which is essential for the encryption scheme to work.

## Line-by-Line Explanation

### Imports

**Line 1**: Database
```javascript
const db = require('../database');
```
*   **Explanation**: Imports the DB connection.

### Main Function

**Line 3**: Start
```javascript
async function testOwnerChanges() {
```
*   **Explanation**: Async entry point.

**Line 6**: Test Data
```javascript
  const testEmail = `owner_audit_${Date.now()}@example.com`;
```
*   **Explanation**: Generates a unique email for the test run.

### Step 1: Register Owner (INSERT)

**Line 10**: Log Action
```javascript
    console.log('Performing INSERT (Owner Registration)...');
```
*   **Explanation**: Simulates owner registration.

**Line 11-14**: Execute Insert
```javascript
    const insertRes = await db.query(
      'INSERT INTO owners (email, password_hash, full_name, public_key) VALUES ($1, $2, $3, $4) RETURNING *',
      [testEmail, 'hash_123', 'Test Owner Shop', '-----BEGIN PUBLIC KEY-----\nMOCK_KEY\n-----END PUBLIC KEY-----']
    );
```
*   **Explanation**:
    *   **Public Key**: We insert a string that looks like a PEM key. In a real app, this would be a much longer string (RSA-2048 is about 450 characters). PostgreSQL `TEXT` type handles this easily (up to 1GB).
    *   **RETURNING ***: Returns the created owner record.

**Line 15-17**: Log Result
```javascript
    const newOwner = insertRes.rows[0];
    console.log('Change Logged: Owner Registered');
    console.log('Owner ID:', newOwner.id);
```
*   **Explanation**: Verifies the ID was generated.

### Step 2: Rotate Key (UPDATE)

**Line 20**: Log Action
```javascript
    console.log('Performing UPDATE (Rotate Key)...');
```
*   **Explanation**: Simulates a key rotation. If an owner loses their private key or it is compromised, they need to upload a new public key.

**Line 21-24**: Execute Update
```javascript
    const updateRes = await db.query(
      'UPDATE owners SET public_key = $1 WHERE id = $2 RETURNING *',
      ['-----BEGIN PUBLIC KEY-----\nNEW_MOCK_KEY\n-----END PUBLIC KEY-----', newOwner.id]
    );
```
*   **Explanation**:
    *   Updates the `public_key` column for the specific owner.
    *   This confirms that the `TEXT` column is mutable and can handle updates.

**Line 25-26**: Log Result
```javascript
    console.log('Change Logged: Public Key Rotated');
    console.log('New Key:', updateRes.rows[0].public_key);
```
*   **Explanation**: Verifies the key was updated.

### Cleanup

**Line 29**: Delete
```javascript
    await db.query('DELETE FROM owners WHERE id = $1', [newOwner.id]);
```
*   **Explanation**: Removes the test record.

**Line 30**: Log
```javascript
    console.log('Cleanup Complete');
```
*   **Explanation**: Done.

### Error Handling

**Line 32**: Catch
```javascript
  } catch (err) {
    console.error('Test Failed:', err);
```
*   **Explanation**: Logs any errors.

## Summary
This script confirms that the `owners` table is correctly configured to support the application's PKI (Public Key Infrastructure) requirements. It verifies that:
1.  Owners can be created with a Public Key.
2.  The Public Key can be retrieved and updated.
3.  The database handles the `TEXT` data type correctly for keys.
