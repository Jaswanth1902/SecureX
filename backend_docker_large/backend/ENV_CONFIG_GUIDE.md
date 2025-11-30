# Environment Configuration Guide

This guide explains how to properly configure environment variables for the Secure File Print System backend.

---

## 📋 Overview

The backend uses environment variables for:
- **Database credentials** (PostgreSQL)
- **Security secrets** (JWT, encryption keys)
- **CORS configuration** (allowed origins)
- **Application settings** (ports, file limits, etc.)

---

## 🔒 Security Best Practices

### ✅ DO:
- Use strong, randomly generated secrets (minimum 32 bytes / 64 hex characters)
- Store production secrets in CI/CD secrets or cloud secret managers
- Rotate credentials regularly
- Use different credentials for each environment (dev, staging, prod)
- Keep `.env` files in `.gitignore`

### ❌ DON'T:
- Commit `.env` files to version control
- Use default credentials (`postgres:postgres`) in production
- Share credentials via email or chat
- Reuse secrets across different applications
- Use weak or predictable passwords

---

## 📁 Environment Files

### For Docker Deployment

**File:** `.env` (in `backend/` directory)

This file is used by `docker-compose.yml`:

```bash
# Copy the example file
cp docker.env.example .env

# Edit with your values
nano .env
```

**Required variables:**
- `POSTGRES_USER` - Database username
- `POSTGRES_PASSWORD` - Database password
- `POSTGRES_DB` - Database name
- `JWT_SECRET` - JWT signing secret
- `JWT_REFRESH_SECRET` - Refresh token secret
- `ENCRYPTION_KEY` - File encryption key
- `CORS_ORIGIN` - Allowed CORS origins
- `CORS_CREDENTIALS` - Allow credentials in CORS

### For Manual/Non-Docker Deployment

**File:** `.env` (in `backend/` directory)

This file is loaded by the Node.js application:

```bash
# Copy the example file
cp .env.example .env

# Edit with your values
nano .env
```

**Required variables:** (See `.env.example` for full list)

---

## 🔑 Generating Secure Secrets

### Using Node.js (Recommended)

```bash
# Generate JWT_SECRET (64 characters)
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Generate JWT_REFRESH_SECRET (64 characters)
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Generate ENCRYPTION_KEY (64 characters)
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### Using OpenSSL

```bash
# Generate 64-character hex string
openssl rand -hex 32

# Generate base64 string
openssl rand -base64 32
```

### Using PowerShell (Windows)

```powershell
# Generate random bytes and convert to hex
-join ((1..32 | ForEach-Object { '{0:X2}' -f (Get-Random -Maximum 256) }))
```

---

## 🌐 CORS Configuration

### Local Development

```env
CORS_ORIGIN=http://localhost:3000,http://localhost:3001
CORS_CREDENTIALS=true
```

### Same Network (Local IP)

```env
CORS_ORIGIN=http://192.168.1.100:3000,http://192.168.1.100:5000
CORS_CREDENTIALS=true
```

### Using ngrok (Remote Testing)

```env
CORS_ORIGIN=https://abc123.ngrok.io
CORS_CREDENTIALS=true
```

**Important:** ngrok URLs use HTTPS, not HTTP!

### Production (Custom Domain)

```env
CORS_ORIGIN=https://app.example.com,https://admin.example.com
CORS_CREDENTIALS=true
```

**Multiple origins:** Separate with commas (no spaces)

---

## 🗄️ Database Configuration

### Default (Development)

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=secure_print
```

### Production (Recommended)

```env
POSTGRES_USER=secure_print_user
POSTGRES_PASSWORD=YourStrongPasswordHere_Min32Chars!
POSTGRES_DB=secure_print_prod
```

**Generate strong password:**
```bash
openssl rand -base64 24
```

---

## 🚀 Deployment Scenarios

### Scenario 1: Docker Compose (Local/Development)

1. **Create `.env` file:**
   ```bash
   cd backend
   cp docker.env.example .env
   ```

