# Detailed Analysis: middleware/auth.js

## File Information
- **Path**: `backend/middleware/auth.js`
- **Type**: Express Middleware
- **Function**: Request Interception & Validation

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
Middleware functions are functions that have access to the request object (`req`), the response object (`res`), and the next middleware function in the application’s request-response cycle (`next`).
This file contains reusable middleware for:
1.  **Authentication**: Verifying JWTs.
2.  **Authorization**: Verifying User Roles.
3.  **Rate Limiting**: Preventing abuse.
4.  **Validation**: Checking request bodies.

## Line-by-Line Explanation

### Imports

**Line 4**: AuthService
```javascript
const AuthService = require('../services/authService');
```
*   **Explanation**: Imports the service to verify tokens.

### Verify Token Middleware

**Line 9**: Definition
```javascript
const verifyToken = (req, res, next) => {
```
*   **Explanation**: Standard Express middleware signature.

**Line 11**: Extract Header
```javascript
    const authHeader = req.headers.authorization;
```
*   **Explanation**: Reads the `Authorization` HTTP header.

**Line 13-19**: Check Format
```javascript
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ ... });
    }
```
*   **Explanation**: Expects the format `Bearer <token>`. If missing or wrong format, returns 401 Unauthorized.

**Line 21**: Extract Token
```javascript
    const token = authHeader.substring(7);
```
*   **Explanation**: Removes "Bearer " (7 chars) to get the raw token string.

**Line 23-28**: Verify
```javascript
    try {
      const payload = AuthService.verifyAccessToken(token);
      req.user = payload;
      req.token = token;
      next();
```
*   **Explanation**:
    *   Calls `verifyAccessToken`. If it throws (expired/invalid), we go to catch block.
    *   `req.user = payload`: **Crucial**. This attaches the decoded user info (id, email, role) to the request object. Subsequent route handlers can now access `req.user.id`.
    *   `next()`: Passes control to the next handler (the actual route).

### Verify Role Middleware

**Line 47**: Definition
```javascript
const verifyRole = (allowedRoles = []) => {
```
*   **Explanation**: This is a "Higher Order Function". It takes arguments (`allowedRoles`) and *returns* a middleware function.
*   **Usage**: `verifyRole(['admin', 'owner'])`

**Line 48**: Returned Middleware
```javascript
  return (req, res, next) => {
```
*   **Explanation**: The actual function Express executes.

**Line 49-55**: Check User Presence
```javascript
    if (!req.user) {
      return res.status(401).json({ ... });
    }
```
*   **Explanation**: Safety check. Ensures `verifyToken` was run before this.

**Line 57-63**: Check Role
```javascript
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        message: 'Forbidden: Insufficient permissions',
      });
    }
```
*   **Explanation**: Checks if the user's role (from the JWT) is in the allowed list. If not, returns 403 Forbidden.

### Rate Limit Middleware

**Line 72**: Definition
```javascript
const rateLimit = (limit = 100, windowMs = 60000) => {
```
*   **Explanation**: Creates a rate limiter. Default: 100 requests per minute.

**Line 73**: Store
```javascript
  const store = new Map();
```
*   **Explanation**: Uses a simple in-memory Map to store request counts. **Note**: In a distributed system (multiple server instances), this should be replaced with Redis.

**Line 76**: Key
```javascript
    const key = req.ip;
```
*   **Explanation**: Identifies users by IP address.

**Line 86**: Cleanup
```javascript
    const recentRequests = requests.filter(time => now - time < windowMs);
```
*   **Explanation**: Removes timestamps older than the window (sliding window algorithm).

**Line 88-95**: Limit Check
```javascript
    if (recentRequests.length >= limit) {
      return res.status(429).json({ ... });
    }
```
*   **Explanation**: Returns 429 Too Many Requests if limit exceeded.

### Request Validation Middleware

**Line 111**: Definition
```javascript
const validateRequest = (schema) => {
```
*   **Explanation**: Generic validation helper.

**Line 116-124**: Required Fields
```javascript
      for (const field of schema.required || []) {
        if (!req.body[field]) { ... }
      }
```
*   **Explanation**: Iterates through required fields and checks if they exist in `req.body`.

**Line 127-135**: Type Checking
```javascript
      for (const [field, type] of Object.entries(schema.types || {})) {
        if (req.body[field] && typeof req.body[field] !== type) { ... }
      }
```
*   **Explanation**: Checks types (e.g., ensure 'age' is a number).

## Summary
This file provides the "Guard Rails" for the API.
1.  `verifyToken`: The Gatekeeper. No valid ID card? No entry.
2.  `verifyRole`: The VIP Rope. Valid ID, but are you on the list for this room?
3.  `rateLimit`: The Bouncer. Stop spamming the door.
4.  `validateRequest`: The Dress Code. Are you sending the right data format?
