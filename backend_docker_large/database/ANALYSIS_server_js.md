# Detailed Analysis: server.js

## File Information
- **Path**: `backend/server.js`
- **Type**: Main Entry Point
- **Language**: JavaScript (Node.js)
- **Framework**: Express.js

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This file serves as the central nervous system of the backend application. It is responsible for:
1.  **Bootstrapping**: Initializing the Express application.
2.  **Configuration**: Loading and validating environment variables.
3.  **Security**: Applying global security middleware (Helmet, CORS).
4.  **Middleware**: Setting up logging, body parsing, and compression.
5.  **Routing**: Connecting API routes to their respective handlers.
6.  **Error Handling**: Defining global error handlers.
7.  **Execution**: Starting the HTTP server on the specified port.

## Line-by-Line Explanation

### Imports and Configuration

**Line 1-2**: Comments identifying the file.
```javascript
// Backend Main Server
// Secure File Printing System - Express API Server
```
*   **Explanation**: These are single-line comments. They provide a brief description of the file's purpose. They are ignored by the JavaScript engine but are useful for developers.

**Line 4**: Loading Environment Variables
```javascript
require("dotenv").config();
```
*   **Explanation**:
    *   `require("dotenv")`: Imports the `dotenv` library. This library is crucial for managing configuration separate from code.
    *   `.config()`: Calls the configuration method. This reads the `.env` file from the root of the project and loads the variables defined there into `process.env`.
    *   **Why**: This allows us to keep sensitive information like API keys and database passwords out of the source code.

**Line 5**: Importing Express
```javascript
const express = require("express");
```
*   **Explanation**: Imports the `express` framework. Express is the standard web framework for Node.js, providing a robust set of features for web and mobile applications.

**Line 6**: Importing CORS
```javascript
const cors = require("cors");
```
*   **Explanation**: Imports the `cors` middleware. CORS stands for Cross-Origin Resource Sharing. It allows the browser to make requests to this server from a different domain (e.g., the frontend running on localhost:3000).

**Line 7**: Importing Helmet
```javascript
const helmet = require("helmet");
```
*   **Explanation**: Imports `helmet`. Helmet helps secure Express apps by setting various HTTP headers. It's a collection of smaller middleware functions that set security-related HTTP response headers.

**Line 8**: Importing Morgan
```javascript
const morgan = require("morgan");
```
*   **Explanation**: Imports `morgan`. Morgan is an HTTP request logger middleware for Node.js. It logs details about every request that hits the server, which is essential for debugging and monitoring.

**Line 9**: Importing Compression
```javascript
const compression = require("compression");
```
*   **Explanation**: Imports `compression`. This middleware attempts to compress response bodies for all requests that traverse through the middleware, usually using Gzip. This reduces the size of the data sent over the network, speeding up the application.

### Configuration Validation

**Line 11-13**: Section Header
```javascript
// ========================================
// CONFIGURATION VALIDATION
// ========================================
```
*   **Explanation**: Visual separator to indicate a new section of the code.

**Line 16**: Defining Required Variables
```javascript
const requiredEnvVars = ["JWT_SECRET", "ENCRYPTION_KEY"];
```
*   **Explanation**: Defines an array of strings. Each string represents the name of an environment variable that *must* be present for the application to function securely.

**Line 17-27**: Validation Loop
```javascript
for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    throw new Error(`Critical: ${envVar} environment variable is not set`);
  }
  if (envVar === "JWT_SECRET" && process.env[envVar].length < 32) {
    throw new Error("Critical: JWT_SECRET must be at least 32 characters");
  }
  if (envVar === "ENCRYPTION_KEY" && process.env[envVar].length < 32) {
    throw new Error("Critical: ENCRYPTION_KEY must be at least 32 characters (preferably 64 hex chars for 32 bytes)");
  }
}
```
*   **Explanation**:
    *   Iterates through each required variable.
    *   **Check 1**: `!process.env[envVar]` checks if the variable is missing. If so, it throws an error, stopping the server immediately. This prevents the server from running in an insecure or broken state.
    *   **Check 2**: Checks if `JWT_SECRET` is too short. A short secret makes JWTs vulnerable to brute-force attacks.
    *   **Check 3**: Checks if `ENCRYPTION_KEY` is too short. AES-256 requires a 32-byte key.

