# SafeCopy - Customer's Comprehensive Manual (Mobile App)

**Version:** 1.0  
**Platform:** Android / iOS  
**Role:** End User

---

## 📖 Table of Contents
1. [Welcome & First-Time Setup](#1-welcome--first-time-setup)
2. [Understanding the Interface](#2-understanding-the-interface)
3. [Mastering File Transfer](#3-mastering-file-transfer)
4. [File Restoration (Downloading)](#4-file-restoration-downloading)
5. [Settings & Configuration](#5-settings--configuration)
6. [FAQ & Common Solutions](#6-faq--common-solutions)

---

## 1. Welcome & First-Time Setup

SafeCopy isn't just a cloud app; it connects directly to your personal secure server (Desktop). This means faster speeds and total privacy.

### Step 1: Permissions
When you first open the app, you will be asked for specific permissions:
- **Storage / Files:** **REQUIRED.** We need this to read the files you want to upload and save the files you restore.
- **Notifications:** Used to alert you when a long upload finishes in the background.

### Step 2: Server Connection
Before logging in, the app needs to know *where* to send files.
1.  Ask the **Owner** for the **Server IP Address** (e.g., `192.168.1.10`).
2.  Tap the **Settings (Gear Icon)** in the top corner.
3.  Enter the IP address in the "Server URL" field.
4.  Tap **Save**. You should look for a "Connected" indicator.

---

## 2. Understanding the Interface

- **🏠 Home Tab:** Your dashboard. Shows your login status and recent activity summary.
- **📤 Upload Tab:** The center action button. This is where you pick files to send.
- **📂 Files/Restore Tab:** A library of everything stored on the server. Go here to get files back.
- **⚙️ Settings:** Configuration for IP address, dark mode, and account management.

---

## 3. Mastering File Transfer

### How to Upload
1.  Navigate to the **Upload Tab**.
2.  **Pick a File:** Tap the big "+" or "Select File" button. Your phone's native file picker will open. You can select photos, videos, or PDFs.
3.  **Preview:** You will see the file name and size.
    *   *Tip:* If the file is huge (1GB+), ensure you have a stable Wi-Fi connection.
4.  **Send:** Tap the **Upload Button**.
5.  **Monitor Progress:** A blue progress bar will show the percentage.
    *   **⚠️ Important:** Try to keep the app open on the screen for fastest performance. Background uploading depends on your phone's battery optimization settings.

### Visual Cues
- **Spinning Circle:** Negotiating connection with the server.
- **Green Checkmark:** The server has confirmed it received 100% of the file.
- **Red "X" or Retry:** The connection dropped. Check your Wi-Fi.

---

## 4. File Restoration (Downloading)

Did you delete a photo from your phone? If you uploaded it to SafeCopy, you can get it back.

1.  Go to the **Files / Restore Tab**.
2.  **Refresh:** Pull down on the screen to refresh the list. It fetches the latest index from the server.
3.  **Search/Browse:** Find your file.
4.  **Tap Download:** Click the download arrow icon.
5.  **Locate File:**
    - On Android, the file is saved to your internal **Downloads** folder (sometimes inside a `SafeCopy` subfolder).
    - You will see a system notification "Download Complete" — tap it to open the file immediately.

---

## 5. Settings & Configuration

### Application Settings
- **Server IP:** The address of your desktop server.
- **Dark Mode:** Toggles between light and dark themes for visual comfort.

### Feedback Loop
Found a bug?
1.  Go to the side menu -> **Feedback**.
2.  Describe the issue. (e.g., "Upload crashes when I pick a video file").
3.  If possible, check "Send Logs". This sends anonymous technical data to help us fix the crash.

---

## 6. FAQ & Common Solutions

**Q: "Server Unreachable" / "Connection Error"**
- **Check Wi-Fi:** Are you on the same Wi-Fi as the desktop computer? (Unless remote access is set up).
- **Check IP:** Did the desktop IP change? Ask the Owner to check their dashboard.

**Q: The upload stops when I lock my screen.**
- Some phones kill background apps aggressively to save battery.
- **Fix:** Go to Android Settings -> Apps -> SafeCopy -> Battery -> Select "Unrestricted" or "No Optimization".

**Q: Can I upload whole folders?**
- Currently, no. You must select individual files. Use a file manager app to zip a folder first, then upload the `.zip` file if needed.

**Q: Is my data safe?**
- Yes. Your data goes directly from Phone -> Desktop. It does NOT go to our company servers or any third-party cloud. You are in total control.
