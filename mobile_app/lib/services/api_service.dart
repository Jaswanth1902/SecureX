// ========================================
// API SERVICE - HTTP COMMUNICATION
// Handles all backend API calls
// ========================================

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class ApiService {
  // NOTE: IP Configuration for different environments:
  // Device on same WiFi (192.168.0.X network):
  static const String WIFI_IP = '192.168.0.103';
  
  // Device connected to Ethernet (192.168.56.X network):
  static const String ETHERNET_IP = '192.168.56.1';
  
  // Android Emulator on same PC:
  static const String EMULATOR_IP = '10.0.2.2';
  
  // Currently using WiFi IP - change to ETHERNET_IP if device is on that network
  static const String BACKEND_IP = WIFI_IP;
  static const int BACKEND_PORT = 5000;
  
  final String baseUrl = 'http://$BACKEND_IP:$BACKEND_PORT';

  // ========================================
  // USER REGISTRATION
  // ========================================

  Future<RegisterResponse> registerUser({
    required String phone,
    required String password,
    String? fullName,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/register');
      print('🔄 Registering to: $url');
      print('📦 Payload: phone=$phone, fullName=$fullName');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
          if (fullName != null) 'full_name': fullName,
        }),
      );

      print('📨 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return RegisterResponse.fromJson(json);
      } else {
        try {
          final json = jsonDecode(response.body);
          final errorMsg = json['error'] ?? json['message'] ?? 'Registration failed: ${response.statusCode}';
          print('❌ Error from backend: $errorMsg');
          throw ApiException(
            errorMsg is String ? errorMsg : 'Registration failed: ${response.statusCode}',
            response.statusCode,
          );
        } catch (e) {
          if (e is ApiException) rethrow;
          print('❌ Failed to parse error response: $e');
          throw ApiException('Registration failed: ${response.statusCode}', response.statusCode);
        }
      }
    } catch (e) {
      print('❌ Registration exception: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Registration error: $e', -1);
    }
  }

  // ========================================
  // USER LOGIN
  // ========================================

  Future<LoginResponse> loginUser({
    required String phone,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/login');
      print('🔄 Logging in to: $url');
      print('📦 Payload: phone=$phone');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      print('📨 Response Status: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return LoginResponse.fromJson(json);
      } else {
        try {
          final json = jsonDecode(response.body);
          final errorMsg = json['error'] ?? json['message'] ?? 'Login failed: ${response.statusCode}';
          print('❌ Error from backend: $errorMsg');
          throw ApiException(
            errorMsg is String ? errorMsg : 'Login failed: ${response.statusCode}',
            response.statusCode,
          );
        } catch (e) {
          if (e is ApiException) rethrow;
          print('❌ Failed to parse error response: $e');
          throw ApiException('Login failed: ${response.statusCode}', response.statusCode);
        }
      }
    } catch (e) {
      print('❌ Login exception: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Login error: $e', -1);
    }
  }

  // ========================================
  // RESET PASSWORD
  // ========================================

  Future<void> resetPassword({
    required String phone,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/reset-password');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final json = jsonDecode(response.body);
        throw ApiException(
          json['message'] ?? 'Password reset failed: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Reset password error: $e', -1);
    }
  }

  // ========================================
  // GET OWNER PUBLIC KEY
  // ========================================

  Future<String> getOwnerPublicKey(String ownerId) async {
    try {
      // Correct URL: /api/owners/public-key/:ownerId
      final url = Uri.parse('$baseUrl/api/owners/public-key/$ownerId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['publicKey'];
      } else {
        throw ApiException(
          'Failed to get public key: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Get public key error: $e', -1);
    }
  }

  // ========================================
  // UPLOAD FILE
  // ========================================

  Future<UploadResponse> uploadFile({
    required Uint8List encryptedData,
    required Uint8List ivVector,
    required Uint8List authTag,
    required String encryptedSymmetricKey,
    required String fileName,
    required String fileMimeType,
    required String accessToken,
    required String ownerId,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/upload');

      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Add fields
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

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return UploadResponse.fromJson(json);
      } else {
        throw ApiException(
          'Upload failed: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Upload error: $e', -1);
    }
  }

  // ========================================
  // LIST FILES
  // ========================================

  Future<List<FileItem>> listFiles({required String accessToken}) async {
    try {
      final url = Uri.parse('$baseUrl/api/files');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final files = (json['files'] as List)
            .map((f) => FileItem.fromJson(f))
            .toList();
        return files;
      } else {
        throw ApiException(
          'Failed to list files: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('List files error: $e', -1);
    }
  }

  // ========================================
  // GET FILE FOR PRINTING
  // ========================================

  Future<PrintFileResponse> getFileForPrinting({
    required String fileId,
    required String accessToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/print/$fileId');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return PrintFileResponse.fromJson(json);
      } else {
        throw ApiException(
          'Failed to get file: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Get file error: $e', -1);
    }
  }

  // ========================================
  // DELETE FILE
  // ========================================

  Future<DeleteResponse> deleteFile({
    required String fileId,
    required String accessToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/delete/$fileId');
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return DeleteResponse.fromJson(json);
      } else {
        throw ApiException(
          'Failed to delete file: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ApiException('Delete file error: $e', -1);
    }
  }

  // ========================================
  // CHECK HEALTH
  // ========================================

  Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// ========================================
// RESPONSE MODELS
// ========================================

class UploadResponse {
  final bool success;
  final String fileId;
  final String fileName;
  final int fileSizeBytes;
  final String uploadedAt;
  final String status;
  final String statusUpdatedAt;
  final String message;

  UploadResponse({
    required this.success,
    required this.fileId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.uploadedAt,
    required this.status,
    required this.statusUpdatedAt,
    required this.message,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      success: json['success'] ?? false,
      fileId: json['file_id'] ?? '',
      fileName: json['file_name'] ?? '',
      fileSizeBytes: json['file_size_bytes'] ?? 0,
      uploadedAt: json['uploaded_at'] ?? '',
      status: json['status'] ?? 'UNKNOWN',
      statusUpdatedAt: json['status_updated_at'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

class FileItem {
  final String fileId;
  final String fileName;
  final int fileSizeBytes;
  final String uploadedAt;
  final bool isPrinted;
  final String? printedAt;
  final String status;
  final String statusUpdatedAt;
  final String? rejectionReason;

  FileItem({
    required this.fileId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.uploadedAt,
    required this.isPrinted,
    this.printedAt,
    required this.status,
    required this.statusUpdatedAt,
    this.rejectionReason,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      fileId: json['file_id'] ?? '',
      fileName: json['file_name'] ?? '',
      fileSizeBytes: json['file_size_bytes'] ?? 0,
      uploadedAt: json['uploaded_at'] ?? '',
      isPrinted: json['is_printed'] ?? false,
      printedAt: json['printed_at'],
      status: json['status'] ?? 'UNKNOWN',
      statusUpdatedAt: json['status_updated_at'] ?? '',
      rejectionReason: json['rejection_reason'],
    );
  }
}

class PrintFileResponse {
  final bool success;
  final String fileId;
  final String fileName;
  final int fileSizeBytes;
  final String uploadedAt;
  final bool isPrinted;
  final String encryptedFileData;
  final String ivVector;
  final String authTag;
  final String message;

  PrintFileResponse({
    required this.success,
    required this.fileId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.uploadedAt,
    required this.isPrinted,
    required this.encryptedFileData,
    required this.ivVector,
    required this.authTag,
    required this.message,
  });

  factory PrintFileResponse.fromJson(Map<String, dynamic> json) {
    return PrintFileResponse(
      success: json['success'] ?? false,
      fileId: json['file_id'] ?? '',
      fileName: json['file_name'] ?? '',
      fileSizeBytes: json['file_size_bytes'] ?? 0,
      uploadedAt: json['uploaded_at'] ?? '',
      isPrinted: json['is_printed'] ?? false,
      encryptedFileData: json['encrypted_file_data'] ?? '',
      ivVector: json['iv_vector'] ?? '',
      authTag: json['auth_tag'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

class DeleteResponse {
  final bool success;
  final String fileId;
  final String status;
  final String deletedAt;
  final String message;

  DeleteResponse({
    required this.success,
    required this.fileId,
    required this.status,
    required this.deletedAt,
    required this.message,
  });

  factory DeleteResponse.fromJson(Map<String, dynamic> json) {
    return DeleteResponse(
      success: json['success'] ?? false,
      fileId: json['file_id'] ?? '',
      status: json['status'] ?? '',
      deletedAt: json['deleted_at'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

class UserInfo {
  final String id;
  final String phone;
  final String? fullName;

  UserInfo({required this.id, required this.phone, this.fullName});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      fullName: json['full_name'],
    );
  }
}

class LoginResponse {
  final bool success;
  final String accessToken;
  final String refreshToken;
  final UserInfo user;

  LoginResponse({
    required this.success,
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: UserInfo.fromJson(json['user'] ?? {}),
    );
  }
}

class RegisterResponse {
  final bool success;
  final String accessToken;
  final String refreshToken;
  final UserInfo user;

  RegisterResponse({
    required this.success,
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] ?? false,
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: UserInfo.fromJson(json['user'] ?? {}),
    );
  }
}

// ========================================
// API EXCEPTION
// ========================================

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}