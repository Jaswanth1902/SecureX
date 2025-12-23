# SafeCopy Technical FAQ

## 1. How is the encrypted file saved in RAM? How is it decrypted only in RAM?

**The encrypted file is never saved to the hard drive.**

*   **Network to Memory:** When the application downloads the file, the data streams directly from the network card into the application's **Heap Memory** (RAM). It is stored as a variable (a `String` or `Uint8List`), not as a file on the disk.
*   **No File I/O:** The code strictly avoids using any file system commands (like `File.writeAsBytes`). The operating system sees this data only as "active application memory."

**Decryption Process:**
1.  **Input:** The application takes the encrypted bytes from one memory location.
2.  **Processing:** The CPU runs the AES-256 algorithm on these bytes.
3.  **Output:** The result (the decrypted PDF) is written to a **new memory buffer** (`Uint8List`).
4.  **Display:** The PDF Viewer reads directly from this memory buffer to show the document.
5.  **Cleanup:** When the screen is closed, the memory is cleared by the Garbage Collector. Nothing remains on the disk.

---

## 2. If we are encrypting the "raw PDF", how is it converted back to bytes after decrypting?

**It doesn't need to be "converted"—it is already bytes.**

A PDF file is fundamentally just a long sequence of bytes (numbers like `0x25, 0x50, 0x44...`).

1.  **Original State:** The original PDF is a sequence of bytes.
2.  **Encryption:** We scramble those bytes using the AES algorithm. The result is "Encrypted Bytes" (garbage noise).
3.  **Decryption:** We use the Key to un-scramble the "Encrypted Bytes".
4.  **Result:** The output is the **exact same sequence of bytes** we started with.

**Analogy:**
Think of the PDF as a LEGO castle.
*   **Encryption:** We take the castle apart brick by brick and put them in a locked box.
*   **Decryption:** We unlock the box and reassemble the bricks exactly as they were.
*   **Result:** We have the castle again. We didn't "convert" it; we just restored the original structure.

---

## 3. How did we stop the "Save as PDF" option? (The Secure Print Agent)

We cannot modify the Windows System Dialog, so we **bypassed** it.

1.  **Custom Interface:** We hid the standard "Print" button and replaced it with a **"SECURE PRINT"** button.
2.  **Filtering:** When clicked, our code scans the list of available printers.
3.  **Blocking:** It programmatically removes any printer that contains "PDF", "XPS", "OneNote", or "Writer" in its name.
4.  **Direct Printing:** It forces the user to select from the remaining (physical) printers and sends the print job **directly** to that printer, skipping the standard dialog where "Save as PDF" would usually be an option.

---

## 4. Learn the math behind the decryption

**We use AES-256-GCM (Advanced Encryption Standard with Galois/Counter Mode).**

The math involves two main parts:

### A. The Core AES Block Cipher (The "Scrambler")
AES **always** operates on fixed **128-bit blocks** of data, regardless of the key size. The "256" in AES-256 refers to the **Key Size**, which determines how many times we repeat the scrambling process (14 rounds).

1.  **AddRoundKey:** The data is XORed with a part of the secret key.
    *   `State = State ⊕ RoundKey`
2.  **SubBytes (Substitution):** Each byte is replaced with another byte using a mathematical lookup table (S-Box). This is non-linear.
3.  **ShiftRows (Permutation):** Rows of the data matrix are shifted cyclically.
4.  **MixColumns (Linear Mixing):** Columns are combined using matrix multiplication.

This process is repeated 14 times (for 256-bit keys) to ensure the data is thoroughly scrambled.

### B. GCM (Galois/Counter Mode)
This turns the block cipher into a stream cipher and adds authentication.
1.  **Counter Mode (CTR):** Instead of encrypting the file directly, we encrypt a "Counter" (1, 2, 3...) to generate a stream of random-looking bytes (Keystream).
2.  **XOR:** We XOR this Keystream with your file data.
    *   `Ciphertext = Plaintext ⊕ AES(Key, Counter)`
    *   To decrypt, we just do it again: `Plaintext = Ciphertext ⊕ AES(Key, Counter)` (because `A ⊕ B ⊕ B = A`).
3.  **Galois Message Authentication Code (GMAC):** We use polynomial multiplication over $GF(2^{128})$ to generate an "Auth Tag". This ensures that if even one bit of the encrypted file is changed, the math won't add up, and we will reject the file (preventing tampering).
