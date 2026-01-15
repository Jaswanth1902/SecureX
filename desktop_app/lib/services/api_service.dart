import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:http/http.dart' as http;
import '../models/file_item.dart';

class ApiService {
  String _baseUrl = const String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:5000',
  );
  bool _configLoaded = false;

  String get baseUrl => _baseUrl;

  Future<String> getBaseUrl() async {
    await _ensureConfigLoaded();
    return _baseUrl;
  }

  // Static callback for auth failures
  static void Function()? onUnauthorized;

  ApiService() {
    _ensureConfigLoaded();
  }

  Future<void> _ensureConfigLoaded() async {
    if (_configLoaded) return;
    _configLoaded = true;

    try {
      // Look for config.json in the same folder as the exe (Windows)
      // This is a simple implementation for Desktop where we can drop a file
      if (Platform.isWindows) {
        final dir = File(Platform.resolvedExecutable).parent;
        final configFile = File('${dir.path}/config.json');
        if (await configFile.exists()) {
          final jsonStr = await configFile.readAsString();
          final json = jsonDecode(jsonStr);
          if (json['api_url'] != null) {
            _baseUrl = json['api_url'];
            debugPrint('Loaded API URL from config: $_baseUrl');
          }
        }
      }
      // Also support config.json in project working directory
      final cwdConfig = File('${Directory.current.path}/config.json');
      if (await cwdConfig.exists()) {
        final jsonStr = await cwdConfig.readAsString();
        final json = jsonDecode(jsonStr);
        if (json['api_url'] != null) {
          _baseUrl = json['api_url'];
          debugPrint('Loaded API URL from cwd config: $_baseUrl');
        }
      }
    } catch (e) {
      debugPrint('Config load error: $e');
    }
  }

  /// Handle API responses and detect auth failures
  http.Response _handleResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      // Trigger global redirection callback
      onUnauthorized?.call();
      throw Exception("Authentication expired or invalid");
    }
    return response;
  }

  Future<List<FileItem>> listFiles(String accessToken) async {
    try {
      await _ensureConfigLoaded();
      // Ensure config is loaded or wait?
      // For simplicity in this async method, we assume constructor starts it
      // But ideally we'd await initialization.
      // Let's reload or verify here if needed.

      final url = Uri.parse('$_baseUrl/api/files');
      final response = _handleResponse(
        await http.get(url, headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final files = (json['files'] as List)
            .map((f) => FileItem.fromJson(f))
            .toList();
        return files;
      } else {
        throw Exception('Failed to list files: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('List files error: $e');
    }
  }

  Future<PrintFileResponse> getFileForPrinting(
    String fileId,
    String accessToken,
  ) async {
    try {
      await _ensureConfigLoaded();
      final url = Uri.parse('$_baseUrl/api/print/$fileId');
      final response = _handleResponse(
        await http.get(url, headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return PrintFileResponse.fromJson(json);
      } else {
        throw Exception('Failed to get file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get file error: $e');
    }
  }

  Future<bool> deleteFile(String fileId, String accessToken) async {
    try {
      await _ensureConfigLoaded();
      final url = Uri.parse('$_baseUrl/api/delete/$fileId');
      final response = _handleResponse(
        await http.post(url, headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Delete file error: $e');
    }
  }

  Future<bool> updateFileStatus(
    String fileId,
    String status,
    String accessToken, {
    String? rejectionReason,
  }) async {
    try {
      await _ensureConfigLoaded();
      final url = Uri.parse('$baseUrl/api/status/update/$fileId');
      final body = {
        'status': status,
        if (rejectionReason != null) 'rejection_reason': rejectionReason,
      };

      final response = _handleResponse(
        await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Update status error: $e');
    }
  }

  Future<List<HistoryItem>> getHistory(String accessToken) async {
    try {
      await _ensureConfigLoaded();
      final url = Uri.parse('$baseUrl/api/history');
      final response = _handleResponse(
        await http.get(url, headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final history = (json['history'] as List)
            .map((h) => HistoryItem.fromJson(h))
            .toList();
        return history;
      } else {
        throw Exception('Failed to get history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get history error: $e');
    }
  }

  Future<bool> clearHistory(String accessToken) async {
    try {
      await _ensureConfigLoaded();
      final url = Uri.parse('$baseUrl/api/clear-history');
      final response = _handleResponse(
        await http.post(url, headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to clear history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Clear history error: $e');
    }
  }

  Future<List<FileItem>> getRecentFiles(String accessToken) async {
    try {
      await _ensureConfigLoaded();
      final url = Uri.parse('$baseUrl/api/files/recent');
      final response = _handleResponse(
        await http.get(url, headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final files = (json['files'] as List)
            .map(
              (f) => FileItem.fromJson({
                'file_id': f['id'],
                'file_name': f['name'],
                'file_size_bytes': f['size'],
                'uploaded_at': f['uploaded_at'],
                'is_printed': false,
                'status': 'UPLOADED',
              }),
            )
            .toList();
        return files;
      } else {
        throw Exception('Failed to fetch recent files: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Recent files error: $e');
    }
  }

  // ========================================
  // SUBMIT FEEDBACK
  // ========================================

  Future<bool> submitFeedback(
    String message,
    String accessToken, {
    int? rating,
  }) async {
    try {
      await _ensureConfigLoaded();
      final url = Uri.parse('$baseUrl/api/feedback');
      final response = _handleResponse(
        await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'message': message,
            if (rating != null) 'rating': rating,
          }),
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to submit feedback: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Submit feedback error: $e');
    }
  }
}

class HistoryItem {
  final String fileId;
  final String fileName;
  final int fileSizeBytes;
  final String uploadedAt;
  final String? deletedAt;
  final String status;
  final String statusUpdatedAt;
  final String? rejectionReason;
  final bool isPrinted;

  HistoryItem({
    required this.fileId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.uploadedAt,
    this.deletedAt,
    required this.status,
    required this.statusUpdatedAt,
    this.rejectionReason,
    required this.isPrinted,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      fileId: json['file_id'],
      fileName: json['file_name'],
      fileSizeBytes: json['file_size_bytes'] ?? 0,
      uploadedAt: json['uploaded_at'] ?? '',
      deletedAt: json['deleted_at'],
      status: json['status'] ?? 'UNKNOWN',
      statusUpdatedAt: json['status_updated_at'] ?? '',
      rejectionReason: json['rejection_reason'],
      isPrinted: (json['is_printed'] == 1) || (json['is_printed'] == true),
    );
  }
}

class PrintFileResponse {
  final String fileId;
  final String fileName;
  final String encryptedFileData; // Base64
  final String ivVector; // Base64
  final String authTag; // Base64
  final String encryptedSymmetricKey; // Base64

  PrintFileResponse({
    required this.fileId,
    required this.fileName,
    required this.encryptedFileData,
    required this.ivVector,
    required this.authTag,
    required this.encryptedSymmetricKey,
  });

  factory PrintFileResponse.fromJson(Map<String, dynamic> json) {
    return PrintFileResponse(
      fileId: json['file_id'],
      fileName: json['file_name'],
      encryptedFileData: json['encrypted_file_data'],
      ivVector: json['iv_vector'],
      authTag: json['auth_tag'],
      encryptedSymmetricKey: json['encrypted_symmetric_key'] ?? '',
    );
  }
}
