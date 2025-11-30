-- =============================================
-- Secure File Printing System - Database Schema
-- =============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS TABLE
-- Stores end-users who upload files
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. OWNERS TABLE
-- Stores print shop owners who receive files
CREATE TABLE IF NOT EXISTS owners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    public_key TEXT NOT NULL, -- RSA Public Key (PEM format)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. FILES TABLE
-- Stores encrypted file metadata and content
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

-- 4. SESSIONS TABLE
-- Stores refresh tokens for auth management
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

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_files_owner_id ON files(owner_id);
CREATE INDEX IF NOT EXISTS idx_files_user_id ON files(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_refresh_hash ON sessions(refresh_token_hash);
