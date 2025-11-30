# Database Audit Testing Guide

> [!CAUTION]
> **AI AGENT WARNING**
> DO NOT MODIFY THE SCRIPTS IN THIS DIRECTORY.
> ALWAYS USE `run_and_log.js` TO EXECUTE TESTS.
> THESE TESTS ARE VERIFIED BUG-FREE.


This directory contains a suite of standalone scripts designed to verify the integrity and behavior of the PostgreSQL database schema. Each script performs a full lifecycle test (Create, Read, Update, Delete) on a specific entity.

## Prerequisites

1.  **Database Running**: The PostgreSQL database must be up and running.
    *   Docker: `docker-compose up -d postgres`
    *   Local: Ensure your local Postgres service is active.
2.  **Environment Variables**: The scripts load `.env` from the `backend/` directory. Ensure `DATABASE_URL` or individual DB params (`DB_USER`, etc.) are set correctly.

## Running the Tests

You can run these tests individually using Node.js. Navigate to the `backend` directory first.

```bash
cd backend
```

### 1. User Audit
Verifies user creation, profile updates, and deletion.
```bash
node tests/audit_users.js
```

### 2. Owner Audit
Verifies owner registration, public key rotation, and deletion.
```bash
node tests/audit_owners.js
```

### 3. File Audit
Verifies the complex relationship between Users, Owners, and Files. Tests file upload, status updates (printing), and cleanup.
```bash
node tests/audit_files.js
```

### 4. Session Audit
Verifies session creation, token rotation, revocation, and cascade deletion when a user is removed.
```bash
node tests/audit_sessions.js
```

## Troubleshooting

*   **Connection Refused**: Check if the database is running and the port (default 5432) is correct in your `.env` file.
*   **Authentication Failed**: Check `DB_USER` and `DB_PASSWORD`.
*   **Table Not Found**: Run the migrations first: `npm run migrate`.
