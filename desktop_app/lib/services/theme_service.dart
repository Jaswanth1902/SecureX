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
    backgroundGradientStart: const Color(0xFFf7f0fb),
    backgroundGradientEnd: const Color(0xFFefffff),
    textPrimary: const Color(0xFF333333),
    textSecondary: const Color(0xFF888888),
    iconLock: const Color(0xFFFFAB40),
    cardBackground: Colors.white.withOpacity(0.6),
    cardBorder: Colors.white.withOpacity(0.4),
    rejectButtonBg: const Color(0xFF8A2BE2).withOpacity(0.1),
    rejectIcon: const Color(0xFF888888),
    acceptGradientStart: const Color(0xFF8A2BE2),
    acceptGradientEnd: const Color(0xFFBA55D3),
    cardShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 16,
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
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  AppColors get colors => _isDarkMode ? AppColors.dark : AppColors.light;

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}
