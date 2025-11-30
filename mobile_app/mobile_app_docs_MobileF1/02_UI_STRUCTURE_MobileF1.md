# UI Structure & Navigation (MobileF1)

**Tag**: `MobileF1`

## Navigation
The app uses a `BottomNavigationBar` in `MyHomePage` (`main.dart`) to switch between four main sections:
1.  **Home**: `HomePage`
2.  **Upload**: `UploadPage` (wraps `UploadScreen`)
3.  **Jobs**: `JobsPage`
4.  **Settings**: `SettingsPage`

## Screens

### 1. Login Screen (`login_screen.dart`)
- **Purpose**: Authenticate the user.
- **Components**:
  - Email & Password TextFields.
  - Login Button (triggers `_handleLogin`).
  - Register Link.
  - Error message display.
- **Logic**: Calls `ApiService.loginUser` and stores tokens via `UserService`.

### 2. Upload Screen (`upload_screen.dart`)
- **Purpose**: Core functionality - Pick, Encrypt, and Upload files.
- **Components**:
  - **Header**: "Secure File Upload" banner.
  - **File Picker**: Button to open system file picker (`file_picker`).
  - **File Info**: Displays selected file name and size.
  - **Action Button**: "Encrypt & Upload" (triggers process).
  - **Progress**: Linear progress indicator and status text.
  - **Success**: Display of File ID and "Copy ID" button.
- **Flow**:
  1.  User picks file.
  2.  User clicks Upload.
  3.  App generates AES key and encrypts file.
  4.  App prompts for Owner ID.
  5.  App fetches Owner Public Key.
  6.  App encrypts AES key with RSA.
  7.  App uploads everything to server.

### 3. Placeholder Screens
- **HomePage**: Welcome message and icon.
- **JobsPage**: "No print jobs yet" placeholder.
- **SettingsPage**: "Settings coming soon" placeholder.

## Theme
- **Colors**: Blue primary swatch (`Colors.blue`), Green for success, Red for errors.
- **Design**: Material Design 3 (`useMaterial3: true`).
