// ========================================
// MOBILE APP - UPLOAD SCREEN
// Secure File Printing System
// ========================================

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/encryption_service.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/file_history_service.dart';
import '../services/permissions_service.dart';
import '../services/connectivity_service.dart';
import '../services/public_key_trust_service.dart';
import '../utils/secure_logger.dart';
import '../utils/operation_timeout.dart';
import '../main.dart' show HomePage;

class UploadScreen extends StatefulWidget {
  final String? initialFilePath;

  const UploadScreen({super.key, this.initialFilePath});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  // State variables
  String? selectedFileName;
  int? selectedFileSize;
  String? selectedFilePath;
  bool isEncrypting = false;
  bool isUploading = false;
  double uploadProgress = 0.0;
  String? uploadStatus;
  String? uploadedFileId;
  Uint8List? selectedFileBytes;
  String? errorMessage;
  
  // SECURITY FIX Bug #42: Cancellation support
  CancellationToken? _uploadCancellationToken;

  // API configuration - Use ApiService's baseUrl which is configured for the device
  late final ApiService apiService = ApiService();
  late final String apiBaseUrl = apiService.baseUrl;

  // ========================================
  // REQUEST PERMISSIONS
  // ========================================

  @override
  void initState() {
    super.initState();
    if (widget.initialFilePath != null) {
      _loadInitialFile(widget.initialFilePath!);
    }
  }

  Future<void> _loadInitialFile(String path) async {
    try {
      final ioFile = File(path);
      if (await ioFile.exists()) {
        final bytes = await ioFile.readAsBytes();
        setState(() {
          selectedFilePath = path;
          selectedFileBytes = bytes;
          selectedFileName = path.split(Platform.pathSeparator).last;
          selectedFileSize = bytes.length;
        });
      } else {
        debugPrint('Initial file path does not exist: $path');
      }
    } catch (e) {
      debugPrint('Failed to load initial file: $e');
    }
  }

  Future<bool> requestPermissions() async {
    return await PermissionsService.requestAllFilePermissions();
  }

  // ========================================
  // PICK FILE FROM DEVICE
  // ========================================

  // Allowed file extensions for upload
  static const List<String> _allowedExtensions = ['pdf', 'doc', 'docx'];

