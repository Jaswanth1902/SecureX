import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/file_item.dart';
import 'login_screen.dart';
import 'print_preview_screen.dart';
import 'print_history_screen.dart';
import 'settings_screen.dart';
import '../services/theme_service.dart';
import '../widgets/file_card.dart';
import '../widgets/glass_dialog.dart';
import 'package:path/path.dart' as path;

import 'dart:async'; // Add this import

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<FileItem> _files = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _refreshTimer; // Add Timer variable

  @override
  void initState() {
    super.initState();
    _loadFiles();
    
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // Logic: Only reload if we are not already loading to prevent race conditions or spam
      if (!_isLoading) {
        _loadFiles(showLoading: false);
      }
    });
    
    // Defer notification connection until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotifications();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Clean up timer
    super.dispose();
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
          onPressed: () => _loadFiles(showLoading: true),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
    
    // Auto-refresh
    _loadFiles(showLoading: false);
  }

  Future<void> _loadFiles({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final authService = context.read<AuthService>();
      final apiService = context.read<ApiService>();
      
      if (authService.accessToken == null) {
        print('DEBUG: No access token found. Redirecting to login.');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      print('DEBUG: Fetching files with token: ${authService.accessToken!.substring(0, 10)}...');
      final files = await apiService.listFiles(authService.accessToken!);
      print('DEBUG: API returned ${files.length} files.');
      
      final validFiles = <FileItem>[];
      final invalidFiles = <FileItem>[];

      for (var f in files) {
        final ext = path.extension(f.fileName).toLowerCase();
        // Strict allow-list: PDF and DOCX only
        if (ext == '.pdf' || ext == '.docx') {
          validFiles.add(f);
        } else {
          invalidFiles.add(f);
        }
      }

      // Auto-reject invalid files in background
      for (var f in invalidFiles) {
        _rejectSilently(f);
      }

      if (invalidFiles.isNotEmpty) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Auto-rejected ${invalidFiles.length} file(s) with invalid extensions.')),
            );
         }
      }

      setState(() {
        _files = validFiles;
      });
    } catch (e) {
      print('DEBUG: Error fetching files: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rejectSilently(FileItem file) async {
    try {
      final authService = context.read<AuthService>();
      final apiService = context.read<ApiService>();
      
      print('Auto-rejecting: ${file.fileName}');

      // Try to update status
      try {
        await apiService.updateFileStatus(
          file.fileId,
          'REJECTED',
          authService.accessToken!,
          rejectionReason: 'invalid file extension',
        );
      } catch (_) {}

      // Delete file
      await apiService.deleteFile(file.fileId, authService.accessToken!);
    } catch (e) {
      print('Error auto-rejecting ${file.fileName}: $e');
    }
  }

  void _handleLogout() {
    context.read<NotificationService>().dispose();
    context.read<AuthService>().logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _acceptFile(FileItem file) async {
    final authService = context.read<AuthService>();
    final apiService = context.read<ApiService>();
    
    // Try to update status to APPROVED (but continue even if it fails)
    try {
      await apiService.updateFileStatus(
        file.fileId,
        'APPROVED',
        authService.accessToken!,
      );
      print('Status updated to APPROVED');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File accepted! Opening print preview...')),
      );
    } catch (statusError) {
      // Log error but continue with print preview
      print('Warning: Status update failed: $statusError');
      print('Continuing with print preview...');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening print preview...')),
      );
    }
    
    // Always open print preview
    _openPrintPreview(file);
  }

  void _openPrintPreview(FileItem file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrintPreviewScreen(fileId: file.fileId, fileName: file.fileName),
      ),
    ).then((_) => _loadFiles()); // Refresh after returning (in case printed/deleted)
  }

  Future<void> _deleteFile(FileItem file) async {
    final confirm = await showDialog<bool>(
      barrierColor: Colors.black.withOpacity(0.7), // Dimmed background
      context: context,
      builder: (context) => GlassDialog(
        title: 'Reject Request?',
        content: 'Are you sure you want to reject printing for "${file.fileName}"? This will delete the file from the server permanently.',
        confirmText: 'Yes, Reject',
        isDestructive: true,
        onConfirm: () {}, // Logic handled by awaiting result
      ),
    );

    if (confirm != true) return;

    try {
      final authService = context.read<AuthService>();
      final apiService = context.read<ApiService>();
      
      // Try to update status to REJECTED (but continue even if it fails)
      try {
        await apiService.updateFileStatus(
          file.fileId,
          'REJECTED',
          authService.accessToken!,
          rejectionReason: 'Rejected by owner from dashboard',
        );
        print('Status updated to REJECTED');
      } catch (statusError) {
        // Log error but continue with delete
        print('Warning: Status update failed: $statusError');
        print('Continuing with file deletion...');
      }
      
      // Always delete the file
      await apiService.deleteFile(file.fileId, authService.accessToken!);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File rejected and deleted successfully.')),
      );
      _loadFiles(); // Refresh list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Group files by date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayFiles = <FileItem>[];
    final yesterdayFiles = <FileItem>[];
    final olderFiles = <FileItem>[];

    for (var file in _files) {
      if (file.isPrinted) continue; // Skip printed files for active dashboard

      DateTime? fileDate;
      try {
        fileDate = DateTime.parse(file.uploadedAt);
      } catch (_) {
        fileDate = null;
      }

      if (fileDate != null) {
        final dateOnly = DateTime(fileDate.year, fileDate.month, fileDate.day);
        if (dateOnly.isAtSameMomentAs(today)) {
          todayFiles.add(file);
        } else if (dateOnly.isAtSameMomentAs(yesterday)) {
          yesterdayFiles.add(file);
        } else {
          olderFiles.add(file);
        }
      } else {
        olderFiles.add(file);
      }
    }

    final themeService = context.watch<ThemeService>();
    final colors = themeService.colors;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 28,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          _buildCircleActionButton(Icons.history, 'History', () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrintHistoryScreen()));
          }, colors),
          _buildCircleActionButton(Icons.refresh, 'Refresh', () => _loadFiles(showLoading: true), colors),
          _buildCircleActionButton(Icons.settings, 'Settings', () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }, colors),
          _buildCircleActionButton(Icons.logout, 'Logout', _handleLogout, colors),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.backgroundGradientStart, colors.backgroundGradientEnd],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_errorMessage!,
                              style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                              onPressed: () => _loadFiles(showLoading: true), child: const Text('Retry')),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadFiles(showLoading: true),
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          if (todayFiles.isNotEmpty) ...[
                            _buildSectionHeader('Today', colors),
                            ...todayFiles.map((file) => FileCard(
                                  file: file,
                                  onAccept: () => _acceptFile(file),
                                  onReject: () => _deleteFile(file),
                                )),
                          ],
                          if (yesterdayFiles.isNotEmpty) ...[
                            _buildSectionHeader('Yesterday', colors),
                            ...yesterdayFiles.map((file) => FileCard(
                                  file: file,
                                  onAccept: () => _acceptFile(file),
                                  onReject: () => _deleteFile(file),
                                )),
                          ],
                          if (olderFiles.isNotEmpty) ...[
                            _buildSectionHeader('Older Files', colors),
                            ...olderFiles.map((file) => FileCard(
                                  file: file,
                                  onAccept: () => _acceptFile(file),
                                  onReject: () => _deleteFile(file),
                                )),
                          ],
                          if (_files.isEmpty || 
                              (todayFiles.isEmpty && yesterdayFiles.isEmpty && olderFiles.isEmpty))
                            _buildEmptyState(colors),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildCircleActionButton(IconData icon, String tooltip, VoidCallback onPressed, AppColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        shape: BoxShape.circle,
        boxShadow: colors.cardShadow,
      ),
      child: IconButton(
        icon: Icon(icon, color: colors.textPrimary),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 24, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }


  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.cloud_done, // Or cloud_done_outlined
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'All categories clear!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No new files to review. Pull to refresh.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
