**Desktop UI Overview**

This document describes the Desktop application user interface we built for SecureX. It covers screens, navigation, state management, services, important UI behaviors, integration points (backend endpoints and required local files), and the list of features still to be implemented.

**Summary**: The desktop UI is a Flutter desktop app (Windows targeted) providing owner workflows: register, login, key management, file listing, file print/download, history, and profile management. The UI is built using Flutter widgets and `provider` for state management; HTTP requests go to the local backend at `http://localhost:5000` by default.

**Project location**: `desktop_app/`

**High-level Screens**
- **Login / Register screen**: Combined PageView that toggles between login and registration. The register flow generates and stores an RSA keypair locally, uploads the public key to the server, and stores the private key in the user's documents folder as `owner_private_key.json` (managed by `KeyService`). The login flow requires the private key to be present locally.
- **Dashboard**: Main post-login screen. Shows the file list, actions to print/delete, file status, and quick access to history and profile.
- **File List / Print flow**: Users see uploaded files (fetched from `/api/files`), can request a file for printing (`/api/print/<fileId>`), and the app downloads encrypted file data and decrypts it using the stored key pair and a symmetric key exchange.
- **History**: Shows upload and print history (`/api/history`) and supports clearing history (`/api/clear-history`).
- **Profile / Settings**: Displays owner information fetched from `/api/owners/profile` and allows updating profile name (`/api/owners/update-profile`).

**Navigation & UX**
- The login/register UI uses a `PageController` for a smooth animated toggle between login and register pages.
- Form validations are performed client-side for presence and password confirmation. Error states are surfaced to the user in readable messages.
- Long-running actions (network calls, key generation) set an `_isLoading` flag and show loading states to prevent duplicate actions.

**State Management**
- `provider` is used to expose services to UI: `AuthService`, `ApiService`, `KeyService`, `NotificationService`.
- `AuthService` stores `accessToken` and `user` in memory during the session and exposes `isAuthenticated` to gate features in the UI.

**Key Pieces (Services)**
- `KeyService` (desktop): generates RSA key pairs (PointyCastle) and stores the private key JSON in the application documents folder. It also provides a PEM encoder for the public key to send to the server.
- `AuthService`: handles `register`, `login`, `refreshProfile`, and `updateName`. It calls the following endpoints on `http://localhost:5000`:
  - `POST /api/owners/register`
  - `POST /api/owners/login`
  - `GET  /api/owners/profile`
  - `POST /api/owners/update-profile`
- `ApiService`: handles file operations and history with endpoints:
  - `GET  /api/files`
  - `GET  /api/print/<fileId>`
  - `POST /api/delete/<fileId>`
  - `POST /api/status/update/<fileId>`
  - `GET  /api/history`
  - `POST /api/clear-history`
- `NotificationService`: connects to event stream `GET /api/events/stream` (SSE) to receive server push messages. Note: SSE consumption is present in code but may require further testing on desktop.

**Local files and keys**
- Private key storage path (desktop): application documents directory + `owner_private_key.json`. The key file JSON contains the RSA modulus, exponents, and primes needed for decrypt operations.
- Public key PEM is produced on registration and uploaded to the server as part of the register request.

**Authentication flow (desktop)**
1. Register: `KeyService.generateAndStoreKeyPair()` → produce public key PEM → `AuthService.register(email, password, full_name, publicKey)` which calls `POST /api/owners/register`. On success the app stores the returned access token in memory.
2. Login: `KeyService.getStoredKeyPair()` must succeed (private key present) → public key PEM optional for sync → `AuthService.login(email, password, publicKey)` which calls `POST /api/owners/login`. On success app stores access token in memory and navigates to Dashboard.

**Error handling & diagnostics**
- Network failures and server 500/4xx responses are captured and converted to messages the UI shows. There are debug prints in numerous places to help trace API requests and tokens.
- Common development issue: ensure the backend server is running from the `backend_flask` folder and listening on port 5000 (requests to a different or stale server will fail).

**Desktop-specific notes**
- The app uses local RSA keys and relies on platform-specific file locations for the private key. Ensure the application has filesystem access to the documents directory.
- SSE (notifications) behavior on Windows needs to be validated end-to-end; some SSE client libraries behave differently on desktop than in a browser.

**Security notes**
- Private keys are stored locally in plaintext JSON for simplicity. In production, this should be encrypted using platform key stores.
- Access tokens are stored in memory only (not persisted) to reduce leak surface; if persistence is added, it must be encrypted.

**Files / Code of interest**
- `desktop_app/lib/screens/login_screen.dart` — Login/Register UI and client-side validation.
- `desktop_app/lib/screens/dashboard_screen.dart` — Dashboard and navigation after login.
- `desktop_app/lib/services/auth_service.dart` — Auth API calls and token handling.
- `desktop_app/lib/services/key_service.dart` — Key generation, storage, and PEM conversion.
- `desktop_app/lib/services/api_service.dart` — File list, print, history, and status API calls.
- `desktop_app/lib/services/notification_service.dart` — SSE connection to `/api/events/stream`.

**Completed features (implemented in UI)**
- Login and registration flows with client key generation.
- File list display and print request flow.
- History listing and clear history action.
- Profile fetch and update (name change) via API.
- Basic error and loading UI states.

**Planned / Not yet implemented features**
- Google account authentication: integration with Google OAuth/Sign-in (desktop) — NOT implemented.
- Delete account: UI + API flow to delete owner account — NOT implemented.
- Password change endpoint/UI: user-initiated password change flow — NOT implemented.
- Notifications: final end-to-end push notifications and UI for notification handling (SSE improvements, toaster UI) — NOT implemented.

**How to run locally (quick)**
1. Ensure backend is running from `backend_flask` and listening on `http://localhost:5000`:
```powershell
cd C:\Users\psabh\SecureX\backend_flask
python -u app.py
```
2. Run the desktop app from the `desktop_app` folder (Windows):
```powershell
cd C:\Users\psabh\SecureX\desktop_app
flutter run -d windows
```
3. Register an owner in the app. The private key will be saved to the app documents folder; ensure the file exists before logging in.

**Next recommended steps**
- Implement account deletion and password-change endpoints in `backend_flask` and add matching UI flows.
- Add Google OAuth sign-in for desktop (or web flow) and a UI to connect a Google account.
- Harden local private key storage (encrypt with OS key store) and optionally persist tokens with encryption.
- Finalize SSE/notification UI with actionable toasts and background connection handling.

If you want, I can add a short checklist entry to the project README linking to this document and create basic UI mocks for the missing features.
