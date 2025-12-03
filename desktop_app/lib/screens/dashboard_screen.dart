import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/file_item.dart';
import 'login_screen.dart';
import 'print_preview_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<FileItem> _files = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFiles();
    
    // Defer notification connection until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotifications();
    });
  }

  void _setupNotifications() {
    final authService = context.read<AuthService>();
    final notificationService = context.read<NotificationService>();
    
    if (authService.accessToken != null) {
      notificationService.connect(authService.accessToken!);
      
      notificationService.events.listen((event) {
        if (event['event'] == 'new_file') {
          _handleNewFile(event['data']);
        }
      });
    }
  }

  void _handleNewFile(Map<String, dynamic> data) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New file received: ${data['file_name']}'),
        action: SnackBarAction(
          label: 'Refresh',
          onPressed: _loadFiles,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
    
    // Auto-refresh
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final apiService = context.read<ApiService>();
      
      if (authService.accessToken == null) {
        // ignore: avoid_print
        print('DEBUG: No access token found. Redirecting to login.');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      // ignore: avoid_print
      print('DEBUG: Fetching files with token: ${authService.accessToken!.substring(0, 10)}...');
      final files = await apiService.listFiles(authService.accessToken!);
      // ignore: avoid_print
      print('DEBUG: API returned ${files.length} files.');
      
      for (var f in files) {
        // ignore: avoid_print
        print('DEBUG: File found: ${f.fileName} (ID: ${f.fileId})');
      }

      setState(() {
        _files = files;
      });
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG: Error fetching files: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLogout() {
    context.read<NotificationService>().dispose();
    context.read<AuthService>().logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openPrintPreview(FileItem file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrintPreviewScreen(fileId: file.fileId, fileName: file.fileName),
      ),
    ).then((_) => _loadFiles()); // Refresh after returning (in case printed/deleted)
  }

  Future<void> _deleteFile(FileItem file) async {
    // Read services before async gap
    final authService = context.read<AuthService>();
    final apiService = context.read<ApiService>();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: Text('Are you sure you want to cancel printing for "${file.fileName}"? This will delete the file from the server permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await apiService.deleteFile(file.fileId, authService.accessToken!);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File deleted successfully.')),
      );
      _loadFiles(); // Refresh list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeCopy Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Memory Check / Security Banner
          Container(
            width: double.infinity,
            color: Colors.black87,
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.memory, color: Colors.greenAccent),
                const SizedBox(width: 12),
                Text(
                  'MEMORY CHECK: RAM-Only Mode. ${_files.length} Files Loaded in Session.',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadFiles,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _files.isEmpty
                        ? const Center(child: Text('No files found.'))
                        : ListView.builder(
                            itemCount: _files.length,
                            itemBuilder: (context, index) {
                              final file = _files[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: Icon(
                                    file.isPrinted ? Icons.check_circle : Icons.lock,
                                    color: file.isPrinted ? Colors.green : Colors.orange,
                                  ),
                                  title: Text(file.fileName),
                                  subtitle: Text(
                                    'Size: ${(file.fileSizeBytes / 1024).toStringAsFixed(1)} KB\nUploaded: ${file.uploadedAt}',
                                  ),
                                  trailing: file.isPrinted
                                      ? const Text('Printed', style: TextStyle(color: Colors.grey))
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextButton.icon(
                                              icon: const Icon(Icons.cancel, color: Colors.red),
                                              label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                                              onPressed: () => _deleteFile(file),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.print),
                                              label: const Text('Print'),
                                              onPressed: () => _openPrintPreview(file),
                                            ),
                                          ],
                                        ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
