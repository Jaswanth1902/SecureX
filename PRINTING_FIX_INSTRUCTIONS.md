# Instructions for Fixing Printing Service (Updated)

I have a working implementation of the Printing Service in another instance of this project (`SafeCopy_Animation`). Please analyze the following files and implementation details to fix the printing service in the current workspace.

### 1. Overview
The printing functionality is implemented on the Client Side (Desktop App) using the `printing` and `pdf` Flutter packages. It does not rely on a separate background "service" file like `printer_service.dart` in this version; instead, the logic is encapsulated within `desktop_app/lib/screens/print_preview_screen.dart`.

### 2. Dependencies
Ensure `desktop_app/pubspec.yaml` has these versions:
```yaml
dependencies:
  printing: ^5.14.2
  pdf: ^3.11.3
  pointycastle: ^3.9.1
  # ... other deps
```

### 3. Implementation Logic
The **`PrintPreviewScreen`** handles the entire flow:
1.  **Fetch & Decrypt**:
    *   Gets metadata and encrypted file content from the API.
    *   Decrypts the symmetric key using the user's RSA Private Key.
    *   Decrypts the file content using AES-256-GCM.
    *   Stores the decrypted PDF/Image in memory (`Uint8List`).
2.  **Print**:
    *   Lists physical printers using `Printing.listPrinters()` (filtering out virtual ones like 'Microsoft Print to PDF').
    *   Sends the decrypted bytes directly to the selected printer using `Printing.directPrintPdf`.
3.  **Cleanup**:
    *   Updates file status to `PRINT_COMPLETED`.
    *   Deletes the file from the server.
    *   Clears the decrypted bytes from RAM.

### 4. Working Code: `print_preview_screen.dart`
Here is the full working code for `desktop_app/lib/screens/print_preview_screen.dart`. **Replace the existing code with this.**
(This version includes extra robust debugging for decoding errors).

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/encryption_service.dart';
import '../services/key_service.dart';

class PrintPreviewScreen extends StatefulWidget {
  final String fileId;
  final String fileName;

  const PrintPreviewScreen({
    super.key,
    required this.fileId,
    required this.fileName,
  });

  @override
  State<PrintPreviewScreen> createState() => _PrintPreviewScreenState();
}

