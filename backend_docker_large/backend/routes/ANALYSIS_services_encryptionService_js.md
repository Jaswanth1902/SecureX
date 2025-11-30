# Detailed Analysis: services/encryptionService.js

## File Information
- **Path**: `backend/services/encryptionService.js`
- **Type**: Service Layer
- **Function**: Cryptographic Utilities (AES, RSA)

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This file provides a suite of cryptographic functions.
**Important Context**: In the SafeCopy architecture, **encryption happens on the client (Mobile App)** and **decryption happens on the client (Desktop App)**. The server is "Zero Knowledge".
However, this service exists on the server for:
1.  **Reference Implementation**: To document exactly how the clients *should* implement encryption.
2.  **Testing**: To allow the server to simulate a client during integration tests.
3.  **Validation**: To potentially verify the format of uploaded data.

It implements **AES-256-GCM** for file encryption and **RSA-2048-OAEP** for key exchange.

## Line-by-Line Explanation

### Imports

**Line 4**: Crypto
```javascript
const crypto = require('crypto');
```
*   **Explanation**: Uses the built-in Node.js `crypto` module. This wraps OpenSSL, providing industry-standard implementations of algorithms.

### AES Encryption (Symmetric)

**Line 12**: Encrypt File
```javascript
  static encryptFileAES256(fileData) {
```
*   **Explanation**: Encrypts a buffer using AES-256-GCM.

**Line 15-16**: Key/IV Generation
```javascript
      const symmetricKey = crypto.randomBytes(32); // 256-bit key
      const iv = crypto.randomBytes(16); // 128-bit IV
```
*   **Explanation**:
    *   `randomBytes(32)`: Generates a cryptographically strong random 32-byte key. This is the "Session Key".
    *   `randomBytes(16)`: Generates a 12-byte or 16-byte IV. GCM standard is usually 12 bytes (96 bits), but 16 is also common.

**Line 19**: Create Cipher
```javascript
      const cipher = crypto.createCipheriv('aes-256-gcm', symmetricKey, iv);
```
*   **Explanation**: Initializes the AES-256-GCM cipher. GCM (Galois/Counter Mode) is an "Authenticated Encryption" mode. It provides both confidentiality (encryption) and integrity (ensures data hasn't been tampered with).

**Line 22-23**: Encrypt
```javascript
      let encryptedData = cipher.update(fileData, 'utf8', 'hex');
      encryptedData += cipher.final('hex');
```
*   **Explanation**: Processes the data. Note: For very large files, streams should be used instead of buffers to avoid memory issues.

**Line 26**: Auth Tag
```javascript
      const authTag = cipher.getAuthTag();
```
*   **Explanation**: This is the "checksum" or signature of the encrypted data. During decryption, if the data was modified by even one bit, the auth tag check will fail.

### AES Decryption

**Line 47**: Decrypt File
```javascript
  static decryptFileAES256(encryptedData, symmetricKey, iv, authTag) {
```
*   **Explanation**: Reverses the process. Requires all 4 inputs.

**Line 50**: Create Decipher
```javascript
      const decipher = crypto.createDecipheriv('aes-256-gcm', symmetricKey, iv);
```
*   **Explanation**: Initializes decryption.

**Line 53**: Set Auth Tag
```javascript
      decipher.setAuthTag(authTag);
```
*   **Explanation**: **Critical Step**. We tell the decipher what the expected auth tag is.

**Line 56-57**: Decrypt
```javascript
      let decryptedData = decipher.update(encryptedData, 'hex', 'utf8');
      decryptedData += decipher.final('utf8');
```
*   **Explanation**: If the auth tag doesn't match, `decipher.final()` will throw an error. This ensures we never process tampered data.

### RSA Encryption (Asymmetric)

**Line 71**: Encrypt Key
```javascript
  static encryptSymmetricKeyRSA(symmetricKey, publicKeyPEM) {
```
*   **Explanation**: Used to securely share the AES key with the Owner.

**Line 73-80**: Public Encrypt
```javascript
      const encrypted = crypto.publicEncrypt(
        {
          key: publicKeyPEM,
          padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
          oaepHash: 'sha256',
        },
        symmetricKey
      );
```
*   **Explanation**:
    *   `publicEncrypt`: Encrypts data using a Public Key. Only the corresponding Private Key can decrypt it.
    *   `RSA_PKCS1_OAEP_PADDING`: Optimal Asymmetric Encryption Padding. This is the modern, secure padding scheme for RSA. Older schemes like PKCS1_v1_5 are vulnerable to padding oracle attacks.
    *   `oaepHash: 'sha256'`: Uses SHA-256 for the OAEP hashing.

### RSA Decryption

**Line 93**: Decrypt Key
```javascript
  static decryptSymmetricKeyRSA(encryptedSymmetricKey, privateKeyPEM) {
```
*   **Explanation**: Used by the Owner (Desktop App) to recover the AES key.

**Line 95-102**: Private Decrypt
```javascript
      const decrypted = crypto.privateDecrypt(
        {
          key: privateKeyPEM,
          padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
          oaepHash: 'sha256',
        },
        encryptedSymmetricKey
      );
```
*   **Explanation**: Uses the Private Key to decrypt.

### Key Generation

**Line 113**: Generate Pair
```javascript
  static async generateRSAKeyPair() {
```
*   **Explanation**: Generates a new RSA-2048 keypair.
    *   `modulusLength: 2048`: Standard security level.
    *   `format: 'pem'`: Returns keys as standard PEM strings (`-----BEGIN...`).

### Data Shredding

**Line 162**: Shred Data
```javascript
  static shredData(buffer) {
```
*   **Explanation**: Securely wipes data from memory.

**Line 166-167**: Overwrite
```javascript
    for (let pass = 0; pass < 3; pass++) {
      crypto.randomFillSync(buffer);
    }
```
*   **Explanation**:
    *   `crypto.randomFillSync(buffer)`: Fills the existing buffer memory with random bytes.
    *   **Why**: In managed languages like JS, the Garbage Collector handles memory. However, for sensitive data (like decrypted keys), we want to ensure the data is gone *immediately* and cannot be recovered from a memory dump.

## Summary
This service provides the cryptographic primitives for the application. It strictly adheres to modern standards:
*   **AES-256-GCM** for data (Confidentiality + Integrity).
*   **RSA-OAEP-SHA256** for keys (Secure Key Exchange).
*   **Secure Randomness** for IVs and Salts.
