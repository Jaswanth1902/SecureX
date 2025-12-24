# Password Hashing & Salting Overview

## What Was Changed
- All password storage and verification in the backend (Node.js and Python) now uses bcrypt for secure hashing and salting.
- Plaintext passwords are never stored or logged.
- Passwords are validated and hashed during registration and verified during login.
- Database schemas remain unchanged; only the logic for password handling is updated.

## How Hashing & Salting Works
- **Hashing**: Converts a password into a fixed-length string using a one-way function (bcrypt).
- **Salting**: Adds a unique random value to each password before hashing, preventing rainbow table attacks.
- **bcrypt**: A slow, adaptive hashing algorithm designed for password security. It automatically handles salt generation and storage.


## How to Test Password Hashing & Salting (Manual & Automated)

### 1. Registration Test
- Register a new user via the app or API.
- **Expected:** The password is not stored in plaintext in the database.
- **Check:** The password field contains a long bcrypt hash (starts with $2b$ or $2a$).

### 2. Login Test
- Attempt to log in with the correct password.
- **Expected:** Login succeeds.
- Attempt to log in with an incorrect password.
- **Expected:** Login fails.

### 3. Hash Uniqueness (Salting) Test
- Register two users with the same password.
- **Expected:** The stored password hashes in the database are different (proves salting is applied).

### 4. No Plaintext Leakage Test
- Search logs, error messages, and API responses for any occurrence of the actual password.
- **Expected:** No plaintext passwords are ever logged or returned.

### 5. Automated Unit/Integration Tests
- Run backend test suites (e.g., test_all_endpoints.py, passwordUtil.test.js if present).
- **Expected:** All authentication and password-related tests pass, and no test exposes plaintext passwords.

---

**Salting is enforced for all databases:**
- Both Node.js and Python backends use bcrypt, which automatically generates a unique salt for every password.
- All password hashes in all databases are salted by design—no unsalted hashes are stored anywhere.

## Why This Is Important
- Prevents attackers from recovering passwords if the database is leaked.
- Protects against brute-force and rainbow table attacks.
- Follows industry best practices for authentication security.

## What Libraries/Tech Are Used
- **Node.js backend**: bcryptjs
- **Python backend**: bcrypt
- **Dart/Flutter apps**: Passwords are sent to the backend for hashing; no client-side hashing.

## How to Add/Change Hashing
- Always use a strong, slow hash function (bcrypt, Argon2, scrypt).
- Never store or log plaintext passwords.
- Always hash and salt passwords before storing or comparing.

---

For more details or code samples, see the backend authentication service files or ask for specific implementation details.