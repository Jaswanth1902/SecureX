import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart'; // Add for MediaType
import 'user_service.dart';
import 'package:flutter/foundation.dart';

// Custom Exception for Authentication Failures
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  final String baseUrl =
      'http://10.85.144.137:5000'; // Using 127.0.0.1 for maximum stability on Windows/Local
  final UserService _userService = UserService();

  // Global callback for authentication failures
  static void Function()? onUnauthorized;

  // Guard to prevent unauthorized triggers during login/registration
  static bool isAuthInProgress = false;

  // ========================================
  // PRIVATE HELPERS
  // ========================================

  /// Get headers with mandatory Authorization token
  Future<Map<String, String>> _getHeaders({bool isJson = true}) async {
    final token = await _userService.getAccessToken();

    /* 
    if (kDebugMode) {
      print('DEBUG (ApiService): _getHeaders() check:');
      print(
          '  - Token: ${token != null ? "PRESENT (${token.substring(0, 10)}...)" : "MISSING"}');
      print('  - isAuthInProgress: $isAuthInProgress');
    }
    */

    if (token == null || token.isEmpty) {
      if (isAuthInProgress) {
        if (kDebugMode) {
          print(
              'DEBUG (ApiService): Token missing but auth in progress. Returning empty headers.');
        }
        return isJson ? {'Content-Type': 'application/json'} : {};
      }
      if (kDebugMode) {
        print(
            'DEBUG (ApiService): Token missing and NO auth in progress. THROWING AuthException.');
      }
      throw AuthException("Not authenticated");
    }

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
    };

    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  /// Handle API responses and detect auth failures
  http.Response _handleResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      // Trigger global redirection callback
      onUnauthorized?.call();
      throw AuthException("Authentication expired or invalid");
    }
    return response;
  }

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
      final response = _handleResponse(await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
          if (fullName != null) 'full_name': fullName,
        }),
      ));

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return RegisterResponse.fromJson(json);
      } else {
        final json = jsonDecode(response.body);
        throw ApiException(
          json['message'] ?? 'Registration failed: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
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
      final response = _handleResponse(await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      ));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return LoginResponse.fromJson(json);
      } else {
        final json = jsonDecode(response.body);
        throw ApiException(
          json['message'] ?? 'Login failed: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Login error: $e', -1);
    }
  }

  // ========================================
  // RESET PASSWORD
  // ========================================

  Future<bool> resetPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/owners/change-password');
      final headers = await _getHeaders();

      final response = _handleResponse(await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'current_password': oldPassword,
          'new_password': newPassword,
        }),
      ));

      if (response.statusCode == 200) {
        return true;
      } else {
        final json = jsonDecode(response.body);
        throw ApiException(
          json['message'] ?? 'Password reset failed: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AuthException || e is ApiException) rethrow;
      throw ApiException('Reset password error: $e', -1);
    }
  }

  // ========================================
  // GET OWNER PUBLIC KEY
  // ========================================

  Future<String> getOwnerPublicKey(String ownerId) async {
    try {
      final url = Uri.parse('$baseUrl/api/owners/public-key/$ownerId');
      final response = _handleResponse(await http.get(url));

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
    required String ownerId,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/upload');
      final headers = await _getHeaders(isJson: false);

      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

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
          contentType: MediaType.parse(fileMimeType),
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response =
          _handleResponse(await http.Response.fromStream(streamedResponse));

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return UploadResponse.fromJson(json);
      } else {
        throw ApiException(
          'Upload failed: ${response.statusCode}. ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AuthException || e is ApiException) rethrow;
      throw ApiException('Upload error: $e', -1);
    }
  }

  // ========================================
  // LIST FILES
  // ========================================

  Future<List<FileItem>> listFiles() async {
    try {
      final url = Uri.parse('$baseUrl/api/files');
      final headers = await _getHeaders();

      final response = _handleResponse(await http.get(
        url,
        headers: headers,
      ));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final files =
            (json['files'] as List).map((f) => FileItem.fromJson(f)).toList();
        return files;
      } else {
        throw ApiException(
          'Failed to list files: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AuthException || e is ApiException) rethrow;
      throw ApiException('List files error: $e', -1);
    }
  }

  // ========================================
  // GET RECENT FILES
  // ========================================

  Future<List<FileItem>> getRecentFiles() async {
    try {
      final url = Uri.parse('$baseUrl/api/files/recent');
      final headers = await _getHeaders();

      final response = _handleResponse(await http.get(
        url,
        headers: headers,
      ));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final files = (json['files'] as List)
            .map((f) => FileItem.fromJson({
                  'file_id': f['id'],
                  'file_name': f['name'],
                  'file_size_bytes': f['size'],
                  'uploaded_at': f['uploaded_at'],
                  'is_printed': 0,
                  'status': 'UPLOADED',
                  'status_updated_at': f['uploaded_at'],
                }))
            .toList();
        return files;
      } else {
        throw ApiException(
          'Failed to fetch recent files: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AuthException || e is ApiException) rethrow;
      throw ApiException('Recent files error: $e', -1);
    }
  }

  // ========================================
  // SUBMIT FEEDBACK
  // ========================================

  Future<bool> submitFeedback({
    required String message,
    int? rating,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/feedback');
      final headers = await _getHeaders();

      final response = _handleResponse(await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'message': message,
          if (rating != null) 'rating': rating,
        }),
      ));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final json = jsonDecode(response.body);
        throw ApiException(
          json['message'] ?? 'Feedback submission failed',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AuthException || e is ApiException) rethrow;
      throw ApiException('Feedback error: $e', -1);
    }
  }

  // ========================================
  // GET FILE FOR PRINTING
  // ========================================

  Future<Map<String, dynamic>> getFileForPrinting({
    required String fileId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/print/$fileId');
      final headers = await _getHeaders();

      final response = _handleResponse(await http.get(
        url,
        headers: headers,
      ));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['file'];
      } else {
        throw ApiException(
          'Failed to get file: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AuthException || e is ApiException) rethrow;
      throw ApiException('Get file error: $e', -1);
    }
  }

  // ========================================
  // SUBMIT PRINT JOB
  // ========================================

  Future<bool> submitPrintJob({
    required String fileId,
    required int copies,
    required bool color,
    required String paperSize,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/print/$fileId');
      final headers = await _getHeaders();

      final response = _handleResponse(await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'file_id': fileId,
          'copies': copies,
          'color': color,
          'paper_size': paperSize,
        }),
      ));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final json = jsonDecode(response.body);
        throw ApiException(
          json['message'] ?? 'Print job failed: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AuthException || e is ApiException) rethrow;
      throw ApiException('Print job error: $e', -1);
    }
  }

  // ========================================
  // DELETE FILE
  // ========================================

  Future<DeleteResponse> deleteFile({
    required String fileId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/delete/$fileId');
      final headers = await _getHeaders();

      final response = _handleResponse(await http.post(
        url,
        headers: headers,
      ));

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
      if (e is AuthException || e is ApiException) rethrow;
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
      isPrinted: json['is_printed'] == 1 || json['is_printed'] == true,
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
      success: json['success'] == 1 || json['success'] == true,
      fileId: json['file_id'] ?? '',
      fileName: json['file_name'] ?? '',
      fileSizeBytes: json['file_size_bytes'] ?? 0,
      uploadedAt: json['uploaded_at'] ?? '',
      isPrinted: json['is_printed'] == 1 || json['is_printed'] == true,
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
      success: json['success'] == 1 || json['success'] == true,
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
      success: json['success'] == 1 || json['success'] == true,
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
      success: json['success'] == 1 || json['success'] == true,
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