class _PrintPreviewScreenState extends State<PrintPreviewScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _decryptedBytes;

  @override
  void initState() {
    super.initState();
    _fetchAndDecrypt();
  }

  // Helper for safe decoding
  Uint8List _safeDecode(String input, String fieldName) {
    try {
      return base64Decode(input);
    } catch (e) {
      print('CRITICAL ERROR: Failed to decode $fieldName');
      // Print first 50 chars to debug
      final preview = input.length > 50 ? '${input.substring(0, 50)}...' : input;
      print('Value preview: $preview');
      throw Exception('Invalid Base64 in $fieldName: $e');
    }
  }

  Future<void> _fetchAndDecrypt() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final apiService = context.read<ApiService>();
      final encryptionService = context.read<EncryptionService>();
      final keyService = context.read<KeyService>();

      // 1. Fetch Encrypted File & Key
      print('DEBUG: Fetching file ${widget.fileId}...');
      final fileData = await apiService.getFileForPrinting(
        widget.fileId,
        authService.accessToken!,
      );

      print('DEBUG: DOWNLOAD COMPLETE. File size: ${fileData.encryptedFileData.length} bytes');

      if (!mounted) return;

      // 2. Get Local Private Key
      final userEmail = authService.user?['email'];
      if (userEmail == null) throw Exception('User not authenticated.');

      final keyPair = await keyService.getStoredKeyPair(userEmail);
      if (keyPair == null) {
        throw Exception('Private key not found. Cannot decrypt.');
      }

      // 3. Decrypt the AES Key (RSA Decryption)
      if (fileData.encryptedSymmetricKey.isEmpty) {
         throw Exception('No encrypted key found for this file.');
      }
      
      print('DEBUG: Decrypting Symmetric Key...');
      Uint8List aesKey;
      try {
        aesKey = await keyService.decryptSymmetricKey(
          fileData.encryptedSymmetricKey,
          keyPair,
        );
        print('DEBUG: Symmetric Key Decrypted Successfully (${aesKey.length} bytes)');
      } catch (e) {
        print('CRITICAL ERROR: Failed to decrypt symmetric key: $e');
        rethrow;
      }

      // 4. Decrypt File (AES Decryption)
      print('DEBUG: Starting decoding of file components...');
      
      // Use safe decoder to pinpoint error
      Uint8List encryptedBytes = _safeDecode(fileData.encryptedFileData, 'encryptedFileData');
      Uint8List iv = _safeDecode(fileData.ivVector, 'ivVector');
      Uint8List authTag = _safeDecode(fileData.authTag, 'authTag');

      print('DEBUG: Components decoded. Decrypting content...');
      final decrypted = await encryptionService.decryptFileAES256(
        encryptedBytes,
        iv,
        authTag,
        aesKey,
      );

      if (decrypted == null) {
        throw Exception('Decryption failed: integrity check (AuthTag) mismatch.');
      }
      
      print('DEBUG: Decryption successful!');

      if (mounted) {
        setState(() {
          _decryptedBytes = decrypted;
          _isLoading = false;
        });
      }

    } catch (e) {
      print('ERROR IN FETCH/DECRYPT: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePrinted(BuildContext context, {bool wasRejected = false}) async {
    try {
       final authService = context.read<AuthService>();
       final apiService = context.read<ApiService>();
       
       if (wasRejected) {
         await apiService.updateFileStatus(
           widget.fileId,
           'REJECTED',
           authService.accessToken!,
           rejectionReason: 'Rejected by owner',
         );
       }
       
       await apiService.deleteFile(widget.fileId, authService.accessToken!);
       
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('File deleted from server for security.')),
       );
       
       Future.delayed(const Duration(seconds: 2), () {
         if (mounted) Navigator.of(context).pop();
       });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete file: $e')),
        );
      }
    }
  }

  Future<void> _showSecurePrintDialog() async {
    // 1. Fetch all printers
    final printers = await Printing.listPrinters();

    // 2. Filter out "Virtual" printers
    final physicalPrinters = printers.where((p) {
      final name = p.name.toLowerCase();
      return !name.contains('pdf') &&
             !name.contains('xps') &&
             !name.contains('onenote') &&
             !name.contains('writer') &&
             !name.contains('fax');
    }).toList();

    if (!mounted) return;

    // 3. Show selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Physical Printer'),
        content: SizedBox(
          width: double.maxFinite,
          child: physicalPrinters.isEmpty
              ? const Text('No physical printers found.\nPlease connect a printer.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: physicalPrinters.length,
                  itemBuilder: (context, index) {
                    final printer = physicalPrinters[index];
                    return ListTile(
                      leading: const Icon(Icons.print),
                      title: Text(printer.name),
                      subtitle: Text(printer.url),
                      onTap: () {
                        Navigator.of(context).pop();
                        _securePrintTo(printer);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _securePrintTo(Printer printer) async {
    if (_decryptedBytes == null) return;
    final authService = context.read<AuthService>();
    final apiService = context.read<ApiService>();

    try {
      await apiService.updateFileStatus(
        widget.fileId,
        'BEING_PRINTED',
        authService.accessToken!,
      );

      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) async => _decryptedBytes!,
      );

      if (!mounted) return;
      
      await apiService.updateFileStatus(
        widget.fileId,
        'PRINT_COMPLETED',
        authService.accessToken!,
      );
      
      if (mounted) {
        setState(() {
          _decryptedBytes = null; // Clear from RAM
        });
      }
      _handlePrinted(context);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Printing failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Secure Print: ${widget.fileName}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         const Icon(Icons.error_outline, size: 48, color: Colors.red),
                         const SizedBox(height: 16),
                         Text('Error: $_errorMessage', textAlign: TextAlign.center),
                         const SizedBox(height: 16),
                         ElevatedButton(
                           onPressed: _fetchAndDecrypt,
                           child: const Text('Retry'),
                         )
                      ],
                    ),
                  ),
                )
              : _decryptedBytes != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, size: 80, color: Colors.green),
                          const SizedBox(height: 24),
                          const Text('Ready to Print', style: TextStyle(fontSize: 24)),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                            icon: const Icon(Icons.print, size: 28),
                            label: const Text('SECURE PRINT', style: TextStyle(fontSize: 18)),
                            onPressed: _showSecurePrintDialog,
                          ),
                        ],
                      ),
                    )
                  : const Center(child: Text('Decryption failed.')),
    );
  }
}
```
