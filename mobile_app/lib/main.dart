import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'screens/upload_screen.dart';
import 'screens/file_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/encryption_service.dart';
import 'services/api_service.dart';

import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'services/file_history_service.dart';
import 'dart:io';
import 'widgets/notification_dropdown.dart';
import 'widgets/profile_info.dart';
import 'widgets/reset_password_dialog.dart';
import 'providers/theme_provider.dart';

// Secure File Printing System - User Mobile App
// Main entry point for the Flutter mobile application

void main() {
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'SecureX',
      themeMode: themeProvider.themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const AuthWrapper(),
    );
  }

  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFAFCFF),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFF111827),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white.withOpacity(0.88),
        shadowColor: Colors.black.withOpacity(0.10),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF60A5FA),
        brightness: Brightness.dark,
      ),
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A2B3F),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFFF1F5F9),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E293B).withOpacity(0.85),
        shadowColor: Colors.black.withOpacity(0.25),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D3E5F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF475569)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF475569)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: const TextStyle(color: Color(0xFFCBD5E1)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF60A5FA),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _userService.logout();
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isAuthenticated) {
      return MyHomePage(
        title: 'SecureX',
       
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.onLogout,
  });

  final String title;
  final VoidCallback onLogout;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  
  // Notification service
  final NotificationService _notificationService = NotificationService();
  final ApiService _apiService = ApiService();
  final UserService _userService = UserService();
  Timer? _statusCheckTimer;

  // Placeholder pages
  late PageController _pageController;

  final List<Widget> _pages = const <Widget>[
    HomePage(),
    UploadPage(),
    JobsPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _initializeNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure PageView is at the correct page after theme changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_selectedIndex);
      }
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _notificationService.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    // Start periodic status checks (every 30 seconds)
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkFileStatuses(),
    );
    // Check immediately on startup
    _checkFileStatuses();
  }

  List<Map<String, dynamic>> _files = [];

  Future<void> _checkFileStatuses() async {
    try {
      String? accessToken = await _userService.getAccessToken();

      if (accessToken == null) {
        debugPrint('No access token - user not authenticated');
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
          setState(() {
            _files = (data['files'] as List)
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          });

          await _notificationService.checkForStatusUpdates(_files);
        }
      }
    } catch (e) {
      debugPrint('Error checking file statuses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    Widget scaffoldBody = Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        actions: [
          // Notification button
          NotificationDropdown(notificationService: _notificationService),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: widget.onLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );

    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FBFF),
      child: scaffoldBody,
    );
  }
}

// Placeholder pages - To be implemented

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static final GlobalKey<_RecentFilesSectionState> _recentFilesKey = GlobalKey<_RecentFilesSectionState>();
  
  /// Call this to refresh recent files from anywhere
  static void refreshRecentFiles() {
    _recentFilesKey.currentState?.refreshFiles();
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserService _userService = UserService();
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final fullName = await _userService.getFullName();
    if (mounted) {
      setState(() {
        _userName = fullName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isGradient = themeProvider.isGradientMode;
    
    // Unified theme colors - used consistently across all pages
    // Gradient theme uses light surfaces for visibility on colorful background
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF111827);
    final secondaryTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563);
    final cardColor = isDark 
        ? const Color(0xFF1E293B).withOpacity(0.85)
        : Colors.white.withOpacity(0.88);
    final iconBgColor = isDark
        ? const Color(0xFF2D3E5F)
        : const Color(0xFFF3F4FF);
    final iconColor = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF2563EB);
    final shadowColor = Colors.black.withOpacity(isDark ? 0.25 : 0.10);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shield,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName != null ? 'Welcome, ${_userName!.split(' ')[0]}!' : 'Welcome!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 0),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Recent Files Section
          Text(
            'Recent Files',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          RecentFilesSection(key: HomePage._recentFilesKey),
        ],
      ),
    );
  }
}

class RecentFilesSection extends StatefulWidget {
  const RecentFilesSection({super.key});

