import 'dart:convert';
import 'dart:typed_data';
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
      
      final aesKey = await keyService.decryptSymmetricKey(
        fileData.encryptedSymmetricKey,
        keyPair,
      );

      // 4. Decrypt File (AES Decryption)
      final encryptedBytes = base64Decode(fileData.encryptedFileData);
      final iv = base64Decode(fileData.ivVector);
      final authTag = base64Decode(fileData.authTag);

      final decrypted = await encryptionService.decryptFileAES256(
        encryptedBytes,
        iv,
        authTag,
        aesKey,
      );

      if (mounted) {
        setState(() {
          _decryptedBytes = decrypted;
          _isLoading = false;
        });
        // ignore: avoid_print
        print('==================================================');
        // ignore: avoid_print
        print('MEMORY CHECK: File loaded into RAM');
        // ignore: avoid_print
        print('Decrypted Size: ${_decryptedBytes!.length} bytes');
        // ignore: avoid_print
        print('Source: In-Memory Buffer (Uint8List)');
        // ignore: avoid_print
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

  Future<void> _handlePrinted(BuildContext context) async {
    try {
       final authService = context.read<AuthService>();
       final apiService = context.read<ApiService>();
       await apiService.deleteFile(widget.fileId, authService.accessToken!);
       
       if (!mounted) return;
       // ignore: use_build_context_synchronously
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('File deleted from server for security.')),
       );
       
       // Go back after short delay
       Future.delayed(const Duration(seconds: 2), () {
         if (mounted) {
           // ignore: use_build_context_synchronously
           Navigator.of(context).pop();
         }
       });
    } catch (e) {
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview: ${widget.fileName}'),
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
                  ? PdfPreview(
                      build: (format) => _decryptedBytes!,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                      onPrinted: (context) => _handlePrinted(context),
                    )
                  : const Center(child: Text('Decryption failed.')),
    );
  }
}
