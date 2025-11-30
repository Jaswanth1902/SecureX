# Codebase Explanation

## Directory Structure
- `backend/`: Root directory for the API server.
  - `routes/`: API route definitions.
  - `services/`: Business logic and helper classes.
  - `middleware/`: Express middleware (auth, validation).
  - `database/`: Database configuration and schema.
  - `scripts/`: Utility scripts (migration, seeding).

## Key Components

### 1. Server Entry Point (`server.js`)
- Initializes the Express application.
- Configures middleware (Helmet, CORS, Body Parser).
- Connects to the database.
- Mounts API routes.
- Starts the HTTP server.

### 2. Authentication (`routes/auth.js`, `services/authService.js`)
- **Registration**: Creates new user accounts with hashed passwords (bcrypt).
- **Login**: Validates credentials and issues JWT access/refresh tokens.
- **Token Management**: Handles token refresh and revocation.
- **Session Tracking**: Stores active sessions in the database for security.

### 3. File Management (`routes/files.js`)
- **Upload (`POST /api/upload`)**:
  - Accepts encrypted file blobs.
  - Validates metadata (IV, Auth Tag, Encrypted Key).
  - Stores file record in the database.
- **List (`GET /api/files`)**:
  - Returns a list of files available for the authenticated user/owner.
- **Download (`GET /api/print/:id`)**:
  - Allows owners to download the encrypted file package.
  - Enforces ownership checks.
- **Delete (`POST /api/delete/:id`)**:
  - Marks files as printed/deleted after successful printing.

### 4. Owner Management (`routes/owners.js`)
- Handles registration and login for print shop owners.
- **Public Key Storage**: Stores the owner's public RSA key during registration.
- **Key Retrieval**: Exposes an endpoint to fetch an owner's public key for client-side encryption.

### 5. Database (`database.js`)
- Manages the PostgreSQL connection pool.
- Exports a query wrapper for executing SQL commands.

### 6. Encryption Service (`services/encryptionService.js`)
- Provides utilities for:
  - AES-256-GCM encryption/decryption (server-side reference implementation).
  - RSA key pair generation.
  - Key wrapping/unwrapping.
  - **Note**: In production, actual file encryption/decryption happens on the **Client**, not the server. The server code serves as a reference and for validation.
