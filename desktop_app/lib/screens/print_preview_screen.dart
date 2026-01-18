import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;

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
  bool _isLoading = true;
  String? _errorMessage;
  String? _errorDetails;
  Uint8List? _decryptedBytes;

  @override
  void initState() {
    super.initState();
    _processFile();
  }

  /// Robust Base64 decoder that handles:
  /// 1. URL-safe Base64 (- and _)
  /// 2. Missing padding
  /// 3. Whitespace/newlines
  Uint8List _decodeBase64(String input, String fieldName) {
    if (input.isEmpty) {
      throw FormatException('Field "$fieldName" is empty');
    }

    // 1. Convert URL-safe to standard
    String cleaned = input.replaceAll('-', '+').replaceAll('_', '/');
    
    // 2. Strip non-Base64 characters
    cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9+/=]'), '');
    
    // 3. Add padding if needed
    final padLength = (4 - (cleaned.length % 4)) % 4;
    cleaned += '=' * padLength;

    try {
      return base64Decode(cleaned);
    } catch (e) {
      debugPrint('DECODE ERROR [$fieldName]: $e');
      debugPrint('First 100 chars: ${input.substring(0, input.length > 100 ? 100 : input.length)}');
      throw FormatException('Invalid Base64 in "$fieldName"');
    }
  }

  Future<void> _processFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorDetails = null;
    });

    try {
      final authService = context.read<AuthService>();
      final apiService = context.read<ApiService>();
      final encryptionService = context.read<EncryptionService>();
      final keyService = context.read<KeyService>();

      // ========== STEP 1: FETCH FILE ==========
      debugPrint('>>> STEP 1: Fetching encrypted file...');
      final fileData = await apiService.getFileForPrinting(
        widget.fileId,
        authService.accessToken!,
      );
      debugPrint('    Encrypted data length: ${fileData.encryptedFileData.length}');
      debugPrint('    Symmetric key length: ${fileData.encryptedSymmetricKey.length}');

      if (!mounted) return;

      // ========== STEP 2: LOAD PRIVATE KEY ==========
      debugPrint('>>> STEP 2: Loading private key...');
      final userEmail = authService.user?['email'];
      if (userEmail == null) {
        throw StateError('User not authenticated');
      }

      final keyPair = await keyService.getStoredKeyPair(userEmail);
      if (keyPair == null) {
        throw StateError(
          'No private key found for $userEmail.\n\n'
          'This can happen if:\n'
          '1. You logged in on a new device\n'
          '2. App data was cleared\n'
          '3. You need to import your key backup'
        );
      }

      final privKey = keyPair.privateKey as pc.RSAPrivateKey;
      final pubKey = keyPair.publicKey as pc.RSAPublicKey;
      debugPrint('    Key Modulus (first 40 chars): ${pubKey.modulus.toString().substring(0, 40)}...');

      // ========== STEP 3: DECODE SYMMETRIC KEY ==========
      debugPrint('>>> STEP 3: Decoding encrypted symmetric key...');
      final encKeyBytes = _decodeBase64(fileData.encryptedSymmetricKey, 'encryptedSymmetricKey');
      debugPrint('    Decoded key bytes length: ${encKeyBytes.length}');
      
      // If the decoded length is not 256 bytes (2048-bit RSA), something is wrong
      if (encKeyBytes.length != 256) {
        debugPrint('    WARNING: Expected 256 bytes for RSA-2048, got ${encKeyBytes.length}');
      }

      // ========== STEP 4: RSA DECRYPTION ==========
      debugPrint('>>> STEP 4: RSA Decryption of symmetric key...');
      
      Uint8List? aesKey;
      final List<String> failedMethods = [];

      // Try OAEP + SHA-256 (expected)
      try {
        final rsa = enc.Encrypter(enc.RSA(
          publicKey: pubKey,
          privateKey: privKey,
          encoding: enc.RSAEncoding.OAEP,
          digest: enc.RSADigest.SHA256,
        ));
        aesKey = Uint8List.fromList(rsa.decryptBytes(enc.Encrypted(encKeyBytes)));
        debugPrint('    SUCCESS: OAEP/SHA-256');
      } catch (e) {
        failedMethods.add('OAEP+SHA256: $e');
      }

      // Fallback: OAEP + SHA-1
      if (aesKey == null) {
        try {
          final rsa = enc.Encrypter(enc.RSA(
            publicKey: pubKey,
            privateKey: privKey,
            encoding: enc.RSAEncoding.OAEP,
            digest: enc.RSADigest.SHA1,
          ));
          aesKey = Uint8List.fromList(rsa.decryptBytes(enc.Encrypted(encKeyBytes)));
          debugPrint('    SUCCESS: OAEP/SHA-1 (fallback)');
        } catch (e) {
          failedMethods.add('OAEP+SHA1: $e');
        }
      }

      // Fallback: PKCS1
      if (aesKey == null) {
        try {
          final rsa = enc.Encrypter(enc.RSA(
            publicKey: pubKey,
            privateKey: privKey,
            encoding: enc.RSAEncoding.PKCS1,
          ));
          aesKey = Uint8List.fromList(rsa.decryptBytes(enc.Encrypted(encKeyBytes)));
          debugPrint('    SUCCESS: PKCS1 (fallback)');
        } catch (e) {
          failedMethods.add('PKCS1: $e');
        }
      }

      if (aesKey == null) {
        debugPrint('    FAILED all RSA methods:');
        for (final m in failedMethods) {
          debugPrint('      - $m');
        }
        throw StateError(
          'RSA decryption failed.\n\n'
          'This usually means the file was encrypted with a different public key '
          'than the one stored on this device.\n\n'
          'Please ensure you are using the same account and device that was '
          'registered when the file was uploaded.'
        );
      }

      debugPrint('    AES Key length: ${aesKey.length} bytes');

      // ========== STEP 5: AES DECRYPTION ==========
      debugPrint('>>> STEP 5: AES-256-GCM Decryption...');
      
      final encFileBytes = _decodeBase64(fileData.encryptedFileData, 'encryptedFileData');
      final ivBytes = _decodeBase64(fileData.ivVector, 'ivVector');
      final authTagBytes = _decodeBase64(fileData.authTag, 'authTag');

      debugPrint('    Encrypted file: ${encFileBytes.length} bytes');
      debugPrint('    IV: ${ivBytes.length} bytes');
      debugPrint('    AuthTag: ${authTagBytes.length} bytes');

      final decrypted = await encryptionService.decryptFileAES256(
        encFileBytes,
        ivBytes,
        authTagBytes,
        aesKey,
      );

      if (decrypted == null) {
        throw StateError('AES decryption failed (AuthTag verification)');
      }

      debugPrint('>>> SUCCESS: Decrypted ${decrypted.length} bytes');

      if (mounted) {
        setState(() {
          _decryptedBytes = decrypted;
          _isLoading = false;
        });
      }

    } on FormatException catch (e) {
      _setError('Data Format Error', e.message);
    } on StateError catch (e) {
      _setError('Decryption Error', e.message);
    } catch (e, st) {
      debugPrint('UNEXPECTED ERROR: $e\n$st');
      _setError('Unexpected Error', e.toString());
    }
  }

  void _setError(String title, String details) {
    if (mounted) {
      setState(() {
        _errorMessage = title;
        _errorDetails = details;
        _isLoading = false;
      });
    }
  }

  // ========== PRINTING LOGIC ==========

  Future<void> _showPrinterDialog() async {
    final printers = await Printing.listPrinters();
    final physical = printers.where((p) {
      final n = p.name.toLowerCase();
      return !n.contains('pdf') && !n.contains('xps') && !n.contains('onenote') && !n.contains('fax');
    }).toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Printer'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: physical.isEmpty
              ? const Center(child: Text('No physical printers found'))
              : ListView.builder(
                  itemCount: physical.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(physical[i].name),
                    onTap: () {
                      Navigator.pop(ctx);
                      _print(physical[i]);
                    },
                  ),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<void> _print(Printer printer) async {
    if (_decryptedBytes == null) return;
    
    final authService = context.read<AuthService>();
    final apiService = context.read<ApiService>();

    try {
      // Update status: BEING_PRINTED
      await apiService.updateFileStatus(widget.fileId, 'BEING_PRINTED', authService.accessToken!);

      // Print
      final success = await Printing.directPrintPdf(
        printer: printer,
        onLayout: (_) async => _decryptedBytes!,
        name: widget.fileName,
      );

      if (!success) throw Exception('Print job failed');

      // Update status: PRINT_COMPLETED
      await apiService.updateFileStatus(widget.fileId, 'PRINT_COMPLETED', authService.accessToken!);

      // Delete file from server
      await apiService.deleteFile(widget.fileId, authService.accessToken!);

      // Clear RAM
      setState(() => _decryptedBytes = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printed and securely deleted'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ========== UI ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Print: ${widget.fileName}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: _isLoading
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Decrypting file...'),
                  ],
                )
              : _errorMessage != null
                  ? _buildErrorView()
                  : _buildReadyView(),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          _errorMessage!,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _errorDetails ?? '',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            textAlign: TextAlign.left,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _processFile,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildReadyView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 16),
        const Text('File Decrypted', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Select a printer to securely release this document.'),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          onPressed: _showPrinterDialog,
          icon: const Icon(Icons.print),
          label: const Text('SELECT PRINTER', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
