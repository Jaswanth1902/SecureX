import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  // Use localhost for desktop dev
  final String baseUrl = 'http://127.0.0.1:5000';

  String? _accessToken;

  Map<String, dynamic>? _user;

  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;
  Map<String, dynamic>? get user => _user;

  Future<bool> register(
    String email,
    String password,
    String fullName,
    String publicKey,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/api/owners/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'public_key': publicKey,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _accessToken = data['accessToken'];
          _user = data['owner'];
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password, String publicKey) async {
    try {
      final url = Uri.parse('$baseUrl/api/owners/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'public_key': publicKey, // Sync public key on login
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _accessToken = data['accessToken'];
          _user = data['owner'];
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> refreshProfile() async {
    if (_accessToken == null) return false;
    try {
      final url = Uri.parse('$baseUrl/api/owners/profile');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final updatedOwner = data['owner'];
          _user = {...?_user, ...updatedOwner};
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Refresh Profile error: $e');
      return false;
    }
  }

  Future<bool> updateName(String newName) async {
    if (_accessToken == null) return false;
    try {
      final url = Uri.parse('$baseUrl/api/owners/update-profile');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode({'full_name': newName}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await refreshProfile();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Update Name error: $e');
      return false;
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_accessToken == null) return false;
    try {
      final url = Uri.parse('$baseUrl/api/owners/change-password');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
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
      debugPrint('Change Password error: $e');
      return false;
    }
  }

  Future<bool> sendFeedback(String message) async {
    if (_accessToken == null) return false;
    try {
      final url = Uri.parse('$baseUrl/api/owners/feedback');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Send Feedback error: $e');
      return false;
    }
  }

  Future<bool> googleLogin(String idToken) async {
    try {
      final url = Uri.parse('$baseUrl/api/owners/google');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _accessToken = data['accessToken'];
          _user = data['owner'];
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Google Login error: $e');
      return false;
    }
  }

  void logout() {
    _accessToken = null;
    _user = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getMyPublicKey() async {
    if (_accessToken == null) return null;
    try {
      final url = Uri.parse('$baseUrl/api/owners/me/public-key');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Get My Public Key error: $e');
      return null;
    }
  }

  Future<bool> syncPublicKey(String publicKey) async {
    if (_accessToken == null) return false;
    try {
      final url = Uri.parse('$baseUrl/api/owners/sync-key');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode({'public_key': publicKey}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Sync Public Key error: $e');
      return false;
    }
  }

  /// Set auth state directly (for browser-based OAuth)
  void setAuthState(String accessToken, Map<String, dynamic> user) {
    _accessToken = accessToken;
    _user = user;
    notifyListeners();
  }

  /// Validate an access token and get user profile
  Future<Map<String, dynamic>?> validateToken(String token) async {
    try {
      final url = Uri.parse('$baseUrl/api/owners/profile');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['owner'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Validate token error: $e');
      return null;
    }
  }

  /// Get Google OAuth status for a session
  Future<bool> deleteAccount() async {
    if (_accessToken == null) return false;
    try {
      final url = Uri.parse('$baseUrl/api/owners/delete-account');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          logout();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Delete Account error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getGoogleAuthStatus(String sessionId) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/owners/google/status?session_id=$sessionId',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Get Google Auth Status error: $e');
      return null;
    }
  }
}
