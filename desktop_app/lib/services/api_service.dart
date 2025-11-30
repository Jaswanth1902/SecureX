import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/file_item.dart';

class ApiService {
  final String baseUrl = 'http://localhost:5000';

  Future<List<FileItem>> listFiles(String accessToken) async {
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
        throw Exception('Failed to list files: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('List files error: $e');
    }
  }

  Future<PrintFileResponse> getFileForPrinting(String fileId, String accessToken) async {
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
        throw Exception('Failed to get file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Get file error: $e');
    }
  }

  Future<bool> deleteFile(String fileId, String accessToken) async {
    try {
      final url = Uri.parse('$baseUrl/api/delete/$fileId');
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
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
