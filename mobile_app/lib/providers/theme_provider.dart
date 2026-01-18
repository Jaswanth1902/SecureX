import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { light, dark }

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  AppTheme _appTheme = AppTheme.light;

  ThemeMode get themeMode => _themeMode;
  AppTheme get appTheme => _appTheme;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _appTheme = isDark ? AppTheme.dark : AppTheme.light;
    _saveTheme(_appTheme);
    notifyListeners();
  }

  void setTheme(AppTheme theme) {
    _appTheme = theme;
    _themeMode = theme == AppTheme.dark ? ThemeMode.dark : ThemeMode.light;
    _saveTheme(theme);
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('appTheme') ?? 'light';
    _appTheme = AppTheme.values.firstWhere(
      (e) => e.toString() == 'AppTheme.$themeString',
      orElse: () => AppTheme.light,
    );
    _themeMode = _appTheme == AppTheme.dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> _saveTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appTheme', theme.toString().split('.').last);
  }
}
