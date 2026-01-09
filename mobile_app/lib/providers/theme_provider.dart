import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { light, dark, gradient }

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  AppTheme _appTheme = AppTheme.light;

  ThemeMode get themeMode => _themeMode;
  AppTheme get appTheme => _appTheme;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isGradientMode => _appTheme == AppTheme.gradient;

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
    if (theme == AppTheme.gradient) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = theme == AppTheme.dark ? ThemeMode.dark : ThemeMode.light;
    }
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
    if (_appTheme == AppTheme.gradient) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = _appTheme == AppTheme.dark ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> _saveTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appTheme', theme.toString().split('.').last);
  }
}