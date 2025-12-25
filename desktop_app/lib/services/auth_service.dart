import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  // Use localhost for desktop dev
  final String baseUrl = 'http://localhost:5000';

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

  void logout() {
    _accessToken = null;
    _user = null;
    notifyListeners();
  }
}
