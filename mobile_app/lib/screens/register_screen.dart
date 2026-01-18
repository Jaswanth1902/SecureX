// ========================================
// REGISTER SCREEN - USER REGISTRATION
// Allows new users to create an account
// ========================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../widgets/glass_container.dart';

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
        fullName: response.user.fullName,
      );

      // Mark onboarding as seen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);

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
          title: const Text('Create Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                const Text(
                  'Join SecureX',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create Your Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 40),

                GlassContainer(
                   padding: const EdgeInsets.all(24),
                   borderRadius: BorderRadius.circular(20),
                   child: Column(
                     children: [
                       TextField(
                          controller: _fullNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration('Full Name', Icons.person),
                        ),
                        const SizedBox(height: 16),
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

                // Register Button
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
                      onTap: _isLoading ? null : _handleRegister,
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
                                'Register',
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
                
                // Link handled by parent AuthScreen in bottom bar
              ],
            ),
          ),
        ),
      ),
    );
  }
}
