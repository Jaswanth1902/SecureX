**Desktop UI — Overview & Screens**

This document describes the user-facing parts of the Desktop app: screens, navigation, and user experience. It focuses on what the user sees and interacts with.

Project location: `desktop_app/`

Summary
- Flutter desktop application (Windows-targeted) providing owner workflows: register, login, key management, file listing, printing, history, and profile.

High-level Screens
- Login / Register
  - Combined PageView with two panes: Login and Register. Users toggle between pages via the UI.
  - Register flow generates an RSA key pair locally, uploads the public key to the server, and stores the private key locally as `owner_private_key.json`.
  - Login requires the private key file to be present; the public key may be sent for sync on login.

- Dashboard
  - Shows a list of files owned/managed by the owner (fetched from `/api/files`).
  - Each file row shows name, size, upload timestamp, status and actions (print/delete where allowed).
  - Provides quick navigation to History and Profile screens.

- File Print Flow
  - User selects a file and requests printing. The app calls `/api/print/<fileId>` to fetch encrypted file data and keys.
  - The app decrypts symmetric key using the owner's private key, then decrypts file content for printing.

- History
  - Lists past uploads, deletes, and prints (`/api/history`).
  - Supports clearing history (`/api/clear-history`).

- Profile / Settings
  - Shows owner profile (`/api/owners/profile`) and allows updating the display name (`/api/owners/update-profile`).

Navigation & UX
- Animations: PageController used for login/register transitions.
- Form validation: inline checks for empty fields and password confirmation.
- Loading states: network/key generation operations set a loading flag to prevent duplicate actions and show spinners.

Completed UI Features
- Register with key generation and upload of public key
- Login (requires local private key)
- Dashboard file list and basic print/delete flows
- History listing and clear-history action
- Profile fetch and name update

How to run (quick)
1. Start backend server from `backend_flask`:
```powershell
cd C:\Users\psabh\SecureX\backend_flask
python -u app.py
```
2. Run desktop app:
```powershell
cd C:\Users\psabh\SecureX\desktop_app
flutter run -d windows
```

Notes
- Ensure the private key file exists in the documents folder before attempting login from the desktop UI.
