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
      final fileData = await apiService.getFileForPrinting(
        widget.fileId,
        authService.accessToken!,
      );

      print('DEBUG: DOWNLOAD COMPLETE. File size: ${fileData.encryptedFileData.length} bytes');

      if (!mounted) return;

      // 2. Get Local Private Key
      final keyPair = await keyService.getStoredKeyPair();
      if (keyPair == null) {
        throw Exception('Private key not found. Cannot decrypt.');
      }

      // 3. Decrypt the AES Key (RSA Decryption)
      if (fileData.encryptedSymmetricKey.isEmpty) {
         throw Exception('No encrypted key found for this file.');
      }
      
      print('DEBUG: Decrypting Symmetric Key...');
      print('DEBUG: Key Length: ${fileData.encryptedSymmetricKey.length}');
      print('DEBUG: Key Value (First 50): ${fileData.encryptedSymmetricKey.substring(0, min(50, fileData.encryptedSymmetricKey.length))}');

      Uint8List aesKey;
      try {
        aesKey = await keyService.decryptSymmetricKey(
          fileData.encryptedSymmetricKey,
          keyPair,
        );
        print('DEBUG: Symmetric Key Decrypted Successfully (${aesKey.length} bytes)');
      } catch (e) {
        print('CRITICAL ERROR: Failed to decrypt symmetric key');
        print('Error: $e');
        rethrow;
      }

      // 4. Decrypt File (AES Decryption)
      print('DEBUG: Starting decoding...');
      print('DEBUG: Encrypted Data Length: ${fileData.encryptedFileData.length}');
      print('DEBUG: IV Length: ${fileData.ivVector.length}');
      print('DEBUG: Auth Tag Length: ${fileData.authTag.length}');

      Uint8List encryptedBytes;
      try {
        encryptedBytes = base64Decode(fileData.encryptedFileData);
        print('DEBUG: Encrypted Bytes Decoded Successfully (${encryptedBytes.length} bytes)');
      } catch (e) {
        print('CRITICAL ERROR: Failed to decode encryptedFileData');
        print('First 50 chars: ${fileData.encryptedFileData.substring(0, 50)}');
        rethrow;
      }

      Uint8List iv;
      try {
        iv = base64Decode(fileData.ivVector);
        print('DEBUG: IV Decoded Successfully (${iv.length} bytes)');
      } catch (e) {
        print('CRITICAL ERROR: Failed to decode ivVector');
        print('Value: ${fileData.ivVector}');
        rethrow;
      }

      Uint8List authTag;
      try {
        authTag = base64Decode(fileData.authTag);
        print('DEBUG: Auth Tag Decoded Successfully (${authTag.length} bytes)');
      } catch (e) {
        print('CRITICAL ERROR: Failed to decode authTag');
        print('Value: ${fileData.authTag}');
        rethrow;
      }

      final decrypted = await encryptionService.decryptFileAES256(
        encryptedBytes,
        iv,
        authTag,
        aesKey,
      );
      
      print('DEBUG: Decryption successful!');

      if (mounted) {
        setState(() {
          _decryptedBytes = decrypted;
          _isLoading = false;
        });
        print('==================================================');
        print('MEMORY CHECK: File loaded into RAM');
        print('Decrypted Size: ${_decryptedBytes!.length} bytes');
        print('Source: In-Memory Buffer (Uint8List)');
        print('==================================================');
      }

    } catch (e) {
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
       
       // Update status to REJECTED if file was rejected (not printed)
       if (wasRejected) {
         await apiService.updateFileStatus(
           widget.fileId,
           'REJECTED',
           authService.accessToken!,
           rejectionReason: 'Rejected by owner',
         );
         print('Status updated to REJECTED');
       }
       
       await apiService.deleteFile(widget.fileId, authService.accessToken!);
       
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('File deleted from server for security.')),
       );
       
       // Go back after short delay
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

    // 2. Filter out "Virtual" printers (PDF, XPS, OneNote, etc.)
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
                        Navigator.of(context).pop(); // Close dialog
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
      // Update status to BEING_PRINTED
      await apiService.updateFileStatus(
        widget.fileId,
        'BEING_PRINTED',
        authService.accessToken!,
      );
      print('Status updated to BEING_PRINTED');

      // Send to printer
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) async => _decryptedBytes!,
      );

      if (!mounted) return;
      
      // Update status to APPROVED after successful print
      await apiService.updateFileStatus(
        widget.fileId,
        'APPROVED',
        authService.accessToken!,
      );
      print('Status updated to APPROVED');
      
      // Success - Delete file
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
      appBar: AppBar(
        title: Text('Secure Print: ${widget.fileName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAndDecrypt,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _decryptedBytes != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, size: 80, color: Colors.green),
                          const SizedBox(height: 24),
                          const Text(
                            'File Decrypted Successfully',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.fileName,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
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
                          const SizedBox(height: 16),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline, color: Colors.amber.shade700),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'File is held in RAM only. No preview available for security.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(child: Text('Decryption failed.')),
    );
  }
}