2. **Edit `.env`:**
   ```env
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=your_secure_password
   POSTGRES_DB=secure_print
   JWT_SECRET=generated_secret_64_chars
   JWT_REFRESH_SECRET=generated_secret_64_chars
   ENCRYPTION_KEY=generated_secret_64_chars
   CORS_ORIGIN=http://localhost:3000
   CORS_CREDENTIALS=true
   ```

3. **Start services:**
   ```bash
   docker-compose up --build
   ```

### Scenario 2: Docker Compose (Production)

1. **Use environment variables from CI/CD:**
   ```yaml
   # docker-compose.prod.yml
   services:
     backend:
       environment:
         POSTGRES_USER: ${POSTGRES_USER}
         POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
         # ... other vars from secrets
   ```

2. **Deploy with secrets:**
   ```bash
   # Set secrets in CI/CD environment
   export POSTGRES_USER="prod_user"
   export POSTGRES_PASSWORD="strong_password"
   # ... other secrets
   
   docker-compose -f docker-compose.yml up -d
   ```

### Scenario 3: AWS/Cloud Deployment

**Use AWS Secrets Manager, Azure Key Vault, or Google Secret Manager:**

```javascript
// Example: Load secrets from AWS Secrets Manager
const AWS = require('aws-sdk');
const secretsManager = new AWS.SecretsManager();

async function getSecret(secretName) {
  const data = await secretsManager.getSecretValue({ SecretId: secretName }).promise();
  return JSON.parse(data.SecretString);
}
```

### Scenario 4: Distributed Setup (Friend's Computer)

1. **Friend creates `.env`:**
   ```bash
   cd backend
   cp docker.env.example .env
   nano .env
   ```

2. **Friend configures for network access:**
   ```env
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=secure_password
   POSTGRES_DB=secure_print
   JWT_SECRET=<generated_secret>
   JWT_REFRESH_SECRET=<generated_secret>
   ENCRYPTION_KEY=<generated_secret>
   CORS_ORIGIN=http://192.168.1.100:3000,http://192.168.1.101:3000
   CORS_CREDENTIALS=true
   ```

3. **You configure mobile app with friend's IP:**
   ```dart
   // mobile_app/lib/services/api_service.dart
   final String baseUrl = 'http://192.168.1.100:5000';
   ```

---

## ✅ Verification Checklist

Before deploying, verify:

- [ ] `.env` file exists and is not committed to Git
- [ ] All `CHANGE_ME_*` placeholders are replaced with actual values
- [ ] Secrets are at least 64 characters (hex)
- [ ] Database credentials are strong and unique
- [ ] CORS origins match your deployment URLs
- [ ] HTTP/HTTPS protocol matches your setup
- [ ] Environment matches NODE_ENV setting

---

## 🔄 Rotating Secrets

When rotating secrets:

1. **Generate new secrets:**
   ```bash
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```

2. **Update `.env` file**

3. **Restart services:**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

4. **Invalidate old tokens/sessions** (users must re-authenticate)

---

## 🐛 Troubleshooting

### Problem: "CORS Error" in browser

**Solution:** Check CORS_ORIGIN matches your frontend URL exactly (including protocol and port)

```env
# Wrong
CORS_ORIGIN=localhost:3000

# Correct
CORS_ORIGIN=http://localhost:3000
```

### Problem: "Database connection refused"

**Solution:** Check database credentials match in both postgres and backend services

```bash
docker-compose logs postgres
docker-compose logs backend
```

### Problem: "JWT token invalid"

**Solution:** Ensure JWT_SECRET hasn't changed. Rotation requires re-authentication.

---

## 📚 Additional Resources

- [Docker Compose Environment Variables](https://docs.docker.com/compose/environment-variables/)
- [Node.js dotenv package](https://github.com/motdotla/dotenv)
- [OWASP Secret Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

---

**Last Updated:** 2025-11-22  
**Version:** 1.0.0
