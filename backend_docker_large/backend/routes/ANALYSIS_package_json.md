# Detailed Analysis: package.json

## File Information
- **Path**: `backend/package.json`
- **Type**: Node.js Manifest
- **Format**: JSON

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
The `package.json` file is the heart of any Node.js project. It contains metadata about the project (name, version, description) and, most importantly, the list of dependencies (libraries) that the project needs to run. It also defines "scripts" which are shortcuts for running common commands like starting the server or running tests.

## Line-by-Line Explanation

**Line 1-5**: Metadata
```json
{
  "name": "secure-print-backend",
  "version": "1.0.0",
  "description": "Backend API server for Secure File Printing System",
  "main": "server.js",
```
*   **Explanation**:
    *   `name`: The unique name of the package.
    *   `version`: The current version (Semantic Versioning).
    *   `main`: The entry point of the application. When someone runs `node .`, this is the file that gets executed.

**Line 6-15**: Scripts
```json
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest --coverage",
    "test:watch": "jest --watch",
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "migrate": "node scripts/migrate.js",
    "seed": "node scripts/seed.js"
  },
```
*   **Explanation**:
    *   `start`: The command to run in production. `npm start` runs `node server.js`.
    *   `dev`: The command for development. Uses `nodemon` to automatically restart the server whenever you save a file.
    *   `test`: Runs the test suite using `jest` and generates a code coverage report.
    *   `lint`: Runs `eslint` to check for code style and potential errors.
    *   `migrate`: Runs the custom migration script to update the database schema.

**Line 24-37**: Dependencies (Production)
```json
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "compression": "^1.7.4",
    "cors": "^2.8.5",
    "crypto-js": "^4.2.0",
    "dotenv": "^16.0.3",
    "express": "^4.18.2",
    "helmet": "^7.0.0",
    "jsonwebtoken": "^9.0.0",
    "morgan": "^1.10.0",
    "multer": "^1.4.5-lts.1",
    "pg": "^8.9.0",
    "uuid": "^9.0.0"
  },
```
*   **Explanation**: These are the libraries required for the application to run in production.
    *   `bcryptjs`: Used for hashing passwords securely. We never store plain text passwords.
    *   `compression`: Middleware to compress HTTP responses (gzip).
    *   `cors`: Middleware to handle Cross-Origin Resource Sharing.
    *   `crypto-js`: Library for standard crypto algorithms (AES, SHA).
    *   `dotenv`: Loads environment variables from `.env` file.
    *   `express`: The web framework.
    *   `helmet`: Security middleware for HTTP headers.
    *   `jsonwebtoken`: Used to generate and verify JWTs for authentication.
    *   `morgan`: HTTP request logger.
    *   `multer`: Middleware for handling `multipart/form-data`, primarily used for uploading files.
    *   `pg`: The PostgreSQL client for Node.js. **This confirms the project uses PostgreSQL.**
    *   `uuid`: Used to generate unique identifiers (UUID v4) for database records.

**Line 38-43**: Dev Dependencies
```json
  "devDependencies": {
    "eslint": "^8.40.0",
    "jest": "^29.5.0",
    "nodemon": "^3.1.11",
    "supertest": "^6.3.3"
  },
```
*   **Explanation**: These libraries are only needed for development and testing. They are not installed in the production Docker image (see Dockerfile).
    *   `eslint`: Linter.
    *   `jest`: Testing framework.
    *   `nodemon`: Development server with auto-restart.
    *   `supertest`: Library for testing HTTP endpoints.

**Line 44-47**: Engines
```json
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=8.0.0"
  }
```
*   **Explanation**: Specifies the required versions of Node.js and npm. This prevents the application from being deployed on an old, unsupported runtime.

## Key Takeaways
1.  **PostgreSQL**: The presence of `pg` dependency confirms the database choice.
2.  **Security**: Dependencies like `helmet`, `bcryptjs`, and `jsonwebtoken` show a focus on security best practices.
3.  **Modern Stack**: Uses modern Node.js (v18+) and standard tools (Jest, ESLint).
