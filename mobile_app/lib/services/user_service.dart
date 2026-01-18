// ========================================
// USER SERVICE - TOKEN & SECURE STORAGE
// Manages JWT tokens and secure storage
// ========================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart'; // To access dynamic baseUrl

class UserService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _phoneKey = 'user_phone';
  static const _fullNameKey = 'user_full_name';

  final _storage = const FlutterSecureStorage();

  // ========================================
  // TOKEN STORAGE
  // ========================================

  /// Save access and refresh tokens securely
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String phone,
    String? fullName,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _accessTokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
        _storage.write(key: _userIdKey, value: userId),
        _storage.write(key: _phoneKey, value: phone),
        if (fullName != null) _storage.write(key: _fullNameKey, value: fullName),
      ]);
    } catch (e) {
      throw Exception('Failed to save tokens: $e');
    }
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored phone
  Future<String?> getPhone() async {
    try {
      return await _storage.read(key: _phoneKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored full name
  Future<String?> getFullName() async {
    try {
      return await _storage.read(key: _fullNameKey);
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // AUTHENTICATION STATUS
  // ========================================

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;
    return !isTokenExpired(token);
  }

  /// Logout - clear all stored tokens
  Future<void> logout() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _phoneKey),
        _storage.delete(key: _fullNameKey),
      ]);
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  // ========================================
  // TOKEN VALIDATION
  // ========================================

  /// Simple JWT decode (does NOT verify signature)
  /// For production, use jwt package to properly decode and validate
  Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode payload (second part)
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));

      return jsonDecode(decoded);
    } catch (e) {
      return null;
    }
  }

  /// Check if token is expired
  bool isTokenExpired(String token) {
    final payload = decodeToken(token);
    if (payload == null) return true;

    final expTime = payload['exp'];
    if (expTime == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= expTime;
  }
  
  // ========================================
  // ACCOUNT MANAGEMENT
  // ========================================

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final token = await getAccessToken();
    if (token == null) return false;

    try {
      // Use ApiService instance to get correct platform-specific URL
      final apiService = ApiService(); 
      final baseUrl = apiService.baseUrl;
      
      final url = Uri.parse('$baseUrl/api/auth/change-password');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      // debugPrint('Change Password Error: $e');
      return false;
    }
  }
  Future<bool> sendFeedback(String message) async {
    final token = await getAccessToken();
    if (token == null) return false;

    try {
      final apiService = ApiService(); 
      final baseUrl = apiService.baseUrl;
      
      final url = Uri.parse('$baseUrl/api/auth/feedback');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(String fullName) async {
    final token = await getAccessToken();
    if (token == null) return false;

    try {
      final apiService = ApiService();
      final baseUrl = apiService.baseUrl;

      final url = Uri.parse('$baseUrl/api/auth/update-profile');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'full_name': fullName,
        }),
      );

      if (response.statusCode == 200) {
        // Update local storage
        await _storage.write(key: _fullNameKey, value: fullName);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}


