

  import 'dart:convert';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:flutter/foundation.dart';

  // ========================================
  // USER SERVICE - TOKEN & SECURE STORAGE
  // Manages JWT tokens and secure storage
  // ========================================

  class UserService {
    static const _accessTokenKey = 'access_token';
    static const _refreshTokenKey = 'refresh_token';
    static const _userIdKey = 'user_id';
    static const _phoneKey = 'user_phone';
    static const _fullNameKey = 'full_name';

    // Singleton instance
    static final UserService _instance = UserService._internal();
    factory UserService() => _instance;
    UserService._internal();

    SharedPreferences? _prefs;

    // Notifier to broadcast full name changes to UI listeners
    final ValueNotifier<String?> fullNameNotifier = ValueNotifier<String?>(null);

    // IN-MEMORY CACHE for immediate retrieval after login
    String? _cachedAccessToken;

    Future<SharedPreferences> get _storage async {
      _prefs ??= await SharedPreferences.getInstance();
      return _prefs!;
    }

  // ========================================
  // TOKEN STORAGE
  // ========================================

  /// Save access and refresh tokens securely
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String phone,
    required String fullName,
  }) async {
    try {
      _cachedAccessToken = accessToken; // Cache immediately

      final storage = await _storage;
      if (kDebugMode) {
        print(
            'DEBUG (UserService): Saving tokens for user $userId to SharedPreferences');
      }
      await Future.wait([
        storage.setString(_accessTokenKey, accessToken),
        storage.setString(_refreshTokenKey, refreshToken),
        storage.setString(_userIdKey, userId),
        storage.setString(_phoneKey, phone),
        storage.setString(_fullNameKey, fullName),
      ]);

      // Force immediate flush for Windows
      await storage.reload();

      if (kDebugMode) {
        print('DEBUG (UserService): Tokens saved successfully. Cache updated.');
      }
      // update notifier so listeners can react immediately
      fullNameNotifier.value = fullName;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG (UserService): Failed to save tokens: $e');
      }
      throw Exception('Failed to save tokens: $e');
    }
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    // Return cache if available for performance and race prevention
    if (_cachedAccessToken != null) {
      return _cachedAccessToken;
    }

    try {
      final storage = await _storage;
      final token = storage.getString(_accessTokenKey);
      _cachedAccessToken = token; // Populate cache
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG (UserService): Error reading access token: $e');
      }
      return null;
    }
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    try {
      final storage = await _storage;
      return storage.getString(_refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    try {
      final storage = await _storage;
      return storage.getString(_userIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored phone
  Future<String?> getPhone() async {
    try {
      final storage = await _storage;
      return storage.getString(_phoneKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored full name
  Future<String?> getFullName() async {
    try {
      final storage = await _storage;
      // populate notifier if not set
      final name = storage.getString(_fullNameKey);
      if (fullNameNotifier.value == null) fullNameNotifier.value = name;
      return storage.getString(_fullNameKey);
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
      _cachedAccessToken = null; // Clear cache

      final storage = await _storage;
      await Future.wait([
        storage.remove(_accessTokenKey),
        storage.remove(_refreshTokenKey),
        storage.remove(_userIdKey),
        storage.remove(_phoneKey),
        storage.remove(_fullNameKey),
      ]);
      if (kDebugMode) {
        print('DEBUG (UserService): Logged out, tokens cleared');
      }
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
  /// Update stored full name
  Future<void> updateFullName(String newName) async {
    try {
      final storage = await _storage;
      await storage.setString(_fullNameKey, newName);
      // notify listeners immediately
      fullNameNotifier.value = newName;
      if (kDebugMode) {
        print('DEBUG (UserService): Full name updated to: $newName');
      }
    } catch (e) {
      throw Exception('Failed to update full name: $e');
    }
  }
}