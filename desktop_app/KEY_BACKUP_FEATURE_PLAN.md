# Key Backup & Restore Feature - Implementation Plan

> **Status**: Saved for future implementation
> **Created**: 2026-01-16

## Problem
When a user logs in on a new device or reinstalls the app, a new RSA key pair is generated. Files encrypted with the old public key become permanently undecryptable.

## Solution
Implement a secure key backup/restore system that allows users to export and import their private key.

---

## Proposed Changes

### Desktop App

#### [NEW] `lib/screens/settings/key_backup_screen.dart`
- UI for exporting and importing private key.
- Shows current key fingerprint for verification.
- Provides "Export Key" and "Import Key" buttons.

#### [MODIFY] `lib/services/key_service.dart`
Add two methods:
1. `exportKeyToFile(String password, String filePath)` - Encrypts private key with user password and saves to file.
2. `importKeyFromFile(String password, String filePath)` - Decrypts and restores private key from backup file.

#### [MODIFY] `lib/screens/settings_screen.dart`
Add navigation to Key Backup Screen under "Security" section.

---

## Implementation Details

### Key Export Flow
1. User navigates to Settings → Security → Backup Key
2. User enters a strong password (min 8 chars)
3. Private key JSON is encrypted with AES-256 using password-derived key (PBKDF2)
4. Encrypted blob is saved to user-chosen file location (`.safecopy-key`)
5. Show success message with reminder to store securely

### Key Import Flow
1. User selects "Import Key" and picks `.safecopy-key` file
2. User enters the password used during export
3. App decrypts and validates the key
4. If valid: replace local key, sync public key to server
5. If invalid: show error, do not modify anything

### Security Considerations
- Use PBKDF2 with 100,000 iterations for key derivation
- Salt is randomly generated and stored with the backup
- File format: JSON `{version, salt, iv, encrypted_data}`

---

## Verification Plan

### Manual Testing
1. Create a new account, upload a file via mobile
2. Export the key to a backup file
3. Clear app data or login on a new device
4. Try to print the file → Should fail (key mismatch)
5. Import the backup key
6. Try to print the file → Should succeed
