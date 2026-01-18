import 'package:flutter/material.dart';

class AppConstants {
  // Brand Colors
  static const Color primaryColor = Color(0xFFDD2476); // From Settings HTML
  static const Color secondaryColor = Color(0xFFFF512F); // From Settings HTML

  // Light Theme Gradient
  // Reference: linear-gradient(135deg, #FF6B6B 0%, #7B42F6 100%)
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF6B6B),
      Color(0xFF7B42F6),
    ],
  );

  // Dark Theme Gradient
  // Reference: linear-gradient(180deg, #031210 0%, #0c3834 40%, #108a77 85%, #15bba6 100%)
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.4, 0.85, 1.0],
    colors: [
      Color(0xFF031210),
      Color(0xFF0c3834),
      Color(0xFF108a77),
      Color(0xFF15bba6),
    ],
  );

  static LinearGradient getBackgroundGradient(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return darkGradient;
    }
    return lightGradient;
  }
  
  // Backwards compatibility if needed, but we should migrate
  static const LinearGradient backgroundGradient = lightGradient;
}