  @override
  State<RecentFilesSection> createState() => _RecentFilesSectionState();
}

class _RecentFilesSectionState extends State<RecentFilesSection> {
  final ApiService _apiService = ApiService();
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      await _fetchRecentFiles();
    } catch (e) {
      debugPrint('Error loading files: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Public method to refresh files (called after successful upload)
  Future<void> refreshFiles() async {
    await _loadFiles();
  }

  Future<void> _fetchRecentFiles() async {
    try {
      final accessToken = await _userService.getAccessToken();
      if (accessToken == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _files = [];
          });
        }
        return;
      }

      final response = await _apiService.listFiles(accessToken: accessToken);

      if (mounted) {
        // Convert FileItem objects to Map for display
        final serverFiles = response
            .map((file) => {
                  'file_id': file.fileId,
                  'file_name': file.fileName,
                  'file_size_bytes': file.fileSizeBytes,
                  'uploaded_at': file.uploadedAt,
                  'status': file.status,
                })
            .toList();

        // Merge with local history so we can surface local-only metadata (like local_path)
        final fileHistoryService = FileHistoryService();
        final merged = await fileHistoryService.mergeWithServerFiles(serverFiles);
        final filtered = await fileHistoryService.filterDismissedFiles(merged);

        // Sort by uploaded_at desc and limit to last 10
        filtered.sort((a, b) {
          try {
            final da = DateTime.parse(a['uploaded_at'] ?? '1970-01-01');
            final db = DateTime.parse(b['uploaded_at'] ?? '1970-01-01');
            return db.compareTo(da);
          } catch (e) {
            return 0;
          }
        });

        final limited = filtered.take(10).toList();

        setState(() {
          _files = limited;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching recent files: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _files = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final secondaryTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563);

    if (_isLoading) {
      return Center(
        child: SizedBox(
          height: 40,
          width: 40,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
            ),
          ),
        ),
      );
    }

    if (_files.isEmpty) {
      return Text(
        'No files uploaded yet.',
        style: TextStyle(
          fontSize: 16,
          color: secondaryTextColor,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        final fileName = file['file_name'] ?? 'Unknown File';
        final uploadedAt = file['uploaded_at'] ?? 'N/A';
        final fileSize = file['file_size_bytes'];
        final localPath = file['local_path'];

        return ListTile(
          title: Text(fileName, overflow: TextOverflow.ellipsis),
          subtitle: Text(fileSize != null
              ? '${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB • Uploaded: $uploadedAt'
              : 'Uploaded: $uploadedAt'),
          trailing: IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Upload again',
            onPressed: () async {
              // If we have a local path, try to load the file directly and open UploadScreen
              if (localPath != null && localPath is String && localPath.isNotEmpty) {
                final ioFile = File(localPath);
                if (await ioFile.exists()) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => UploadScreen(initialFilePath: localPath),
                  ));
                  return;
                }
              }

              // Fallback: tell the user to pick the file (open Upload page)
              final pick = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Upload Again'),
                  content: const Text(
                      'Local copy not found. You can browse to select the file again.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Browse')),
                  ],
                ),
              );

              if (pick == true) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UploadScreen()));
              }
            },
          ),
        );
      },
    );
  }
}

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final encryptionService = EncryptionService();
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        Provider<EncryptionService>.value(value: encryptionService),
        Provider<ApiService>.value(value: apiService),
      ],
      child: UploadScreenWrapper(onUploadSuccess: () {
        // Refresh recent files after successful upload
        HomePage.refreshRecentFiles();
      }),
    );
  }
}

/// Wrapper widget that catches upload success and notifies listeners
class UploadScreenWrapper extends StatelessWidget {
  final VoidCallback? onUploadSuccess;
  
  const UploadScreenWrapper({this.onUploadSuccess, super.key});