**Line 30-34**: Production CORS Check
```javascript
if (process.env.NODE_ENV === "production" && !process.env.CORS_ORIGIN) {
  throw new Error(
    "Critical: CORS_ORIGIN must be set in production environment"
  );
}
```
*   **Explanation**:
    *   Checks if the code is running in `production` mode.
    *   If so, it enforces that `CORS_ORIGIN` is set. In development, we might allow all origins, but in production, we must restrict access to only our trusted frontend domains.

### App Initialization

**Line 37**: Initialize Express
```javascript
const app = express();
```
*   **Explanation**: Creates an instance of the Express application. The `app` object is used to configure the server, define routes, and start listening for requests.

### Middleware Configuration

**Line 43-60**: Security Headers (Helmet)
```javascript
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
      },
    },
    hsts: {
      maxAge: 31536000, // 1 year
      includeSubDomains: true,
      preload: true,
    },
  })
);
```
*   **Explanation**:
    *   `app.use()`: Mounts the middleware function.
    *   `helmet()`: Initializes Helmet with custom configuration.
    *   `contentSecurityPolicy` (CSP): Helps prevent Cross-Site Scripting (XSS) attacks by defining which dynamic resources are allowed to load.
        *   `defaultSrc`: Only allow resources from the same origin (`'self'`).
        *   `styleSrc`: Allow styles from same origin and inline styles (needed for some UI libraries).
        *   `imgSrc`: Allow images from same origin, data URIs (base64), and HTTPS sources.
    *   `hsts` (HTTP Strict Transport Security): Tells browsers to *only* access this site using HTTPS.
        *   `maxAge`: How long the browser should remember this rule (1 year).
        *   `includeSubDomains`: Apply to all subdomains.
        *   `preload`: Request inclusion in browser HSTS preload lists.

**Line 63-70**: CORS Configuration
```javascript
app.use(
  cors({
    origin: process.env.CORS_ORIGIN || "http://localhost:3000",
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);
```
*   **Explanation**:
    *   `origin`: Specifies which domains are allowed to access the API. Defaults to localhost:3000 for dev.
    *   `credentials`: Allows cookies and authorization headers to be sent cross-origin.
    *   `methods`: Restricts the allowed HTTP methods.
    *   `allowedHeaders`: Restricts which custom headers can be sent.

**Line 73-84**: HTTPS Enforcement
```javascript
if (process.env.NODE_ENV === "production") {
  app.use((req, res, next) => {
    if (!req.secure && req.get("x-forwarded-proto") !== "https") {
      return res.status(403).json({
        error: true,
        statusCode: 403,
        message: "HTTPS is required",
      });
    }
    next();
  });
}
```
*   **Explanation**:
    *   This middleware only runs in production.
    *   It checks if the request is secure (HTTPS) or if the load balancer forwarded it as HTTPS (`x-forwarded-proto`).
    *   If not, it rejects the request with a 403 Forbidden status. This ensures no unencrypted traffic reaches the application logic.

**Line 87-88**: Body Parsing
```javascript
app.use(express.json({ limit: "100mb" }));
app.use(express.urlencoded({ limit: "100mb", extended: true }));
```
*   **Explanation**:
    *   `express.json()`: Parses incoming requests with JSON payloads.
    *   `express.urlencoded()`: Parses incoming requests with URL-encoded payloads.
    *   `limit: "100mb"`: Increases the default limit (usually 100kb) to allow large file uploads (as base64 strings or similar). This is critical for our file transfer app.

