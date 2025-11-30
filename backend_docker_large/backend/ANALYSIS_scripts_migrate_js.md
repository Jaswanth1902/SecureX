# Detailed Analysis: scripts/migrate.js

## File Information
- **Path**: `backend/scripts/migrate.js`
- **Type**: Utility Script
- **Function**: Database Migration Runner

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This script is responsible for setting up the database schema. It reads the SQL commands from `database/schema.sql` and executes them against the configured PostgreSQL database. It is designed to be idempotent (safe to run multiple times) by using `IF NOT EXISTS` clauses in the SQL.

## Line-by-Line Explanation

### Imports

**Line 1-4**: Dependencies
```javascript
const fs = require("fs");
const path = require("path");
const { Pool } = require("pg");
require("dotenv").config();
```
*   **Explanation**:
    *   `fs`: File system module to read the SQL file.
    *   `path`: Module to handle file paths correctly across OSs.
    *   `pg`: PostgreSQL client.
    *   `dotenv`: Loads DB credentials.

### Main Function

**Line 6**: Async Function
```javascript
async function runMigrations() {
```
*   **Explanation**: We use an async function to use `await` for database operations.

**Line 7-14**: Pool Setup
```javascript
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    user: process.env.DB_USER,
    // ...
  });
```
*   **Explanation**: Creates a temporary connection pool just for this script. It supports both a full connection string (`DATABASE_URL`) or individual parameters.

**Line 16**: Connect
```javascript
  const client = await pool.connect();
```
*   **Explanation**: Acquires a single client from the pool.

### Reading Schema

**Line 19-25**: Path Resolution
```javascript
    const schemaPath = path.join(
      __dirname,
      "..",
      "..",
      "database",
      "schema.sql"
    );
```
*   **Explanation**: Constructs the absolute path to the schema file. `__dirname` is the directory of the script (`backend/scripts`). We go up two levels to root, then into `database`.

**Line 26**: Read File
```javascript
    const sql = fs.readFileSync(schemaPath, "utf8");
```
*   **Explanation**: Reads the entire content of `schema.sql` into a string.

### Transaction Management

**Line 31**: Begin Transaction
```javascript
    await client.query('BEGIN');
```
*   **Explanation**: Starts a SQL transaction.
    *   **Why**: Migrations should be atomic. Either everything succeeds, or nothing happens. We don't want a half-created database if the script crashes halfway through.

**Line 33**: Execute SQL
```javascript
      await client.query(sql);
```
*   **Explanation**: Sends the entire SQL string to the database. PostgreSQL supports executing multiple statements in a single query string.

**Line 34**: Commit
```javascript
      await client.query('COMMIT');
```
*   **Explanation**: If the query succeeded, we commit the transaction. The changes are now permanent.

**Line 36-46**: Error Handling & Rollback
```javascript
    } catch (txError) {
      try {
        await client.query('ROLLBACK');
        console.error('Transaction rolled back due to error.');
      } catch (rbError) { ... }
      throw txError;
    }
```
*   **Explanation**:
    *   If any error occurs (e.g., syntax error in SQL), we catch it.
    *   `ROLLBACK`: We undo any changes made since `BEGIN`. The database is left exactly as it was before we started.
    *   `throw txError`: We re-throw the error so the outer catch block sees it.

### Cleanup

**Line 47-50**: Global Error Handler
```javascript
  } catch (error) {
    console.error("✗ Migration failed:", error);
    process.exitCode = 1;
  }
```
*   **Explanation**: Logs the error and sets the exit code to 1 (failure). This tells CI/CD pipelines that the migration failed.

**Line 51-52**: Resource Release
```javascript
  } finally {
    client.release();
    await pool.end();
  }
```
*   **Explanation**:
    *   `client.release()`: Returns the client to the pool.
    *   `pool.end()`: Closes the pool and all connections. This allows the Node.js process to exit gracefully.

**Line 56**: Execution
```javascript
runMigrations();
```
*   **Explanation**: Calls the function to start the process.

## Summary
This script is a critical operational tool. It ensures the database schema matches what the code expects. By using transactions, it ensures reliability and prevents data corruption during updates.