  @override
  Widget build(BuildContext context) {
    return const UploadScreen();
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

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isGradient = themeProvider.isGradientMode;
    
    // Unified theme colors - matches HomePage and UploadPage colors
    // Gradient theme uses light surfaces for visibility on colorful background
    // Text colors with gradient theme support - ensuring visibility on colorful background
    final textColor = (isDark && !isGradient) 
        ? const Color(0xFFF1F5F9) 
        : const Color(0xFF111827);  // Dark text for light/gradient themes
    final secondaryTextColor = (isDark && !isGradient) 
        ? const Color(0xFFCBD5E1) 
        : const Color(0xFF4B5563);  // Medium-dark text for visibility
    final cardColor = isDark 
        ? const Color(0xFF1E293B).withOpacity(0.85)
        : Colors.white.withOpacity(0.88);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final iconColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your account and preferences',
          style: TextStyle(
            fontSize: 14,
            color: secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        
        // Profile Section
        const ProfileInfo(),
        const SizedBox(height: 28),
        
        // Preferences Section
        _buildSectionHeader('Preferences', textColor),
        const SizedBox(height: 12),
        _buildSettingsCard(
          cardColor: cardColor,
          dividerColor: dividerColor,
          icon: Icons.brightness_6,
          iconColor: const Color(0xFFF59E0B),
          title: 'Theme',
          subtitle: 'Choose your preferred theme',
          themeProvider: themeProvider,
          isDark: isDark,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        const SizedBox(height: 12),
        
        // Security Section
        _buildSectionHeader('Security', textColor),
        const SizedBox(height: 12),
        _buildSecurityOption(
          cardColor: cardColor,
          dividerColor: dividerColor,
          icon: Icons.lock_reset,
          iconColor: const Color(0xFF3B82F6),
          title: 'Change Password',
          subtitle: 'Update your password',
          context: context,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        const SizedBox(height: 12),
        _buildSecurityOption(
          cardColor: cardColor,
          dividerColor: dividerColor,
          icon: Icons.info_outline,
          iconColor: const Color(0xFF8B5CF6),
          title: 'About',
          subtitle: 'App version and information',
          context: context,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          isAbout: true,
        ),
        const SizedBox(height: 28),
        
        // Info Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFBFC),
            border: Border.all(color: dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shield,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Security & Privacy',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '• AES-256-GCM encryption\n'
                '• End-to-end security\n'
                '• No plain text storage\n'
                '• Secure communication',
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsCard({
    required Color cardColor,
    required Color dividerColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required ThemeProvider themeProvider,
    required bool isDark,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: dividerColor),
              borderRadius: BorderRadius.circular(6),
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: themeProvider.isDarkMode ? 'Dark' : 'Light',
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    themeProvider.toggleTheme(newValue == 'Dark');
                  }
                },
                dropdownColor: cardColor,
                icon: const Icon(Icons.expand_more, size: 20),
                items: <String>['Light', 'Dark']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOption({
    required Color cardColor,
    required Color dividerColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required BuildContext context,
    required Color textColor,
    required Color secondaryTextColor,
    bool isAbout = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isAbout) {
            showDialog(
              context: context,
              builder: (context) => const _AboutDialog(),
            );
          } else {
            showDialog(
              context: context,
              builder: (context) => const ResetPasswordDialog(),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right,
                color: secondaryTextColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================
// CUSTOM ABOUT DIALOG (No Licenses Section)
// ========================================
class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF1A2B3F) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF111827);
    final secondaryTextColor = isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563);

    return AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'About SecureX',
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // App Name
            Text(
              'SecureX',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            
            
            const SizedBox(height: 16),

            // Version
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Version',
                  style: TextStyle(color: secondaryTextColor, fontSize: 13),
                ),
                Text(
                  '1.0.0',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Build Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Build',
                  style: TextStyle(color: secondaryTextColor, fontSize: 13),
                ),
                Text(
                  'Production Ready',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Security Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Encryption',
                  style: TextStyle(color: secondaryTextColor, fontSize: 13),
                ),
                Text(
                  'AES-256-GCM',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'A secure file  printing system with end-to-end encryption.',
              style: TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: TextStyle(color: const Color(0xFF2563EB), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}