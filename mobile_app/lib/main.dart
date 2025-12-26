import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'screens/upload_screen.dart';
import 'screens/file_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/encryption_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'widgets/notification_dropdown.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const SecurePrintUserApp());
}

class SecurePrintUserApp extends StatelessWidget {
  const SecurePrintUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecurePrint - User',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
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

  Future<void> _checkFileStatuses() async {
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
        print(
            'DEBUG (MyHomePage): Auth failure detected during periodic check: ${e.message}');
        print('DEBUG (MyHomePage): Force redirecting to Login screen');
      }
      widget.onLogout();
    } catch (e) {
      debugPrint('Error checking file statuses: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Refresh notifications when switching to Jobs tab
    if (index == 2) {
      _checkFileStatuses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        onTap: _onItemTapped,
      ),
    );
  }
}

// Placeholder pages - To be implemented

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.security, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Welcome to SecurePrint',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Send files securely to your printer',
            style: TextStyle(fontSize: 16, color: Colors.grey),
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

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.settings, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Settings coming soon',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
