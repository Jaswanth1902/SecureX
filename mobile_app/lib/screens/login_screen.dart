// ========================================
// LOGIN SCREEN - USER AUTHENTICATION
// Allows users to login with email and password
// ========================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../widgets/glass_container.dart';

class LoginScreen extends StatefulWidget {
  final Function(String accessToken, String userId) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _userService = UserService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Phone and password are required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call POST /api/auth/login
      final response = await _apiService.loginUser(
        phone: _phoneController.text,
        password: _passwordController.text,
      );

      // Save tokens locally
      await _userService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        userId: response.user.id,
        phone: response.user.phone,
        fullName: response.user.fullName,
      );

      // Mark onboarding as seen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);

      // Notify parent widget of successful login
      widget.onLoginSuccess(response.accessToken, response.user.id);
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppConstants.getBackgroundGradient(context)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Title
                const Icon(Icons.security, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'SecureX',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Secure Printing Made Simple',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 48),

                // Inputs
                GlassContainer(
                   padding: const EdgeInsets.all(24),
                   borderRadius: BorderRadius.circular(20),
                   child: Column(
                     children: [
                       TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration('Phone Number', Icons.phone),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration('Password', Icons.lock),
                        ),
                     ],
                   )
                ),
                const SizedBox(height: 24),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Login Button
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppConstants.getBackgroundGradient(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isLoading ? null : _handleLogin,
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Register Link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to register screen (handled by parent switch)
                      // Since AuthScreen manages state, we likely need to invoke a callback provided to this widget?
                      // Wait, LoginScreen constructor has `onLoginSuccess`. 
                      // AuthScreen switches based on internal state. 
                      // The link `Don't have an account?` is actually OUTSIDE LoginScreen in AuthScreen.
                      // Let's check AuthScreen in main.dart.
                      // Yes, the bottomNavigationBar of AuthScreen handles the toggle.
                      // So we don't need the link INSIDE LoginScreen, or if we keep it, it won't work without a callback.
                      // The original file had a link but it did nothing or was handled by parent?
                      // Original code: `onTap: () { // Navigate to register screen (handled by parent) },` - it was empty.
                      // `AuthScreen` passes `onLoginSuccess`.
                      // `AuthScreen` has a bottomNavigationBar with the link.
                      // So I can remove the link from here to avoid duplication/confusion.
                    },
                    child: Container(), // Removed link as it's in the bottom bar
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
