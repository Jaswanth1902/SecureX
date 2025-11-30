# SafeCopy - Secure File Printing System

## Overview
SafeCopy is a secure file transfer and printing system designed to allow users to securely send documents to print shop owners without exposing the files to intermediaries or unauthorized access. The system uses end-to-end encryption to ensure that only the intended recipient (the print shop owner) can decrypt and view the files.

## Key Features
- **End-to-End Encryption**: Files are encrypted on the client side using AES-256-GCM before being uploaded.
- **Secure Key Exchange**: The symmetric encryption key is encrypted using the owner's public RSA key.
- **Zero-Knowledge Server**: The server stores only encrypted data and does not have access to the decryption keys.
- **Ephemeral Storage**: Files are intended to be printed and then immediately deleted from the system.

## Architecture
The system consists of three main components:
1. **Mobile App (Client)**: Allows users to select files, encrypt them, and upload them to the server.
2. **Backend API**: A Node.js/Express server that handles user authentication, file storage, and metadata management.
3. **Desktop App (Owner)**: A desktop application for print shop owners to download, decrypt, and print files.

## Security Model
1. **User Upload**:
   - Client generates a random AES-256 key.
   - File is encrypted with this key.
   - AES key is encrypted with the Owner's Public Key.
   - Encrypted file + Encrypted Key + Metadata are sent to the server.

2. **Server Storage**:
   - Server stores the encrypted blob and metadata in PostgreSQL.
   - Server performs authentication checks (JWT) but cannot decrypt the file.

3. **Owner Download**:
   - Owner authenticates and downloads the encrypted package.
   - Owner uses their Private Key (stored locally) to decrypt the AES key.
   - Owner uses the AES key to decrypt the file in memory.
   - File is sent to the printer and then wiped from memory.
