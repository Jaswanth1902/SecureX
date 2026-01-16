import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'screens/upload_screen.dart';
import 'screens/file_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/encryption_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'services/error_logger.dart';
import 'widgets/notification_dropdown.dart';
import 'widgets/profile_info.dart';
import 'widgets/profile_card.dart';
import 'widgets/reset_password_dialog.dart';
import 'widgets/edit_name_dialog.dart';
import 'providers/theme_provider.dart';

import 'screens/print_screen.dart';

// Secure File Printing System - User Mobile App
// Main entry point for the Flutter mobile application

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    ErrorLogger().logError(
      context: 'FlutterError',
      message: details.exceptionAsString(),
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorLogger().logError(
      context: 'PlatformDispatcher',
      message: error.toString(),
      stackTrace: stack,
    );
    return true;
  };

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
      title: 'SecurePrint - User',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: themeProvider.isGradientMode
          ? ThemeData(
              primarySwatch: Colors.purple,
              useMaterial3: true,
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.transparent,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            )
          : ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              brightness: Brightness.light,
            ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const AuthWrapper(),
      routes: {
        '/upload': (context) => const UploadPage(),
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
    // Always clear tokens on launch to force login
    _userService.logout().then((_) => _checkAuthentication());
  }

  Future<void> _checkAuthentication() async {
    // Always require login if not authenticated, never skip
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
      return MyHomePage(
        title: 'SecurePrint - Send Files Securely',
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
  // ignore: unused_field
  final UserService _userService = UserService();
  Timer? _statusCheckTimer;

  // Placeholder pages
  final List<Widget> _pages = const <Widget>[
    HomePage(),
    UploadPage(),
    JobsPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize redirection on auth failure
    ApiService.onUnauthorized = () async {
      if (mounted) {
        widget.onLogout();
      }
    };
      _initializeNotifications();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _notificationService.dispose();
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

  bool _isCheckingStatus = false;

  // Backported logic: Use Local _apiService.listFiles() method
  Future<void> _checkFileStatuses() async {
    if (_isCheckingStatus) return;
    _isCheckingStatus = true;

    try {
      final files = await _apiService.listFiles();

      // Convert FileItem objects to Map for compatibility with NotificationService
      final filesMap = files
          .map((f) => {
                'file_id': f.fileId,
                'file_name': f.fileName,
                'file_size_bytes': f.fileSizeBytes,
                'uploaded_at': f.uploadedAt,
                'is_printed': f.isPrinted,
                'printed_at': f.printedAt,
                'status': f.status,
                'status_updated_at': f.statusUpdatedAt,
                'rejection_reason': f.rejectionReason,
              })
          .toList();

      await _notificationService.checkForStatusUpdates(filesMap);
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('DEBUG (MyHomePage): Auth failure: ${e.message}');
      }
      // Only logout if it's a persistent issue or explicit 401
      if (e.message.contains('expired') || e.message.contains('invalid')) {
        widget.onLogout();
      } else {
        debugPrint(
            'DEBUG (MyHomePage): Transient auth error, not logging out yet');
      }
    } catch (e) {
      debugPrint('Error checking file statuses: $e');
    } finally {
      _isCheckingStatus = false;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // No explicit call needed here, screens handle their own loading
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

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
      body: Center(
        child: _pages.elementAt(_selectedIndex),
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
        onTap: _onItemTapped,
      ),
    );

    if (themeProvider.isGradientMode) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
              Color(0xFF4facfe),
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: scaffoldBody,
      );
    }

    return scaffoldBody;
  }
}

