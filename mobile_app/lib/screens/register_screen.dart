// ========================================
// REGISTER SCREEN - USER REGISTRATION
// Allows new users to create an account
// ========================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../providers/theme_provider.dart';

class RegisterScreen extends StatefulWidget {
  final Function(String accessToken, String userId) onRegisterSuccess;
  final Function()? onHaveAccount;

  const RegisterScreen({
    super.key,
    required this.onRegisterSuccess,
    this.onHaveAccount,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _apiService = ApiService();
  final _userService = UserService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _fullNameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'All fields are required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call POST /api/auth/register
      final response = await _apiService.registerUser(
        phone: _phoneController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
      );

      // Save tokens locally
      await _userService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        userId: response.user.id,
        phone: response.user.phone,
        fullName: response.user.fullName ?? '',
      );

      // Notify parent widget of successful registration
      widget.onRegisterSuccess(response.accessToken, response.user.id);
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed. Please check your details and try again.';
      });    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final content = Scaffold(
      appBar: AppBar(title: const Text('Create Account'), centerTitle: true),
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
            const SizedBox(height: 10),
            const Text(
              'Create Your Account',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // Full Name Field
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

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
                helperText: 'Min 8 chars, uppercase, number, special char',
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

            // Register Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
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
                  : const Text('Register', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),

            // Login Link
            Center(
              child: GestureDetector(
                onTap: widget.onHaveAccount,
                child: Text(
                  'Already have an account? Login here',
                  style: TextStyle(color: Colors.blue.shade600),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (themeProvider.isGradientMode) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
              Color(0xFF4facfe),
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: content,
      );
    }

    return content;
  }
}