**Line 91**: Compression
```javascript
app.use(compression());
```
*   **Explanation**: Enables Gzip compression for responses.

**Line 94**: Logging
```javascript
app.use(morgan("combined"));
```
*   **Explanation**: Enables request logging using the "combined" Apache format, which includes standard information like IP, date, method, URL, status, and user agent.

### Error Handling Middleware

**Line 100-112**: Global Error Handler
```javascript
app.use((err, req, res, _next) => {
  console.error("Error:", err);

  const statusCode = err.statusCode || 500;
  const message = err.message || "Internal Server Error";

  res.status(statusCode).json({
    error: true,
    statusCode,
    message,
    timestamp: new Date().toISOString(),
  });
});
```
*   **Explanation**:
    *   This is a special middleware with 4 arguments `(err, req, res, next)`. Express recognizes this signature as an error handler.
    *   It catches any errors thrown in previous middleware or routes.
    *   It logs the error to the console.
    *   It sends a structured JSON response to the client, ensuring the API always returns valid JSON even when it crashes.

### Routes

**Line 119-125**: Health Check
```javascript
app.get("/health", (req, res) => {
  res.json({
    status: "OK",
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
  });
});
```
*   **Explanation**:
    *   Defines a `GET` route at `/health`.
    *   Used by Docker, load balancers, and monitoring tools to check if the server is up and running.

**Line 128**: API Routes
```javascript
app.use("/api", require("./routes/files"));
```
*   **Explanation**:
    *   Mounts the file-related routes under the `/api` prefix.
    *   Any route defined in `routes/files.js` (like `/upload`) will be accessible at `/api/upload`.

**Line 131-132**: Auth and Owner Routes
```javascript
app.use("/api/auth", require("./routes/auth"));
app.use("/api/owners", require("./routes/owners"));
```
*   **Explanation**:
    *   Mounts authentication routes under `/api/auth`.
    *   Mounts owner management routes under `/api/owners`.

### 404 Handler

**Line 144-151**: Not Found Handler
```javascript
app.use((req, res) => {
  res.status(404).json({
    error: true,
    statusCode: 404,
    message: "Endpoint not found",
    path: req.path,
  });
});
```
*   **Explanation**:
    *   This middleware is placed *after* all routes.
    *   If a request reaches this point, it means no previous route matched the URL.
    *   It returns a standard 404 JSON response.

### Server Startup

**Line 157**: Port Definition
```javascript
const PORT = process.env.PORT || 5000;
```
*   **Explanation**: Sets the port number. It tries to use the `PORT` environment variable first; if not set, it defaults to 5000.

**Line 160-168**: Start Listening
```javascript
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`\n${"=".repeat(50)}`);
    console.log(`Secure File Printing System - API Server`);
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || "development"}`);
    console.log(`${"=".repeat(50)}\n`);
  });
}
```
*   **Explanation**:
    *   `require.main === module`: This check ensures the server only starts if the file is run directly (e.g., `node server.js`). If this file is imported by a test runner (e.g., `require('./server')`), it won't start the server automatically, allowing tests to control the start/stop lifecycle.
    *   `app.listen(PORT)`: Binds the server to the port and starts listening for connections.
    *   The `console.log` statements print a nice banner to the terminal indicating the server is ready.

**Line 170**: Export App
```javascript
module.exports = app;
```
*   **Explanation**: Exports the `app` instance. This is useful for testing (using libraries like `supertest`) or if we wanted to wrap this app in another server.

## Summary of Best Practices Used
1.  **Fail Fast**: The server checks for critical configuration immediately and crashes if something is wrong, rather than running insecurely.
2.  **Security First**: Uses Helmet and HSTS by default.
3.  **Structured Logging**: Uses Morgan for consistent logs.
4.  **Graceful Error Handling**: Catches exceptions and returns JSON, preventing the server from hanging or returning HTML stack traces to users.
5.  **Modular Routing**: Routes are split into separate files (`routes/`) to keep `server.js` clean.
