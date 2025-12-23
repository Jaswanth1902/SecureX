import 'package:flutter/material.dart';

class AppColors {
  final Color backgroundGradientStart;
  final Color backgroundGradientEnd;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconLock;
  final Color cardBackground;
  final Color cardBorder;
  final Color rejectButtonBg;
  final Color rejectIcon;
  final Color acceptGradientStart;
  final Color acceptGradientEnd;
  final List<BoxShadow> cardShadow;

  AppColors({
    required this.backgroundGradientStart,
    required this.backgroundGradientEnd,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconLock,
    required this.cardBackground,
    required this.cardBorder,
    required this.rejectButtonBg,
    required this.rejectIcon,
    required this.acceptGradientStart,
    required this.acceptGradientEnd,
    required this.cardShadow,
  });

  static final light = AppColors(
    // Soft Vaporwave Haze Gradient: Pink -> Lavender -> Blue
    backgroundGradientStart: const Color(0xFFFFB6C1), // Haze Pink
    backgroundGradientEnd: const Color(0xFFADD8E6),   // Haze Electric Blue
    
    // Text Colors
    textPrimary: const Color(0xFFFF69B4), // Pastel Neon Pink (for titles)
    textSecondary: const Color(0xFF9CA3AF), // Transparent Gray (approx for #E5E7EB with opacity) - using solid gray for clarity
    
    // Icons
    iconLock: const Color(0xFF40E0D0), // Pastel Neon Blue
    
    // Glassmorphism
    cardBackground: Colors.white.withOpacity(0.15),
    cardBorder: const Color(0xFFFFC0CB), // Start of iridescent border (Pink) - simple fallback for border color
    
    rejectButtonBg: const Color(0xFFFF69B4).withOpacity(0.15),
    rejectIcon: const Color(0xFFFF69B4), // Pastel Neon Pink
    
    acceptGradientStart: const Color(0xFF40E0D0), // Pastel Neon Blue
    acceptGradientEnd: const Color(0xFFBA55D3),   // Pastel Neon Lavender
    
    cardShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Dark Mode - Deep Purple Theme
  static final dark = AppColors(
    backgroundGradientStart: const Color(0xFF1e0a30),
    backgroundGradientEnd: const Color(0xFF3a1a5b),
    textPrimary: Colors.white,
    textSecondary: const Color(0xFF9CA3AF), // gray-400
    iconLock: const Color(0xFFFFAB40),
    cardBackground: Colors.white.withOpacity(0.05),
    cardBorder: Colors.white.withOpacity(0.1),
    rejectButtonBg: Colors.white.withOpacity(0.05),
    rejectIcon: const Color(0xFFd8b4fe), // purple-300
    acceptGradientStart: const Color(0xFF6A0DAD),
    acceptGradientEnd: const Color(0xFF9370DB),
    cardShadow: [
      BoxShadow(
        color: const Color(0xFF581C87).withOpacity(0.2), // shadow-purple-900/50ish approximation
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class ThemeService extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  AppColors get colors => _isDarkMode ? AppColors.dark : AppColors.light;

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}
