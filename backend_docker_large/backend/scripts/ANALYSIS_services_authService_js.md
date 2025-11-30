# Detailed Analysis: services/authService.js

## File Information
- **Path**: `backend/services/authService.js`
- **Type**: Service Layer
- **Function**: Authentication Logic (Hashing, Tokens, Validation)

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This file encapsulates all the "business logic" related to authentication. It keeps the route handlers (controllers) clean by moving complex logic like password hashing and token signing into reusable static methods. It uses `bcryptjs` for security and `jsonwebtoken` for session management.

## Line-by-Line Explanation

### Imports

**Line 4-6**: Dependencies
```javascript
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
```
*   **Explanation**:
    *   `jsonwebtoken`: Library for creating and verifying JSON Web Tokens.
    *   `bcryptjs`: Library for hashing passwords. It uses a salt and a slow hashing algorithm (Blowfish) to make brute-force attacks difficult.
    *   `crypto`: Node.js built-in crypto library, used here for simple hashing (SHA-256) of tokens.

### Class Definition

**Line 8**: Class
```javascript
class AuthService {
```
*   **Explanation**: We define a class with `static` methods. This acts as a namespace for our functions. We don't need to instantiate this class (`new AuthService()`) to use it.

### Password Management

**Line 14**: Hash Password
```javascript
  static async hashPassword(password) {
```
*   **Explanation**: Async function because bcrypt operations are CPU intensive and asynchronous.

**Line 16-17**: Salting and Hashing
```javascript
      const salt = await bcrypt.genSalt(10);
      return await bcrypt.hash(password, salt);
```
*   **Explanation**:
    *   `genSalt(10)`: Generates a random salt with a "cost factor" of 10. The cost factor determines how many iterations the algorithm runs. Higher is safer but slower. 10 is a good balance for 2025.
    *   `hash(password, salt)`: Combines the password and salt, then hashes them.

**Line 29**: Compare Password
```javascript
  static async comparePassword(password, hash) {
```
*   **Explanation**: Used during login.

**Line 31**: Comparison
```javascript
      return await bcrypt.compare(password, hash);
```
*   **Explanation**:
    *   `bcrypt.compare`: This function extracts the salt from the stored `hash`, hashes the input `password` with that salt, and checks if the result matches the stored hash. It handles timing attacks automatically.

### Token Generation

**Line 43**: Generate Access Token
```javascript
  static generateAccessToken(payload, expiresIn = '1h') {
```
*   **Explanation**: Creates the short-lived token used for API requests. Default expiry is 1 hour.

**Line 45-48**: Signing
```javascript
      return jwt.sign(payload, process.env.JWT_SECRET, {
        expiresIn,
        algorithm: 'HS256',
      });
```
*   **Explanation**:
    *   `jwt.sign`: Creates the token string.
    *   `payload`: The data to store inside (user ID, email, role).
    *   `process.env.JWT_SECRET`: The secret key used to sign the token. **If this leaks, anyone can forge tokens.**
    *   `HS256`: HMAC SHA-256 algorithm.

**Line 60**: Generate Refresh Token
```javascript
  static generateRefreshToken(payload, expiresIn = '7d') {
```
*   **Explanation**: Creates the long-lived token used to get new access tokens. Default expiry is 7 days.

**Line 62-65**: Signing (Different Secret)
```javascript
      return jwt.sign(payload, process.env.JWT_REFRESH_SECRET, {
        expiresIn,
        algorithm: 'HS256',
      });
```
*   **Explanation**:
    *   **Crucial**: Uses `JWT_REFRESH_SECRET`. Using a different secret for refresh tokens adds a layer of security. If the access token secret leaks, refresh tokens are still safe (and vice versa).

### Token Verification

**Line 77**: Verify Access Token
```javascript
  static verifyAccessToken(token) {
```
*   **Explanation**: Used by middleware to check if a request is authorized.

**Line 79-81**: Verification
```javascript
      return jwt.verify(token, process.env.JWT_SECRET, {
        algorithms: ['HS256'],
      });
```
*   **Explanation**:
    *   `jwt.verify`: Decodes the token and checks the signature. If valid, returns the payload. If invalid (expired, wrong signature), throws an error.

**Line 93**: Verify Refresh Token
```javascript
  static verifyRefreshToken(token) {
```
*   **Explanation**: Used by the `/refresh-token` endpoint. Uses `JWT_REFRESH_SECRET`.

### Token Hashing

**Line 121**: Hash Token
```javascript
  static hashToken(token) {
    return crypto.createHash('sha256').update(token).digest('hex');
  }
```
*   **Explanation**:
    *   This is a fast, synchronous hash (SHA-256).
    *   **Purpose**: We store *hashes* of tokens in the database, not the tokens themselves. This is for the same reason we hash passwords. If the DB is compromised, the attacker finds `sha256(token)`. They cannot reverse this to find `token`, so they cannot use the stolen data to impersonate users.

### Validation Helpers

**Line 130**: Validate Password Strength
```javascript
  static validatePassword(password) {
```
*   **Explanation**: Enforces complexity rules.
    *   Min 8 chars.
    *   At least 1 uppercase, 1 lowercase, 1 digit, 1 special char.
    *   Returns an object `{ isValid: boolean, errors: string[] }`.

**Line 164**: Validate Email
```javascript
  static validateEmail(email) {
```
*   **Explanation**: Uses a Regex to check if the email looks valid (e.g., `user@domain.com`).

**Line 174**: Generate Code
```javascript
  static generateCode(length = 6) {
```
*   **Explanation**: Utility to generate random numeric codes (e.g., for OTPs). Not currently used in the main flow but good to have.

## Summary
This service abstracts the complexity of security operations. By centralizing this logic, we ensure that:
1.  All passwords are hashed consistently.
2.  All tokens are signed and verified with the correct secrets.
3.  Validation rules are applied uniformly across the app.
