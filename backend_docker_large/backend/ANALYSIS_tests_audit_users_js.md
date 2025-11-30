# Detailed Analysis: tests/audit_users.js

## File Information
- **Path**: `backend/tests/audit_users.js`
- **Type**: Integration Test / Audit Script
- **Function**: Verification of User Lifecycle Events

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This script serves as a verification tool for the `users` table in the PostgreSQL database. It simulates the lifecycle of a user account—Creation, Update, and Deletion—and logs the state changes to the console. This is crucial for verifying that the database schema is correct and that the application can successfully read and write user data.

In a production environment, similar logic would be used in the `AuthService` to manage users. This script isolates that logic for testing purposes.

## Line-by-Line Explanation

### Imports and Setup

**Line 1**: Database Connection
```javascript
const db = require('../database');
```
*   **Explanation**: Imports the shared database module. This ensures the test uses the *exact same* connection pool configuration as the main application. If the app works, this test should work. If this test fails, the app will likely fail too.

**Line 2**: UUID Generation
```javascript
const { v4: uuidv4 } = require('uuid');
```
*   **Explanation**: Imports the UUID library. Although the database generates UUIDs automatically (via `DEFAULT uuid_generate_v4()`), we might need to generate them client-side in some tests. In this specific script, we rely on the DB to generate the ID, but having the library available is standard practice.

### Main Function

**Line 4**: Function Definition
```javascript
async function testUserChanges() {
```
*   **Explanation**: Defined as `async` to allow the use of `await`. Database operations are asynchronous network calls.

**Line 5**: Start Log
```javascript
  console.log('--- Starting User Audit Test ---');
```
*   **Explanation**: clear delimiter in the logs.

**Line 7-8**: Test Data Setup
```javascript
  const testEmail = `audit_test_${Date.now()}@example.com`;
  const testPasswordHash = 'hashed_secret';
```
*   **Explanation**:
    *   `testEmail`: Generates a unique email using the current timestamp (`Date.now()`). This prevents "Unique Constraint" errors if we run the test multiple times.
    *   `testPasswordHash`: Uses a dummy hash. In a real app, this would be a bcrypt hash. For this DB test, any string fits the `VARCHAR` column.

### Step 1: Initial State Check

**Line 11-13**: Pre-flight Check
```javascript
    console.log(`Checking if user ${testEmail} exists...`);
    const check1 = await db.query('SELECT * FROM users WHERE email = $1', [testEmail]);
    console.log('Initial State:', check1.rows.length ? 'User exists' : 'User does not exist');
```
*   **Explanation**:
    *   **Query**: Selects from `users` looking for our test email.
    *   **Expectation**: Should return 0 rows.
    *   **Purpose**: Verifies that we are starting with a clean slate for this specific user identity.

### Step 2: Create User (INSERT)

**Line 16**: Log Action
```javascript
    console.log('Performing INSERT...');
```
*   **Explanation**: Audit log indicating the start of a write operation.

**Line 17-20**: Execute Insert
```javascript
    const insertRes = await db.query(
      'INSERT INTO users (email, password_hash, full_name) VALUES ($1, $2, $3) RETURNING *',
      [testEmail, testPasswordHash, 'Audit Test User']
    );
```
*   **Explanation**:
    *   **SQL**: Standard `INSERT` statement.
    *   **Parameters**: Uses `$1, $2, $3` placeholders for security (prevents SQL injection).
    *   **RETURNING ***: This is a powerful PostgreSQL feature. It returns the data that was just inserted, including auto-generated fields like `id` and `created_at`. This saves us from having to do a separate `SELECT` immediately after.

**Line 21-23**: Log Result
```javascript
    const newUser = insertRes.rows[0];
    console.log('Change Logged: User Created');
    console.log('New Record:', JSON.stringify(newUser, null, 2));
```
*   **Explanation**:
    *   `insertRes.rows[0]`: The first (and only) row returned.
    *   `JSON.stringify`: Pretty-prints the user object. This allows us to visually verify that fields like `id` (UUID) and `created_at` (Timestamp) were generated correctly by the database.

### Step 3: Update User (UPDATE)

**Line 26**: Log Action
```javascript
    console.log('Performing UPDATE (Changing name)...');
```
*   **Explanation**: Testing the ability to modify existing records.

**Line 27-30**: Execute Update
```javascript
    const updateRes = await db.query(
      'UPDATE users SET full_name = $1 WHERE email = $2 RETURNING *',
      ['Updated Audit Name', testEmail]
    );
```
*   **Explanation**:
    *   **SQL**: Updates the `full_name` column.
    *   **Condition**: `WHERE email = $2`. Identifies the row to update.
    *   **RETURNING ***: Again, returns the *new* state of the row after the update.

**Line 31-34**: Log Change
```javascript
    const updatedUser = updateRes.rows[0];
    console.log('Change Logged: User Updated');
    console.log('Old Name:', newUser.full_name);
    console.log('New Name:', updatedUser.full_name);
```
*   **Explanation**:
    *   Compares the old name (from Step 2) with the new name (from Step 3).
    *   **Verification**: This proves the database state actually changed.

### Step 4: Delete User (DELETE)

**Line 37**: Log Action
```javascript
    console.log('Performing DELETE...');
```
*   **Explanation**: Cleanup phase.

**Line 38**: Execute Delete
```javascript
    await db.query('DELETE FROM users WHERE email = $1', [testEmail]);
```
*   **Explanation**:
    *   **SQL**: Removes the row.
    *   **Importance**: Leaving test data in a database ("pollution") is bad practice. It can confuse developers and affect future tests. We always try to clean up.

**Line 39**: Log Completion
```javascript
    console.log('Change Logged: User Deleted');
```
*   **Explanation**: Confirms the action completed without error.

### Error Handling and Cleanup

**Line 41-42**: Catch Block
```javascript
  } catch (err) {
    console.error('Test Failed:', err);
```
*   **Explanation**: If any SQL command fails (e.g., connection lost, syntax error, constraint violation), execution jumps here. The error is logged to stderr.

**Line 43-47**: Finally Block
```javascript
  } finally {
    console.log('--- User Audit Test Complete ---');
    process.exit(0);
  }
```
*   **Explanation**:
    *   `finally`: Runs whether the test succeeded or failed.
    *   `process.exit(0)`: Forces the Node.js process to terminate. This is important because the database pool might keep the process alive waiting for new connections.

**Line 51-53**: Execution Check
```javascript
if (require.main === module) {
  testUserChanges();
}
```
*   **Explanation**: Allows the script to be run directly (`node audit_users.js`) or imported by a test runner.

## Summary
This script demonstrates the fundamental CRUD (Create, Read, Update, Delete) operations for the `users` entity. It confirms that:
1.  The `users` table exists.
2.  The columns (`email`, `password_hash`, `full_name`) match the schema.
3.  Constraints (Unique Email) are respected (implied by the use of unique emails).
4.  Auto-generation of UUIDs works.
