# Mobile App Overview (MobileF1)

**Tag**: `MobileF1`
**Date**: 2025-11-30
**Version**: 1.0.0+1

## Introduction
The Secure Print User App is a Flutter-based mobile application designed to allow users to securely encrypt and upload files to a central server for printing. It ensures end-to-end encryption where only the designated owner can decrypt and print the files.

## Key Features
- **User Authentication**: Login and Registration using JWT tokens.
- **File Selection**: Pick files (PDF, DOC, images, etc.) from the device storage.
- **Client-Side Encryption**:
  - Files are encrypted using **AES-256-GCM**.
  - The AES key is encrypted using **RSA-2048-OAEP** with the owner's public key.
- **Secure Upload**: Encrypted files and metadata are uploaded to the Flask backend.
- **Owner Selection**: Users can specify which owner (by email/ID) can print the file.
- **Progress Tracking**: Real-time upload progress and status updates.

## Architecture
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Networking**: `http` package with JWT authentication.
- **Encryption**: `cryptography` (AES-GCM), `encrypt` (RSA), `pointycastle`.
- **Storage**: `flutter_secure_storage` (Tokens), `shared_preferences`.

## Project Structure
- `lib/main.dart`: Entry point, app configuration, and main navigation.
- `lib/screens/`: UI screens (Login, Upload, etc.).
- `lib/services/`: Business logic and external communication (API, Encryption).
- `lib/models/`: Data models (if separated).

## Current Status
- **Working**: Login, File Picking, Encryption, Uploading.
- **Placeholder**: Home Page, Jobs Page, Settings Page (UI exists but logic is minimal).
