// ========================================
// LOGIN SCREEN - USER AUTHENTICATION
// Allows users to login with email and password
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  final _apiService = ApiService();
  final _userService = UserService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Set guard to prevent premature logout triggers
      ApiService.isAuthInProgress = true;

      // Call POST /api/auth/login
      final response = await _apiService.loginUser(
        phone: phone,
        password: password,
      );

      // Save tokens locally - CRITICAL: Must be awaited
      await _userService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        userId: response.user.id,
        phone: response.user.phone,
      );

      // VERIFICATION: Verify token was actually saved before continuing
      final savedToken = await _userService.getAccessToken();
      if (kDebugMode) {
        print('DEBUG (Login): Token saved successfully: ${savedToken != null}');
      }

      // Small delay to ensure storage consistency on some platforms
      await Future.delayed(const Duration(milliseconds: 500));

      // Reset guard AFTER successful save
      ApiService.isAuthInProgress = false;

      // Navigate to Dashboard using Navigator.pushReplacement
      if (mounted) {
        debugPrint('DEBUG (Login): Navigating to dashboard');
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      // Reset guard on error as well
      ApiService.isAuthInProgress = false;
      setState(() {
        _errorMessage = 'Login failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo/Title
            const SizedBox(height: 40),
            const Text(
              'Secure Print',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // Phone Field
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),

            // Password Field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            const SizedBox(height: 20),

            // Login Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),

            // Register Link
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/register');
                },
                child: Text(
                  'Don\'t have an account? Register here',
                  style: TextStyle(color: Colors.blue.shade600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
