import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'screens/upload_screen.dart';
import 'screens/file_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart'; 
import 'screens/settings_screen.dart';
import 'services/encryption_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'services/theme_provider.dart';
import 'services/file_history_service.dart'; // Import FileHistoryService
import 'utils/constants.dart';

// Secure File Printing System - User Mobile App
// Main entry point for the Flutter mobile application

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SecurePrintUserApp(),
    ),
  );
}

class SecurePrintUserApp extends StatelessWidget {
  const SecurePrintUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'SecureX',
          theme: ThemeData(
            primarySwatch: Colors.pink,
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.teal,
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.transparent, 
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Colors.black26, 
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

// Authentication Wrapper - Shows login screen or main app
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final isAuth = await _userService.isAuthenticated();
    setState(() {
      _isAuthenticated = isAuth;
      _isLoading = false;
    });
  }

  void _handleLoginSuccess(String accessToken, String userId) {
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _handleLogout() async {
    await _userService.logout();
    setState(() {
      _isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isAuthenticated) {
      return MainLayout(
        onLogout: _handleLogout,
      );
    }

    return AuthScreen(onLoginSuccess: _handleLoginSuccess);
  }
}

// Auth Screen - Login/Register switcher
class AuthScreen extends StatefulWidget {
  final Function(String accessToken, String userId) onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLogin = true;

  void _toggleScreen() {
    setState(() {
      _showLogin = !_showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return Scaffold(
        body: LoginScreen(
          onLoginSuccess: widget.onLoginSuccess,
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextButton(
            onPressed: _toggleScreen,
            child: const Text("Don't have an account? Register here"),
          ),
        ),
      );
    } else {
      return Scaffold(
        body: RegisterScreen(
          onRegisterSuccess: widget.onLoginSuccess,
          onHaveAccount: _toggleScreen,
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextButton(
            onPressed: _toggleScreen,
            child: const Text("Already have an account? Login here"),
          ),
        ),
      );
    }
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({
    super.key,
    required this.onLogout,
  });

  final VoidCallback onLogout;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Notification service & API logic
  final NotificationService _notificationService = NotificationService();
  final ApiService _apiService = ApiService();
  final UserService _userService = UserService();
  final FileHistoryService _fileHistoryService = FileHistoryService(); // Local History
  Timer? _statusCheckTimer;
  int _currentIndex = 1; // Start at Home (middle page)
  late final PageController _pageController = PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _notificationService.dispose();
    _pageController.dispose(); // Dispose the PageController
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkFileStatuses(),
    );
    _checkFileStatuses();
  }

  Future<void> _checkFileStatuses() async {
    try {
      String? accessToken = await _userService.getAccessToken();
      
      if (accessToken == null) {
        return;
      }
      
      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/api/files'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['files'] is List) {
          final serverFiles = (data['files'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          
          // Merge with Local History to detect REJECTED files (missing from server)
          final mergedFiles = await _fileHistoryService.mergeWithServerFiles(serverFiles);

          await _notificationService.checkForStatusUpdates(mergedFiles);
        }
      }
    } catch (e) {
      debugPrint('Error checking file statuses: $e');
    }
  }

  String? _selectedFilePath;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 1, // Can pop only if on Home screen (index 1)
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        // If not on Home screen, navigate to Home
        _pageController.animateToPage(
          1, // Home Index
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        decoration: BoxDecoration(gradient: AppConstants.getBackgroundGradient(context)),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: [
              // Index 0: History
              const JobsPage(),
              
              // Index 1: Home
              HomeScreen(
                onLogout: widget.onLogout,
                notificationService: _notificationService,
                onTabSwitchRequested: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                onFileSelectedForUpload: (path) {
                  setState(() {
                    _selectedFilePath = path;
                  });
                  _pageController.animateToPage(
                    2, // Upload Index
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              
              // Index 2: Upload
              UploadPage(filePath: _selectedFilePath),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Wrappers for direct navigation from Home
class UploadPage extends StatelessWidget {
  final String? filePath;
  const UploadPage({super.key, this.filePath});

  @override
  Widget build(BuildContext context) {
    // Only used correctly wrapping providers
    final encryptionService = EncryptionService();
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        Provider<EncryptionService>.value(value: encryptionService),
        Provider<ApiService>.value(value: apiService),
      ],
      child: UploadScreen(initialFilePath: filePath),
    );
  }
}

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Import and use the FileListScreen which shows file status
    return const FileListScreen();
  }
}
