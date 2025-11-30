# Detailed Analysis: database.js

## File Information
- **Path**: `backend/database.js`
- **Type**: Database Configuration
- **Language**: JavaScript (Node.js)
- **Library**: `pg` (node-postgres)

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This file is responsible for establishing and managing the connection to the PostgreSQL database. Instead of opening a new connection for every single query (which is slow and resource-intensive), it uses a **Connection Pool**. A pool maintains a set of open connections that can be reused, significantly improving performance for high-traffic applications.

## Line-by-Line Explanation

### Imports

**Line 6**: Import Pool
```javascript
const { Pool } = require('pg');
```
*   **Explanation**:
    *   `require('pg')`: Imports the `node-postgres` library, which is the standard PostgreSQL client for Node.js.
    *   `{ Pool }`: Destructures the `Pool` class from the library. The `Pool` class is the main mechanism we use to manage connections.

**Line 7**: Load Environment Variables
```javascript
require('dotenv').config();
```
*   **Explanation**: Ensures that environment variables (like DB password) are loaded from the `.env` file before we try to use them.

### Pool Configuration

**Line 10-19**: Create Pool Instance
```javascript
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'secure_print',
  max: 20,                    // Max connections in pool
  idleTimeoutMillis: 30000,   // Close idle connections after 30s
  connectionTimeoutMillis: 2000, // Timeout for connection attempt
});
```
*   **Explanation**:
    *   `new Pool({...})`: Creates a new instance of the connection pool with the specified configuration.
    *   **Connection Details**:
        *   `user`: The database username. Defaults to 'postgres'.
        *   `password`: The database password. Defaults to 'postgres'.
        *   `host`: The server address. Defaults to 'localhost'. In Docker, this would be the service name (e.g., 'postgres').
        *   `port`: The database port. Standard PostgreSQL port is 5432.
        *   `database`: The name of the specific database to connect to.
    *   **Pool Settings**:
        *   `max: 20`: The maximum number of clients the pool should contain. If 20 clients are busy running queries, the 21st request will wait until one is freed. This prevents overwhelming the database server.
        *   `idleTimeoutMillis: 30000`: If a connection sits unused for 30 seconds, it is closed to save resources.
        *   `connectionTimeoutMillis: 2000`: If the application cannot connect to the database within 2 seconds (e.g., network issue), it will throw an error.

### Event Listeners

**Line 22-24**: Connect Event
```javascript
pool.on('connect', () => {
  console.log('✅ Database pool connected');
});
```
*   **Explanation**:
    *   `pool.on('connect', ...)`: Adds an event listener.
    *   This callback runs whenever a *new* client is created and added to the pool. It's helpful for debugging to see when the pool is growing.

**Line 27-29**: Error Event
```javascript
pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client', err);
});
```
*   **Explanation**:
    *   `pool.on('error', ...)`: This is critical. It catches errors that happen on idle clients in the pool (e.g., if the database server restarts or the network drops).
    *   Without this listener, an error on an idle client could crash the entire Node.js process.

### Exports

**Line 32-35**: Module Exports
```javascript
module.exports = {
  query: (text, params) => pool.query(text, params),
  pool: pool,
};
```
*   **Explanation**:
    *   We export an object with two properties.
    *   `query`: This is a wrapper function.
        *   `text`: The SQL query string (e.g., `SELECT * FROM users WHERE id = $1`).
        *   `params`: An array of values to substitute into the query (e.g., `[userId]`).
        *   `pool.query(text, params)`: This method automatically acquires a client from the pool, executes the query, and releases the client back to the pool. This is the preferred way to run single queries.
    *   `pool`: We also export the raw pool instance. This is useful if we need to manually acquire a client (e.g., for running a transaction with `BEGIN`, `COMMIT`, `ROLLBACK`).

## Why PostgreSQL?
This project uses PostgreSQL because:
1.  **Reliability**: It is ACID compliant, ensuring data integrity.
2.  **Security**: It has robust role-based access control.
3.  **Features**: It supports advanced data types like JSONB and Arrays, and has powerful indexing capabilities.
4.  **Scalability**: It handles concurrent connections much better than SQLite.

## Usage Example
In other files, you will see code like this:
```javascript
const db = require('../database');

// Execute a query
const result = await db.query('SELECT * FROM users WHERE id = $1', [userId]);
const user = result.rows[0];
```
This simple API hides the complexity of connection management from the rest of the application.
