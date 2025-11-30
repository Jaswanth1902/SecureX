# Detailed Analysis: database/schema.sql

## File Information
- **Path**: `backend/database/schema.sql`
- **Type**: SQL Script
- **Dialect**: PostgreSQL

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This file defines the structure (schema) of the database. It creates the tables, relationships (foreign keys), and indexes required by the application. It uses `IF NOT EXISTS` to ensure it can be run safely on an existing database without errors.

## Line-by-Line Explanation

### Extensions

**Line 6**: UUID Extension
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```
*   **Explanation**: Enables the `uuid-ossp` extension.
    *   **Why**: PostgreSQL doesn't generate UUID v4 by default. This extension provides the `uuid_generate_v4()` function. We use UUIDs instead of Integers for IDs to avoid enumeration attacks (guessing IDs like 1, 2, 3).

### 1. Users Table

**Line 10-17**: Definition
```sql
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```
*   **Explanation**:
    *   `id`: Primary Key. Automatically generates a random UUID.
    *   `email`: Must be unique. Used for login.
    *   `password_hash`: Stores the bcrypt hash, not the password.
    *   `TIMESTAMP WITH TIME ZONE`: Best practice for storing time. Stores as UTC but handles timezones correctly.

### 2. Owners Table

**Line 21-29**: Definition
```sql
CREATE TABLE IF NOT EXISTS owners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    public_key TEXT NOT NULL, -- RSA Public Key (PEM format)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```
*   **Explanation**: Similar to users, but adds `public_key`.
    *   `public_key TEXT`: Stores the RSA Public Key in PEM format (starts with `-----BEGIN PUBLIC KEY-----`). This is used by users to encrypt files for this owner.

### 3. Files Table

**Line 33-49**: Definition
```sql
CREATE TABLE IF NOT EXISTS files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    encrypted_file_data BYTEA NOT NULL, -- Encrypted file content
    file_size_bytes BIGINT NOT NULL,
    file_mime_type VARCHAR(100) DEFAULT 'application/octet-stream',
    iv_vector BYTEA NOT NULL, -- Initialization Vector for AES
    auth_tag BYTEA NOT NULL, -- Authentication Tag for AES-GCM
    encrypted_symmetric_key BYTEA NOT NULL, -- AES key encrypted with Owner's Public RSA Key
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_printed BOOLEAN DEFAULT FALSE,
    printed_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE
);
```
*   **Explanation**:
    *   `user_id`: Foreign Key to `users`. `ON DELETE SET NULL` means if a user is deleted, their files remain (but unlinked).
    *   `owner_id`: Foreign Key to `owners`. `ON DELETE CASCADE` means if an owner is deleted, all files waiting for them are deleted too.
    *   `encrypted_file_data BYTEA`: Stores the binary blob of the encrypted file.
    *   `iv_vector`, `auth_tag`: Essential metadata for AES decryption.
    *   `encrypted_symmetric_key`: The AES key, encrypted with the owner's RSA key.
    *   `is_deleted`: Soft delete flag.

### 4. Sessions Table

**Line 53-68**: Definition
```sql
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    owner_id UUID REFERENCES owners(id) ON DELETE CASCADE,
    token_hash VARCHAR(64) NOT NULL, -- Hash of access token
    refresh_token_hash VARCHAR(64) NOT NULL, -- Hash of refresh token
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    refresh_expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_valid BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP WITH TIME ZONE,
    -- Ensure either user_id or owner_id is set, but not both (optional constraint)
    CONSTRAINT check_user_or_owner CHECK (
        (user_id IS NOT NULL AND owner_id IS NULL) OR 
        (user_id IS NULL AND owner_id IS NOT NULL)
    )
);
```
*   **Explanation**:
    *   Stores active sessions.
    *   `token_hash`: We store SHA-256 hashes (64 hex chars) of the tokens, not the tokens themselves.
    *   `check_user_or_owner`: A Check Constraint. Ensures a session belongs to EITHER a user OR an owner, preventing logic errors.

### Indexes

**Line 71-73**: Performance Optimization
```sql
CREATE INDEX IF NOT EXISTS idx_files_owner_id ON files(owner_id);
CREATE INDEX IF NOT EXISTS idx_files_user_id ON files(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_refresh_hash ON sessions(refresh_token_hash);
```
*   **Explanation**:
    *   `idx_files_owner_id`: Speeds up "Show me all files for Owner X".
    *   `idx_sessions_refresh_hash`: Speeds up "Verify this refresh token" (which looks up by hash).

## Summary
This schema provides a solid foundation for the application. It enforces data integrity through Foreign Keys and Check Constraints, ensures security through token hashing, and optimizes performance with Indexes.
