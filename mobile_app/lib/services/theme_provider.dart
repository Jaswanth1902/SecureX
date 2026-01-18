import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // Default to Dark

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode');
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark; // Default to Dark if not set
    }
    notifyListeners();
  }

  Future<void> toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isOn);
    notifyListeners();
  }

  // Optional: Reset to system
  Future<void> setSystemTheme() async {
    _themeMode = ThemeMode.system;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isDarkMode');
    notifyListeners();
  }
}
