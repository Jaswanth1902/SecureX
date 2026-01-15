import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'screens/upload_screen.dart';
import 'screens/file_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'services/encryption_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
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
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => MyHomePage(
              title: 'SecurePrint - Send Files Securely',
              onLogout: () async {
                await UserService().logout();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),
      },
    );
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
      await UserService().logout();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
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
  // ignore: unused_field
  final UserService _userService = UserService();
  final ApiService _apiService = ApiService();
  String? _userName;
  List<FileItem> _recentFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
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
                    // Navigate to Jobs tab (index 2)
                    final state =
                        context.findAncestorStateOfType<_MyHomePageState>();
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child:
                            const Icon(Icons.description, color: Colors.blue),
                      ),
                      title: Text(
                        file.fileName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_formatFileSize(file.fileSizeBytes)} • ${_formatDateTime(file.uploadedAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
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

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Import and use the FileListScreen which shows file status
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
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
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
        const ProfileInfo(),
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
        const SizedBox(height: 40),
      ],
    );
  }
}