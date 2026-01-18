# Understanding the "Decryption / Decoding Error"

If you see an error like `Invalid argument(s): decoding error` or `RSA Decryption failed` again, here is exactly what is happening.

## The Simple Explanation
Imagine you have a physical safe.
1.  **Upload**: You put a file in the safe and locked it with **Lock A**.
2.  **Key Change**: You lost **Key A** (e.g., cleared app data or switched PCs), so the app gave you a new **Key B**.
3.  **Download**: You tried to open the "Lock A" safe with your new "Key B".
4.  **Error**: The key didn't turn. The error message was just the computer saying "This key doesn't work".

## The Technical Explanation

### 1. The Misleading Error Message
The error `decoding error` comes from the underlying math library.
-   **What you might think:** "The text is corrupted or not valid Base64."
-   **What it actually means:** "The RSA mathematical operation produced a result, but the padding check failed."

RSA encryption adds specific "padding" bytes to data before encrypting. When decrypting, if the private key doesn't match the public key used for encryption, the math produces random garbage output. The code looks for the expected padding structure in that garbage, doesn't find it, and throws a "decoding error".

### 2. Why Did the Keys Mismatch?
Your system uses **Asymmetric Encryption** (Public/Private Keys).
-   **Public Key**: Shared with the server. Used by the mobile app to **Encrypt**.
-   **Private Key**: Stored **ONLY** on your desktop. Used to **Decrypt**.

**The Critical Gap:**
The server *never* has your Private Key (for security). If you uninstall the desktop app, clear its data, or log in on a new computer, your Private Key is deleted. The app then generates a **brand new key pair**.

Any files encrypted before this moment are still locked with the **Old Public Key**. Your **New Private Key** cannot unlock them.

## Future Solutions

### 1. Immediate Fix (If it happens again)
If a specific file fails with this error:
-   **Delete the file.** It is permanently lost because the key to open it is gone.
-   **Re-upload the file.** The mobile app will fetch your *current* Public Key and encrypt the new copy correctly.

### 2. Prevention (The Backup Feature)
This is why we planned the **Key Backup** feature.
-   It lets you save your Private Key to a file (`.safecopy-key`).
-   If you switch computers, you "Import" that file instead of generating a new key.
-   This keeps your identity consistent so you can always open your old files.
