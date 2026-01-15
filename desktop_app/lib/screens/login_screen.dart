import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/key_service.dart';
import '../widgets/google_logo_painter.dart';
import '../services/theme_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late PageController _pageController;

  // LOGIN FORM CONTROLLERS
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // REGISTER FORM CONTROLLERS
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _stopGooglePolling = false;
  String? _errorMessage;

  // Form Validity State
  bool _isLoginValid = false;
  bool _isRegisterValid = false;

  // Specific Error States
  bool _passwordsMismatch = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Add Listeners
    _loginEmailController.addListener(_validateLogin);
    _loginPasswordController.addListener(_validateLogin);

    _registerNameController.addListener(_validateRegister);
    _registerEmailController.addListener(_validateRegister);
    _registerPasswordController.addListener(_validateRegister);
    _registerConfirmPasswordController.addListener(_validateRegister);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  void _validateLogin() {
    final isValid =
        _loginEmailController.text.isNotEmpty &&
        _loginPasswordController.text.isNotEmpty;
    if (_isLoginValid != isValid) {
      setState(() => _isLoginValid = isValid);
    }
  }

  void _validateRegister() {
    final name = _registerNameController.text;
    final email = _registerEmailController.text;
    final pass = _registerPasswordController.text;
    final confirm = _registerConfirmPasswordController.text;

    // Check mismatch (only if both are non-empty to avoid noise)
    final mismatch = (pass.isNotEmpty && confirm.isNotEmpty && pass != confirm);

    // Check total validity
    final isValid =
        name.isNotEmpty &&
        email.isNotEmpty &&
        pass.isNotEmpty &&
        confirm.isNotEmpty &&
        !mismatch;

    if (_isRegisterValid != isValid || _passwordsMismatch != mismatch) {
      setState(() {
        _isRegisterValid = isValid;
        _passwordsMismatch = mismatch;
      });
    }
  }

  // --- ACTIONS ---

  void _handleToggle(bool toLogin) {
    _errorMessage = null; // Clear errors on toggle
    _stopGooglePolling = true; // Cancel any active Google polling
    _isGoogleLoading = false;

    _pageController.animateToPage(
      toLogin ? 0 : 1,
      duration: const Duration(milliseconds: 1000), // Glide duration (1 sec)
      curve: Curves.easeInOutQuart,
    );
  }

  Future<void> _handleLogin() async {
    if (!_isLoginValid) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _stopGooglePolling =
          true; // If user starts manual login, stop Google polling
      _isGoogleLoading = false;
    });
    try {
      final keyService = context.read<KeyService>();
      final authService = context.read<AuthService>();
      final email = _loginEmailController.text;

      // Pass email to get user-specific key
      final keyPair = await keyService.getStoredKeyPair(email);
      if (keyPair == null) throw 'No private key found. Please register.';

      final publicKeyPem = await keyService.getPublicKeyPem(keyPair.publicKey);
      final success = await authService.login(
        email,
        _loginPasswordController.text,
        publicKeyPem,
      );

      if (success) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        throw 'Login failed. Check credentials.';
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_isRegisterValid) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _stopGooglePolling =
          true; // If user starts manual register, stop Google polling
      _isGoogleLoading = false;
    });
    try {
      // Validate
      if (_registerPasswordController.text !=
          _registerConfirmPasswordController.text) {
        throw 'Passwords do not match.';
      }

      final keyService = context.read<KeyService>();
      final authService = context.read<AuthService>();
      final email = _registerEmailController.text;

      // Pass email to store user-specific key
      final keyPair = await keyService.generateAndStoreKeyPair(email);
      final publicKeyPem = await keyService.getPublicKeyPem(keyPair.publicKey);

      final success = await authService.register(
        email,
        _registerPasswordController.text,
        _registerNameController.text,
        publicKeyPem,
      );

      if (success) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        throw 'Registration failed. Email might be taken.';
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin(bool isLogin) async {
    if (_isGoogleLoading) return; // Prevent multiple clicks

    setState(() {
      _isGoogleLoading = true;
      _stopGooglePolling = false;
      _errorMessage = null;
    });

    try {
      // Generate unique session ID for polling
      final session_id = DateTime.now().microsecondsSinceEpoch.toString();
      debugPrint('DEBUG: OAuth Session ID: $session_id');

      // Open browser for Google OAuth with session ID
      final authService = context.read<AuthService>();
      final googleLoginUrl = Uri.parse(
        '${authService.baseUrl}/api/owners/google/login?session_id=$session_id',
      );

      if (!await canLaunchUrl(googleLoginUrl)) {
        throw 'Could not open browser';
      }

      // DO NOT await launchUrl indefinitely if it takes time; trigger and move to polling
      launchUrl(googleLoginUrl, mode: LaunchMode.externalApplication)
          .then((success) {
            debugPrint('DEBUG: Browser launch success: $success');
          })
          .catchError((err) {
            debugPrint('DEBUG: Browser launch error: $err');
          });

      // Show message to user
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete login in browser. You\'ll be logged in automatically.',
          ),
          duration: Duration(seconds: 3),
        ),
      );

      // Poll for auth completion every 1 second
      const maxAttempts = 45; // 45 seconds max (polling every 1s)
      debugPrint('DEBUG: Starting polling for session: $session_id');

      for (var i = 0; i < maxAttempts; i++) {
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted || _stopGooglePolling) {
          debugPrint(
            'DEBUG: Polling stopped - mounted: $mounted, stopFlag: $_stopGooglePolling',
          );
          return;
        }

        try {
          // Poll the backend
          final result = await authService.getGoogleAuthStatus(session_id);
          debugPrint(
            'DEBUG: Polling attempt ${i + 1}/$maxAttempts for $session_id: $result',
          );

          if (result != null && result['status'] == 'success') {
            debugPrint('DEBUG: Auth Success detected for $session_id');
            final jwt = result['jwt'] as String?;
            final email = result['email'] as String?;
            final name = result['name'] as String? ?? 'User';

            if (jwt != null && email != null) {
              // 1. Set Auth State (so AuthService has the token)
              authService.setAuthState(jwt, {
                'email': email,
                'full_name': name,
              });

              // 2. Key Consistency Logic (Prevent Mobile MITM Warning)
              final keyService = context.read<KeyService>();

              // A. Check if backend already has a public key
              final keyInfo = await authService.getMyPublicKey();
              final backendKeyExists =
                  keyInfo != null && keyInfo['exists'] == true;

              if (backendKeyExists) {
                debugPrint(
                  'DEBUG: Backend already has key for $email. Skipping generation to prevent MITM.',
                );
                // Note: If local key is missing, user might need to import private key manually
                // but we MUST NOT overwrite the backend key.
              } else {
                // B. Backend has no key -> safe to generate and sync
                debugPrint(
                  'DEBUG: No backend key found for $email. Generating new RSA keys.',
                );

                // Get or Generate KeyPair
                var keyPair = await keyService.getStoredKeyPair(email);
                if (keyPair == null) {
                  keyPair = await keyService.generateAndStoreKeyPair(email);
                }

                // Sync Public Key with Backend
                final publicKeyPem = await keyService.getPublicKeyPem(
                  keyPair.publicKey,
                );
                final syncSuccess = await authService.syncPublicKey(
                  publicKeyPem,
                );
                debugPrint('DEBUG: Public Key sync status: $syncSuccess');
              }

              if (!mounted) return;

              // 3. Snackbar confirmed for individual user device
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Logged in successfully as $email'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );

              // 4. Navigate
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
              return;
            }
          }
        } catch (e) {
          debugPrint('DEBUG: Polling error: $e');
        }
      }

      throw 'Login timed out. Please try again.';
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // --- BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    final themeService = context.watch<ThemeService>();
    final colors = themeService.colors;
    final isDark = themeService.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [colors.backgroundGradientStart, colors.backgroundGradientEnd]
                : [
                    colors.backgroundGradientStart,
                    const Color(0xFFE6E6FA),
                    colors.backgroundGradientEnd,
                  ],
            stops: isDark ? null : [0.0, 0.5, 1.0],
          ),
        ),
        // Use PageView for the "Glide" effect
        child: PageView(
          controller: _pageController,
          physics:
              const NeverScrollableScrollPhysics(), // Disable swipe, only buttons
          children: [
            // PAGE 0: LOGIN LAYER (Image Left, Form Right)
            _buildLayer(
              isDesktop: isDesktop,
              isImageLeft: true,
              child: _buildFadeWrapper(0, _buildLoginForm()),
            ),

            // PAGE 1: REGISTER LAYER (Form Left, Image Right)
            _buildLayer(
              isDesktop: isDesktop,
              isImageLeft: false,
              child: _buildFadeWrapper(1, _buildRegisterForm()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFadeWrapper(int pageIndex, Widget child) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double page = 0.0;
        try {
          if (_pageController.hasClients) {
            page = _pageController.page ?? 0.0;
          } else {
            page = _pageController.initialPage.toDouble();
          }
        } catch (_) {}

        double opacity = 1.0;

        // Accelerated Fade Logic
        if (pageIndex == 0) {
          // Login Page: 0 -> 1 (Fade OUT fast)
          // Fades out completely by 0.5 (halfway slide)
          // 0.0 -> 1.0; At 0.5 -> 0.0
          opacity = (1.0 - (page * 1.5)).clamp(0.0, 1.0);
        } else {
          // Register Page: 0 -> 1 (Fade IN fast)
          // Starts appearing from 0.0, but gets full opacity quickly
          // Let's make it fade in throughout the slide but maybe start slightly delayed or just pure page?
          // If user says "no fade", maybe they want it to look like it's dissolving?
          // Let's try pure linear mapping but distinct.
          // Actually, let's mirror login: Fade IN during last half? (0.5 -> 1.0)
          // page 0.5 -> 0.0 opacity. 1.0 -> 1.0 opacity.
          // opacity = ((page - 0.2) / 0.8).clamp(0.0, 1.0); // start fading in at 0.2
          opacity = page.clamp(0.0, 1.0);
          // Reverting to simple clamp but ensure AnimatedBuilder triggers.
          // It's possible AnimatedBuilder isn't triggering if 'page' doesn't notify?
          // PageController DOES notify.
        }

        return Opacity(opacity: opacity, child: child);
      },
      child: child,
    );
  }

  Widget _buildLayer({
    required bool isDesktop,
    required bool isImageLeft,
    required Widget child,
  }) {
    if (!isDesktop)
      return Center(child: child); // Mobile: Just content centered

    return Row(
      children: isImageLeft
          ? [
              Expanded(flex: 1, child: _buildImage()),
              Expanded(flex: 1, child: Center(child: child)),
            ]
          : [
              Expanded(flex: 1, child: Center(child: child)),
              Expanded(flex: 1, child: _buildImage()),
            ],
    );
  }

  Widget _buildImage() {
    final isDark = context.watch<ThemeService>().isDarkMode;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/login_background.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF2D1B4E),
            child: const Center(
              child: Icon(Icons.security, size: 80, color: Colors.white24),
            ),
          ),
        ),
        Container(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
        ), // Overlay
      ],
    );
  }

  // --- FORMS ---

  Widget _buildLoginForm() {
    return _buildFormContainer(
      isLogin: true,
      isValid: _isLoginValid,
      title: 'Welcome back',
      subtitle: 'Login to manage your files in SafeCopy.',
      formFields: [
        _buildLabel('Email'),
        _buildInput(_loginEmailController, 'Enter your email', false),
        const SizedBox(height: 16),
        _buildLabel('Password'),
        _buildInput(_loginPasswordController, 'Enter your password', true),
      ],
      onSubmit: _handleLogin,
    );
  }

  Widget _buildRegisterForm() {
    return _buildFormContainer(
      isLogin: false,
      isValid: _isRegisterValid,
      title: 'Create Account',
      subtitle: 'Register to start securing your files.',
      formFields: [
        _buildLabel('Name'),
        _buildInput(_registerNameController, 'Enter your name', false),
        const SizedBox(height: 16),

        _buildLabel('Email-id'),
        _buildInput(_registerEmailController, 'Enter your email-id', false),
        const SizedBox(height: 16),

        _buildLabel(
          'New Password',
          errorText: _passwordsMismatch ? "Password doesn't match." : null,
        ),
        _buildInput(_registerPasswordController, 'Enter your password', true),
        const SizedBox(height: 16),

        _buildLabel(
          'Confirm password',
          errorText: _passwordsMismatch ? "Password doesn't match." : null,
        ),
        _buildInput(
          _registerConfirmPasswordController,
          'Confirm your password',
          true,
        ),
      ],
      onSubmit: _handleRegister,
    );
  }

  Widget _buildFormContainer({
    required bool isLogin,
    required bool isValid,
    required String title,
    required String subtitle,
    required List<Widget> formFields,
    required VoidCallback onSubmit,
  }) {
    final themeService = context.watch<ThemeService>();
    final colors = themeService.colors;
    final isDark = themeService.isDarkMode;

    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final dividerColor = isDark
        ? const Color(0xFF4A2F65)
        : const Color(0xFFD1D5DB);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(color: subtitleColor, fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Toggle
              _buildToggle(isLogin),
              const SizedBox(height: 24),

              // Inputs
              ...formFields,
              const SizedBox(height: 24),

              // Submit Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.acceptGradientStart,
                      colors.acceptGradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isValid
                      ? [
                          BoxShadow(
                            color: colors.acceptGradientStart.withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: colors.acceptGradientEnd.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 0),
                          ),
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: (_isLoading || !isValid) ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Opacity(
                          opacity: isValid ? 1.0 : 0.7,
                          child: Text(
                            isLogin ? 'Login' : 'Register',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),

              // Divider & Social
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isLogin ? 'or continue with' : 'or sign up with',
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: dividerColor)),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => _handleGoogleLogin(isLogin),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: dividerColor),
                  backgroundColor: isDark
                      ? const Color(0xFF2C2335)
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CustomPaint(painter: GoogleLogoPainter()),
                    ),
                    const SizedBox(width: 12),
                    _isGoogleLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                          )
                        : Text(
                            isLogin
                                ? 'Continue with Google'
                                : 'Sign up with Google',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ],
                ),
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFEF4444)),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildToggle(bool isLogin) {
    final isDark = context.watch<ThemeService>().isDarkMode;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2335) : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildToggleOption('Login', isLogin, () => _handleToggle(true)),
          _buildToggleOption('Register', !isLogin, () => _handleToggle(false)),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isSelected, VoidCallback onTap) {
    final themeService = context.watch<ThemeService>();
    final isDark = themeService.isDarkMode;
    final colors = themeService.colors;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF4A2C6D) : colors.textPrimary)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {String? errorText}) {
    final isDark = context.watch<ThemeService>().isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF333333),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          if (errorText != null)
            Text(
              errorText,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String hint,
    bool isPassword,
  ) {
    final isDark = context.watch<ThemeService>().isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2335) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF4A2F65) : const Color(0xFFD1D5DB),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF333333),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
