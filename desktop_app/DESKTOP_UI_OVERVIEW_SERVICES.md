**Desktop UI — Services, Integration & Security**

This document covers the desktop app's internal services, API integration points, key storage, and security notes.

Services (in `desktop_app/lib/services`)
- `AuthService` — handles authentication and profile operations. Stores `accessToken` in memory and the `user` object. Key methods:
  - `register(email, password, fullName, publicKey)` → `POST /api/owners/register`
  - `login(email, password, publicKey)` → `POST /api/owners/login`
  - `refreshProfile()` → `GET /api/owners/profile`
  - `updateName(newName)` → `POST /api/owners/update-profile`

- `KeyService` — generates and stores RSA keypairs using PointyCastle. Responsible for:
  - `generateAndStoreKeyPair()` — creates RSA keypair and saves JSON to app documents folder as `owner_private_key.json`.
  - `getStoredKeyPair()` — reads stored key file and reconstructs keys for use in decrypt operations.
  - `getPublicKeyPem()` — builds a PEM-formatted public key to send to server.

- `ApiService` — file operations and history. Endpoints:
  - `GET /api/files`
  - `GET /api/print/<fileId>`
  - `POST /api/delete/<fileId>`
  - `POST /api/status/update/<fileId>`
  - `GET /api/history`
  - `POST /api/clear-history`

- `NotificationService` — SSE connection to `GET /api/events/stream` for server-sent events. Designed to receive push notifications for file status updates etc.

Backend blueprints and endpoints mapping (see `backend_flask/app.py`)
- `auth_bp` → `/api/auth` (not used by desktop UI currently)
- `owners_bp` → `/api/owners` (desktop uses this)
- `files_bp` → `/api` (files endpoints)
- `events_bp` → `/api/events`
- `status_bp` → `/api/status`

Local file expectations
- Private key file: `owner_private_key.json` stored in the application documents directory (created by `KeyService`). The desktop app expects this file to exist before attempting login.
- Key JSON fields: modulus, publicExponent, privateExponent, p, q. The UI reconstructs RSA keys from these values.

Authentication flow (detailed)
1. During registration, the app creates a keypair, sends public key PEM with register payload. Server stores public key in `owners.public_key`.
2. On login, the app reads local private key to decrypt symmetric keys received from server when fetching a file for printing.
3. Tokens returned by server (`accessToken`, `refreshToken`) are stored in memory and used in `Authorization: Bearer <token>` headers for protected endpoints (profile, files, etc.).

Error handling
- Auth and API services return boolean success flags; UI surfaces descriptive messages on failure.
- Debug prints are present in services to log request/response summary; check console when troubleshooting.

Security notes
- Private key storage is currently unencrypted JSON. For production, use OS key stores or encrypt the file with a passphrase.
- Access tokens are in-memory only; if persisted, they must be encrypted.
- Ensure the backend is started from `backend_flask` so the desktop app requests hit the correct DB and schema.
