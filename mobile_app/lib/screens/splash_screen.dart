import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_print_user/main.dart'; // For AuthWrapper
import 'package:secure_print_user/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkPreferences();

    _controller = AnimationController(
        vsync: this, 
        duration: const Duration(milliseconds: 2500)
    );

    // Phase 1: Fade In (0ms - 1000ms)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Phase 2: Zoom In (1500ms - 2500ms)
    // Scale goes from 1 to 100 to fill the screen
    _scaleAnimation = Tween<double>(begin: 1.0, end: 100.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOutExpo),
      ),
    );

    // Navigate when animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });

    _controller.forward();
  }

  Future<void> _checkPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showOnboarding = !prefs.containsKey('hasSeenOnboarding');
    });
  }

  void _navigateToNext() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return _showOnboarding 
            ? OnboardingScreen(
                onFinish: (ctx) {
                   Navigator.of(ctx).pushReplacement(
                     MaterialPageRoute(builder: (_) => const AuthWrapper()),
                   );
                },
              )
            : const AuthWrapper();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.teal : Colors.pink;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Keep minimal width to center properly
            children: [
              Text(
                "Secure",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 1.2,
                  fontFamily: 'Roboto', // Or your app's font
                ),
              ),
              // The "X" that we will zoom into
              ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.center, // Scale from its own center
                child: Text(
                  "X",
                  style: TextStyle(
                    fontSize: 48, // Slightly larger
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