// Placeholder pages - To be implemented

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserService _userService = UserService();
  final ApiService _apiService = ApiService();
  String? _userName;
  List<FileItem> _recentFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    // listen for changes to the full name so HomePage updates immediately
    _userService.fullNameNotifier.addListener(_handleNameChange);
  }

  @override
  void dispose() {
    _userService.fullNameNotifier.removeListener(_handleNameChange);
    super.dispose();
  }

  void _handleNameChange() {
    if (!mounted) return;
    final name = _userService.fullNameNotifier.value;
    setState(() {
      _userName = name ?? 'User';
    });
  }

  Future<void> _loadUserName() async {
    final fullName = await _userService.getFullName();
    if (mounted) {
      setState(() {
        _userName = fullName ?? "User";
      });
    }
    _fetchRecentFiles();
  }

  Future<void> _fetchRecentFiles() async {
    try {
      final files = await _apiService.getRecentFiles();
      if (mounted) {
        setState(() {
          _recentFiles = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error fetching recent files: $e');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Unknown';
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myHomePageState = context.findAncestorStateOfType<_MyHomePageState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 20),
          const Icon(Icons.security, size: 64, color: Colors.blue),
          const SizedBox(height: 24),
          Text(
            _userName != null ? 'Hi $_userName' : 'Hi',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Welcome to SecurePrint',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          const Text(
            'Send files securely to your printer',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Text(
                  'Recent Files',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    final state = context.findAncestorStateOfType<_MyHomePageState>();
                    state?._onItemTapped(2);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const CircularProgressIndicator()
          else if (_recentFiles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No recent files yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentFiles.length,
              itemBuilder: (context, index) {
                final file = _recentFiles[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Icon(Icons.description, color: theme.colorScheme.primary),
                      ),
                      title: Text(
                        file.fileName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_formatFileSize(file.fileSizeBytes)} \u2022 ${_formatDateTime(file.uploadedAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {
                        // Open file details (PrintScreen)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => PrintScreen(fileId: file.fileId),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
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
      child: const UploadScreen(),
    );
  }
}

// JobsPage now matches desktop: segmented control, unified file list, modern card style
class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FileListScreen();
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _feedbackController = TextEditingController();
  final ApiService _apiService = ApiService();
  final UserService _userService = UserService();
  bool _isSubmitting = false;
  String _userName = 'User';
  String _userEmail = '';
  int _uploads = 0;
  int _prints = 0;
  int _completed = 0;

  @override
  void dispose() {
    _feedbackController.dispose();
    _userService.fullNameNotifier.removeListener(_onFullNameChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    // subscribe to full name changes
    _userService.fullNameNotifier.addListener(_onFullNameChanged);
    if (!mounted) return;
    final name = _userService.fullNameNotifier.value;
    setState(() {
      _userName = (name != null && name.trim().isNotEmpty) ? name.trim() : 'User';
    });
  }

  Future<void> _loadUserProfile() async {
    final fullName = await _userService.getFullName();
    final phone = await _userService.getPhone();
    int uploads = 0;
    int prints = 0;
    int completed = 0;
    try {
      final files = await _apiService.listFiles();
      uploads = files.length;
      prints = files.where((f) => f.isPrinted == true).length;
      completed = files.where((f) => f.status == 'PRINT_COMPLETED').length;
    } catch (_) {}
    if (mounted) {
      setState(() {
        _userName = (fullName != null && fullName.trim().isNotEmpty)
            ? fullName.trim()
            : 'User';
        _userEmail = (phone ?? '').trim();
        _uploads = uploads;
        _prints = prints;
        _completed = completed;
      });
    }
  }

  Future<void> _editName() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => EditNameDialog(
        initialName: _userName,
        onNameChanged: (name) {
          Navigator.of(ctx).pop(name);
        },
      ),
    );
    if (newName != null && newName.trim().isNotEmpty && newName != _userName) {
      await _userService.updateFullName(newName.trim());
      setState(() {
        _userName = newName.trim();
      });
    }
  }

  void _onFullNameChanged() {
    if (!mounted) return;
    final name = _userService.fullNameNotifier.value;
    setState(() {
      _userName = (name != null && name.trim().isNotEmpty) ? name.trim() : 'User';
    });
  }

  Future<void> _logoutFromProfile() async {
    await _userService.logout();
    if (mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _submitFeedback() async {
    final message = _feedbackController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _apiService.submitFeedback(message: message);
      if (success && mounted) {
        _feedbackController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ProfileCard(
          userName: _userName,
          userEmail: _userEmail,
          onLogout: null,
          onEditProfile: _editName,
          uploads: _uploads,
          prints: _prints,
          completed: _completed,
        ),
        const SizedBox(height: 24),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.brightness_6),
          title: const Text('Theme'),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: themeProvider.isGradientMode
                  ? 'Gradient'
                  : (themeProvider.isDarkMode ? 'Dark' : 'Light'),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  if (newValue == 'Gradient') {
                    themeProvider.setTheme(AppTheme.gradient);
                  } else {
                    themeProvider.toggleTheme(newValue == 'Dark');
                  }
                }
              },
              items: <String>['Light', 'Dark', 'Gradient']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_reset),
          title: const Text('Reset Password'),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const ResetPasswordDialog(),
            );
          },
        ),
        const SizedBox(height: 32),
        const Text(
          'Feedback',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeProvider.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey[300]!,
            ),
          ),
          child: TextField(
            controller: _feedbackController,
            maxLines: 6,
            minLines: 5,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Write your feedback here...',
              contentPadding: EdgeInsets.all(20),
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey),
            ),
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Feedback'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Help & Support'),
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Help & Support'),
                content: const Text('Contact support@secureprint.com for help.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('About'),
                content: const Text('SecurePrint Mobile App v1.0.0'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}