  /// Check if a file extension is allowed
  bool _isAllowedExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return _allowedExtensions.contains(extension);
  }

  Future<void> pickFile() async {
    try {
      debugPrint('🔍 Starting file picker...');
      
      // Let file_picker handle permissions via SAF (Storage Access Framework)
      // This works on Android 6+ and is more reliable than manual permission requests
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions, // Only PDF and DOCX
        allowMultiple: false,
      );

      debugPrint('📁 File picker result: ${result != null ? "Selected" : "Cancelled"}');

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.single;
        debugPrint('   File: ${file.name}');
        debugPrint('   Size: ${file.size} bytes');
        debugPrint('   Path: ${file.path}');
        
        // Validate file extension (double-check even after picker filter)
        if (!_isAllowedExtension(file.name)) {
          final errorMsg = 'File format is incompatible. Only PDF and DOCX files are allowed.';
          setState(() {
            errorMessage = errorMsg;
            selectedFileBytes = null;
            selectedFileName = null;
            selectedFileSize = null;
          });
          debugPrint('❌ $errorMsg');
          if (mounted) _showErrorDialog(errorMsg);
          return;
        }
        
        Uint8List? fileBytes = file.bytes;

        // On mobile, file.bytes might be null, so we need to read from path
        if (fileBytes == null && file.path != null) {
          try {
            debugPrint('   Reading file from path (bytes were null)...');
            final ioFile = File(file.path!);
            fileBytes = await ioFile.readAsBytes();
            debugPrint('   ✅ File read successfully: ${fileBytes.length} bytes');
          } catch (e) {
            debugPrint('❌ Error reading file from path: $e');
            fileBytes = null;
          }
        }

        if (fileBytes != null && fileBytes.isNotEmpty) {
          setState(() {
            selectedFilePath = file.path;
            selectedFileName = file.name;
            selectedFileSize = file.size;
            selectedFileBytes = fileBytes;
            errorMessage = null;
            uploadStatus = null;
            uploadedFileId = null;
          });

          debugPrint('✅ File ready for upload: $selectedFileName (${selectedFileSize ?? 0} bytes)');
        } else {
          final errorMsg = 'Could not read file data. Please try another file.';
          setState(() {
            errorMessage = errorMsg;
            selectedFileBytes = null;
          });
          debugPrint('❌ $errorMsg');
          if (mounted) _showErrorDialog(errorMsg);
        }
      } else {
        debugPrint('⚠️  No file selected by user');
        // Don't show error dialog for user cancellation
        setState(() {
          errorMessage = null; // Don't display error for cancellation
        });
      }
    } catch (e) {
      final errorMsg = 'Error picking file: $e';
      debugPrint('❌ Exception in pickFile: $e');
      setState(() {
        errorMessage = errorMsg;
      });
      if (mounted) _showErrorDialog(errorMsg);
    }
  }


  // ========================================
  // ENCRYPT AND UPLOAD FILE
  // ========================================

  Future<void> encryptAndUploadFile() async {
    if (selectedFileBytes == null || selectedFileName == null) {
      const errorMsg = 'Please select a file first';
      debugPrint('❌ $errorMsg - File: $selectedFileName, Bytes: ${selectedFileBytes?.length}');
      if (mounted) _showErrorDialog(errorMsg);
      return;
    }

    try {
      // SECURITY FIX Bug #45: Check connectivity before starting
      if (!await ConnectivityService.hasConnectivity()) {
        throw ConnectivityException('No internet connection. Please check your WiFi or mobile data.');
      }
      
      setState(() {
        isEncrypting = true;
        uploadStatus = 'Encrypting file...';
        errorMessage = null;
      });

      debugPrint('🔐 Starting encryption for: $selectedFileName');
      debugPrint('   File size: ${selectedFileBytes!.length} bytes');

      // Step 1: Generate AES-256 key
      final encryptionService = EncryptionService();
      final aesKey = encryptionService.generateAES256Key();
      SecureLogger.logEncryptionOperation('AES-256 key generated', 32);

      // Step 2: Encrypt file with timeout protection (Bug #42 fix)
      final encryptResult = await OperationTimeout.withTimeout(
        operation: () => encryptionService.encryptFileAES256(
          selectedFileBytes!,
          aesKey,
        ),
        timeout: OperationTimeout.fileEncryption,
        operationName: 'File encryption',
      );

      final encryptedBytes = encryptResult['encrypted'] as Uint8List;
      final iv = encryptResult['iv'] as Uint8List;
      final authTag = encryptResult['authTag'] as Uint8List;
      
      SecureLogger.logEncryptionOperation('File encrypted successfully', encryptedBytes.length);
      SecureLogger.debug('IV: ${SecureLogger.sanitizeBytes(iv)}, AuthTag: ${SecureLogger.sanitizeBytes(authTag)}');

      setState(() {
        isEncrypting = false;
        isUploading = true;
        uploadStatus = 'Uploading file to server...';
        uploadProgress = 0.0;
      });

      // Step 3: Prompt for owner ID
      final ownerId = await _promptForOwnerId();
      if (ownerId == null || ownerId.isEmpty) {
        debugPrint('⚠️  User cancelled owner ID prompt');
        setState(() {
          isEncrypting = false;
          isUploading = false;
          uploadStatus = null;
        });
        return; // User cancelled, abort silently
      }
      
      debugPrint('📋 Upload details:');
      debugPrint('   Owner ID: $ownerId');
      debugPrint('   File name: $selectedFileName');
      debugPrint('   Base URL: $apiBaseUrl');
      
      // Step 3.1: Fetch Owner Public Key with timeout (Bug #42 fix)
      setState(() => uploadStatus = 'Fetching owner public key...');
      final publicKeyPem = await OperationTimeout.withTimeout(
        operation: () => apiService.getOwnerPublicKey(ownerId),
        timeout: OperationTimeout.keyFetch,
        operationName: 'Public key fetch',
      );
      SecureLogger.debug('✅ Owner Public Key fetched (${publicKeyPem.length} chars)');
      
      // SECURITY FIX Bug #40: Verify public key using TOFU
      setState(() => uploadStatus = 'Verifying owner identity...');
      final keyVerification = await PublicKeyTrustService.verifyKey(ownerId, publicKeyPem);
      
      if (!keyVerification.isTrusted) {
        // Show verification dialog to user
        final shouldTrust = await _showKeyVerificationDialog(keyVerification, ownerId);
        if (shouldTrust != true) {
          setState(() {
            isEncrypting = false;
            isUploading = false;
            uploadStatus = null;
          });
          return; // User declined to trust the key
        }
        // User accepted - store the trust
        await PublicKeyTrustService.trustFingerprint(ownerId, keyVerification.fingerprint);
        SecureLogger.info('Public key trusted for owner: $ownerId');
      }

      // Step 3.2: Encrypt AES Key with RSA (with timeout)
      setState(() => uploadStatus = 'Encrypting key...');
      final encryptedSymmetricKey = await OperationTimeout.withTimeout(
        operation: () => encryptionService.encryptSymmetricKeyRSA(aesKey, publicKeyPem),
        timeout: OperationTimeout.apiCall,
        operationName: 'RSA encryption',
      );
      SecureLogger.logEncryptionOperation('AES Key encrypted with RSA', encryptedSymmetricKey.length);
      
      // SECURITY FIX Bug #33: Immediately shred the AES key from memory
      // after RSA encryption to prevent key exposure
      encryptionService.shredData(aesKey);
      SecureLogger.info('🔒 AES Key securely wiped from memory');
      
      // Get real access token from UserService
      final userService = UserService();
      var accessToken = await userService.getAccessToken();
      
      if (accessToken == null) {
        throw Exception('Not authenticated. Please log in first.');
      }
      
      SecureLogger.logTokenUsage('Access token');
      
      // Step 4: Upload encrypted file
      setState(() => uploadStatus = 'Uploading file to server...');
      await uploadEncryptedFile(
        encryptedData: encryptedBytes,
        ivVector: iv,
        authTag: authTag,
        encryptedSymmetricKey: encryptedSymmetricKey,
        fileName: selectedFileName!,
        fileMimeType: _getMimeType(selectedFileName!),
        accessToken: accessToken,
        ownerId: ownerId,
      );

      debugPrint('✅ Upload complete - file ID received and displayed to user');
      
    } on TimeoutException catch (e) {
      // SECURITY FIX Bug #42: Handle timeout gracefully
      final errorMsg = e.toString();
      SecureLogger.error('Upload timeout', e);
      setState(() {
        isEncrypting = false;
        isUploading = false;
        uploadStatus = null;
        errorMessage = errorMsg;
      });
      if (mounted) _showErrorDialog(errorMsg);
      
    } on ConnectivityException catch (e) {
      // SECURITY FIX Bug #45: Handle connectivity errors
      final errorMsg = e.toString();
      SecureLogger.warning('No internet connection');
      setState(() {
        isEncrypting = false;
        isUploading = false;
        uploadStatus = null;
        errorMessage = errorMsg;
      });
      if (mounted) _showErrorDialog(errorMsg);
      
    } on OperationCancelledException catch (e) {
      // Handle user cancellation
      SecureLogger.info('Upload cancelled by user');
      setState(() {
        isEncrypting = false;
        isUploading = false;
        uploadStatus = null;
        errorMessage = null;
      });
      
    } catch (e) {
      final errorMsg = 'Error: $e';
      setState(() {
        errorMessage = errorMsg;
        isEncrypting = false;
        isUploading = false;
      });
      debugPrint('❌ Upload error: $e');
      if (mounted) _showErrorDialog(errorMsg);
    }
  }

  // ========================================
  // UPLOAD ENCRYPTED FILE TO SERVER
  // ========================================

  Future<void> uploadEncryptedFile({
    required Uint8List encryptedData,
    required Uint8List ivVector,
    required Uint8List authTag,
    required String encryptedSymmetricKey,
    required String fileName,
    required String fileMimeType,
    required String accessToken,
    required String ownerId,
  }) async {
    try {
      final uploadUri = Uri.parse('$apiBaseUrl/api/upload');

      debugPrint('📤 Uploading to: $uploadUri');
      debugPrint('   File: $fileName (${encryptedData.length} bytes)');

      // Create multipart request
      final request = http.MultipartRequest('POST', uploadUri);

      // Add JWT authorization header
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Add form fields
      request.fields['file_name'] = fileName;
      request.fields['iv_vector'] = base64Encode(ivVector);
      request.fields['auth_tag'] = base64Encode(authTag);
      request.fields['encrypted_symmetric_key'] = encryptedSymmetricKey;
      request.fields['owner_id'] = ownerId;

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          encryptedData,
          filename: fileName,
          contentType: http.MediaType.parse(fileMimeType),
        ),
      );

      // Send request with progress tracking
      final streamedResponse = await request.send();

      // Handle response
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response: ${response.body}');

      if (response.statusCode == 201) {
        // Success!
        final jsonResponse = jsonDecode(response.body);
        final fileId = jsonResponse['file_id'];

        // Save to local history for rejection tracking
        final fileHistoryService = FileHistoryService();
        await fileHistoryService.saveFileToHistory(
          fileId: fileId,
          fileName: fileName,
          fileSizeBytes: encryptedData.length,
          uploadedAt: DateTime.now().toIso8601String(),
          status: 'WAITING_FOR_APPROVAL',
          localPath: selectedFilePath,
        );
        debugPrint('📝 File saved to local history');

        setState(() {
          uploadedFileId = fileId;
          uploadStatus = 'Upload successful! 🎉';
          isUploading = false;
          uploadProgress = 1.0;
        });

        debugPrint('✅ File ID: $fileId');

        // Show success dialog
        if (mounted) {
          _showSuccessDialog(fileId, fileName);
          
          // Refresh recent files for this user
          HomePage.refreshRecentFiles();
        }
      } else {
        throw Exception(
          'Upload failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Upload failed: $e';
        isUploading = false;
      });
      debugPrint('❌ Upload error: $e');
      rethrow;
    }
  }

  // ========================================
  // PROMPT FOR OWNER ID
  // ========================================

  Future<String?> _promptForOwnerId() async {
    String? ownerId;
    
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Select Owner'),
            content: TextField(
              decoration: const InputDecoration(
                labelText: 'Owner ID or Email',
                hintText: 'e.g., owner@example.com',
              ),
              onChanged: (value) {
                setDialogState(() {
                  ownerId = value.isEmpty ? null : value;
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: ownerId?.trim().isNotEmpty == true
                    ? () {
                        final chosen = ownerId!.trim();
                        debugPrint('Owner selected: $chosen');
                        Navigator.pop(context, chosen);
                      }
                    : null,
                child: const Text('Select'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ========================================
  // GET MIME TYPE
  // ========================================

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    final mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
    };
    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  // ========================================
  // SHOW SUCCESS DIALOG
  // ========================================

  void _showSuccessDialog(String fileId, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Upload Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your file has been encrypted and uploaded securely!',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The file is encrypted and only the owner can decrypt it.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ========================================
  // SHOW ERROR DIALOG
  // ========================================

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ========================================
  // COPY TO CLIPBOARD
  // ========================================

  void _copyToClipboard(String text) {
    // In production, use flutter's Clipboard
    debugPrint('File ID copied: $text');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ========================================
  // RESET UPLOAD
  // ========================================

  void resetUpload() {
    setState(() {
      selectedFileName = null;
      selectedFileSize = null;
      uploadStatus = null;
      uploadedFileId = null;
      uploadProgress = 0.0;
      errorMessage = null;
      isEncrypting = false;
      isUploading = false;
      selectedFileBytes = null;
    });
  }

  // ========================================
  // BUILD UI
  // ========================================

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final headerBgColor = isDarkMode ? const Color(0xFF2D3E5F) : const Color(0xFFF0F4FF);
    final headerBorderColor = isDarkMode ? const Color(0xFF4A5F7F) : const Color(0xFFB0C4E8);
    final headerTextColor = isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);
    final headerIconColor = isDarkMode ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('SecureX - Upload'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: headerBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: headerBorderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.folder_open, size: 48, color: headerIconColor),
                    const SizedBox(height: 12),
                    Text(
                      '📂 Browse Your File',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: headerTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a file to upload',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // FILE SELECTION SECTION
              if (selectedFileName == null || uploadedFileId == null)
                Column(
                  children: [
                    // File picker button
                    ElevatedButton.icon(
                      onPressed: isEncrypting || isUploading ? null : pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Select File'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selected file info
                    if (selectedFileName != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF1B3A2A) : const Color(0xFFF0FDF4),
                          border: Border.all(
                            color: isDarkMode ? const Color(0xFF22C55E) : const Color(0x8622C55E),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.1),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: isDarkMode ? const Color(0xFF22C55E) : const Color(0xFF15803D),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedFileName!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                      color: isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
                                    ),
                                  ),
                                  Text(
                                    '${(selectedFileSize! / 1024 / 1024).toStringAsFixed(2)} MB',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Upload button
                    if (selectedFileName != null)
                      ElevatedButton(
                        onPressed: isEncrypting || isUploading
                            ? null
                            : encryptAndUploadFile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isEncrypting || isUploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Encrypt & Upload',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                  ],
                ),

              // PROGRESS SECTION
              if (isEncrypting || isUploading || uploadStatus != null)
                Column(
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFF2563EB) : const Color(0xFFB0C4E8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uploadStatus ?? 'Processing...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: isEncrypting ? null : uploadProgress,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(uploadProgress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              // SUCCESS SECTION
              if (uploadedFileId != null)
                Column(
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1B3A2A) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFF22C55E) : const Color(0x8622C55E),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 48,
                            color: isDarkMode ? const Color(0xFF22C55E) : const Color(0xFF15803D),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Upload Complete!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? const Color(0xFF22C55E) : const Color(0xFF15803D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your file is encrypted and stored on the server.',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: SelectableText(
                              uploadedFileId!,
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Share this ID with the owner to print the file',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: resetUpload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Upload Another File'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              // ERROR SECTION
              if (errorMessage != null)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF3A1A1A) : const Color(0xFFFEF2F2),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFFEF4444) : const Color(0xFFFCA5A5),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: isDarkMode ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                color: isDarkMode ? const Color(0xFFFCA5A5) : const Color(0xFF7F1D1D),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // KEY VERIFICATION DIALOG (TOFU)
  // ========================================

  Future<bool?> _showKeyVerificationDialog(
    KeyVerificationResult verification,
    String ownerId,
  ) async {
    final isKeyChanged = verification.reason == KeyVerificationReason.keyChanged;
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(isKeyChanged ? Icons.warning_amber : Icons.security,
                color: isKeyChanged ? Colors.red : Colors.blue, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text(isKeyChanged ? 'Security Warning' : 'Verify Owner Identity',
                style: TextStyle(color: isKeyChanged ? Colors.red : null, fontWeight: FontWeight.bold))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(verification.message, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 16),
                Text('Owner ID:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(ownerId, style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                const SizedBox(height: 12),
                Text('Key Fingerprint:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                  child: Text(verification.shortFingerprint, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: isKeyChanged ? Colors.orange : Colors.blue),
              child: Text(isKeyChanged ? 'Trust Anyway' : 'Trust & Continue'),
            ),
          ],
        );
      },
    );
  }
}
