# Services & Business Logic (MobileF1)

**Tag**: `MobileF1`

## 1. ApiService (`api_service.dart`)
Handles all HTTP communication with the Flask backend.
- **Base URL**: `http://10.117.97.65:5000` (Hardcoded IP - needs to be configurable).
- **Methods**:
  - `loginUser`: POST `/api/auth/login`
  - `getOwnerPublicKey`: GET `/api/owners/public-key/{id}`
  - `uploadFile`: POST `/api/upload` (Multipart request)
  - `listFiles`: GET `/api/files`
  - `getFileForPrinting`: GET `/api/print/{id}`
  - `deleteFile`: POST `/api/delete/{id}`
- **Error Handling**: Throws `ApiException` with status codes.

## 2. EncryptionService (`encryption_service.dart`)
Handles all cryptographic operations.
- **AES-256-GCM**:
  - Uses `package:cryptography`.
  - `generateAES256Key()`: Generates 32-byte secure random key.
  - `encryptFileAES256()`: Encrypts data, returns ciphertext, IV (12 bytes), and Auth Tag.
  - `decryptFileAES256()`: Decrypts data (used for verification).
- **RSA-2048-OAEP**:
  - Uses `package:encrypt` and `pointycastle`.
  - `encryptSymmetricKeyRSA()`: Encrypts the 32-byte AES key using the Owner's RSA Public Key (PEM format).
- **Utilities**:
  - `hashFileSHA256()`: Generates file hash.
  - `shredData()`: Overwrites memory for security.

## 3. UserService (`user_service.dart`)
Manages local user session.
- **Storage**: Uses `flutter_secure_storage` for tokens and `shared_preferences` for non-sensitive data.
- **Methods**:
  - `saveTokens()`: Stores Access/Refresh tokens and User ID.
  - `getAccessToken()`: Retrieves valid token.
  - `logout()`: Clears all data.

## 4. PermissionsService (`permissions_service.dart`)
Handles Android/iOS permission requests.
- Uses `permission_handler`.
- Requests `storage`, `manageExternalStorage` (Android 11+), etc.
