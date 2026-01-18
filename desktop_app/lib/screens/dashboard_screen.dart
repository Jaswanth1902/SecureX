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
import '../services/file_history_service.dart'; // Import History Service
import '../models/history_item.dart'; // Import History Item
import '../widgets/file_card.dart';
import '../widgets/glass_dialog.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:printing/printing.dart';
import '../services/key_service.dart';
import '../services/encryption_service.dart';


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
  Timer? _refreshTimer;
  Duration _pollInterval = const Duration(seconds: 5); // Start with 5s


  @override
  void initState() {
    super.initState();
    _loadFiles();
    
    // Start adaptive polling
    _scheduleNextPoll();
    
    // Defer notification connection until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotifications();
    });
  }

  void _scheduleNextPoll() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(_pollInterval, () async {
      if (mounted && !_isLoading) {
        await _loadFiles(showLoading: false);
      }
      if (mounted) _scheduleNextPoll();
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
        // Check status: Only show pending files
        bool isPending = f.status == 'WAITING_FOR_APPROVAL' || 
                         f.status == 'UPLOADED' || 
                         f.status == 'APPROVED'; // Legacy support

        if (!isPending) continue; // Skip REJECTED, CANCELLED, PRINT_COMPLETED

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
      
      // Notification removed as per user request


      setState(() {
        _files = validFiles;
        // Reset backoff on success
        _pollInterval = const Duration(seconds: 5);
      });
    } catch (e) {
      print('DEBUG: Error fetching files: $e');
      setState(() {
        _errorMessage = e.toString();
        // Increase backoff on error (max 60s)
        _pollInterval = _pollInterval * 2;
        if (_pollInterval.inSeconds > 60) {
          _pollInterval = const Duration(seconds: 60);
        }
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
      } catch (e) {
        print('Error updating status for auto-reject: $e');
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Failed to update status for invalid file: ${file.fileName}')),
           );
        }
      }

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

  Future<void> _handlePrintFlow(FileItem file) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Text('Decrypting file...'),
          ],
        ),
      ),
    );

    try {
      final authService = context.read<AuthService>();
      final apiService = context.read<ApiService>();
      final encryptionService = context.read<EncryptionService>();
      final keyService = context.read<KeyService>();

      // 1. Fetch file data
      final fileData = await apiService.getFileForPrinting(file.fileId, authService.accessToken!);

      // 2. Get key pair
      final userEmail = authService.user?['email'];
      if (userEmail == null) throw Exception('User not authenticated');
      
      final keyPair = await keyService.getStoredKeyPair(userEmail);
      if (keyPair == null) throw Exception('No private key found. Cannot decrypt.');

      // 3. Decrypt symmetric key
      final encryptedSymmetricKey = _decodeBase64(fileData.encryptedSymmetricKey);
      final aesKey = await keyService.decryptSymmetricKey(
        base64Encode(encryptedSymmetricKey), // Re-encode after cleaning
        keyPair,
      );

      // 4. Decrypt file
      final encryptedFileBytes = _decodeBase64(fileData.encryptedFileData);
      final ivBytes = _decodeBase64(fileData.ivVector);
      final authTagBytes = _decodeBase64(fileData.authTag);

      final decryptedBytes = await encryptionService.decryptFileAES256(
        encryptedFileBytes,
        ivBytes,
        authTagBytes,
        aesKey,
      );

      if (decryptedBytes == null) throw Exception('Decryption failed: integrity check mismatch');

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // 5. Show printer selection
      _showPrinterSelection(file, decryptedBytes);

    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Decryption Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Helper to decode Base64 with URL-safe and padding handling
  Uint8List _decodeBase64(String input) {
    String cleaned = input.replaceAll('-', '+').replaceAll('_', '/');
    cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9+/=]'), '');
    final padLength = (4 - (cleaned.length % 4)) % 4;
    cleaned += '=' * padLength;
    return base64Decode(cleaned);
  }

  Future<void> _showPrinterSelection(FileItem file, Uint8List pdfBytes) async {
      final printers = await Printing.listPrinters();
      final physicalPrinters = printers.where((p) {
        final name = p.name.toLowerCase();
        return !name.contains('pdf') &&
               !name.contains('xps') &&
               !name.contains('onenote') &&
               !name.contains('writer') &&
               !name.contains('fax');
      }).toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Printer'),
          content: SizedBox(
            width: double.maxFinite,
            child: physicalPrinters.isEmpty
                ? const Text('No physical printers found.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: physicalPrinters.length,
                    itemBuilder: (context, index) {
                      final printer = physicalPrinters[index];
                      return ListTile(
                        leading: const Icon(Icons.print),
                        title: Text(printer.name),
                        onTap: () {
                          Navigator.of(context).pop();
                          _executePrint(file, printer, pdfBytes);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
  }

  Future<void> _executePrint(FileItem file, Printer printer, Uint8List pdfBytes) async {
    final authService = context.read<AuthService>();
    final apiService = context.read<ApiService>();
    final historyService = context.read<FileHistoryService>();

    try {
      // Update Status: BEING_PRINTED
      await apiService.updateFileStatus(file.fileId, 'BEING_PRINTED', authService.accessToken!);
      
      // Print
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (_) async => pdfBytes,
      );

      // Update Status: COMPLETED
      await apiService.updateFileStatus(file.fileId, 'PRINT_COMPLETED', authService.accessToken!);

      // Save to Local History BEFORE deleting
      await historyService.addToHistory(HistoryItem(
        fileId: file.fileId,
        fileName: file.fileName,
        fileSizeBytes: file.fileSizeBytes,
        uploadedAt: file.uploadedAt,
        deletedAt: DateTime.now().toUtc().toIso8601String(),
        status: 'PRINT_COMPLETED',
        statusUpdatedAt: DateTime.now().toUtc().toIso8601String(),
        isPrinted: true,
      ));

      // Delete (Hard Delete on Server)
      await apiService.deleteFile(file.fileId, authService.accessToken!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Printed and deleted ${file.fileName}'), backgroundColor: Colors.green),
        );
        _loadFiles(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
      final historyService = context.read<FileHistoryService>();
      
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
      
      // Save to Local History BEFORE deleting
      await historyService.addToHistory(HistoryItem(
        fileId: file.fileId,
        fileName: file.fileName,
        fileSizeBytes: file.fileSizeBytes,
        uploadedAt: file.uploadedAt,
        deletedAt: DateTime.now().toUtc().toIso8601String(),
        status: 'REJECTED',
        statusUpdatedAt: DateTime.now().toUtc().toIso8601String(),
        rejectionReason: 'Rejected by owner from dashboard',
        isPrinted: false,
      ));

      // Always delete the file (Hard Delete)
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

      final fileDate = file.uploadedAtDateTime;
      final dateOnly = DateTime(fileDate.year, fileDate.month, fileDate.day);
      
      if (dateOnly.isAtSameMomentAs(today)) {
        todayFiles.add(file);
      } else if (dateOnly.isAtSameMomentAs(yesterday)) {
        yesterdayFiles.add(file);
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
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeService.isDarkMode 
              ? [colors.backgroundGradientStart, colors.backgroundGradientEnd]
              : [colors.backgroundGradientStart, const Color(0xFFE6E6FA), colors.backgroundGradientEnd], // Tri-color: Pink -> Lavender -> Blue
            stops: themeService.isDarkMode ? null : [0.0, 0.5, 1.0], // Even distribution for light mode
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
                                  onAccept: () => _handlePrintFlow(file),
                                  onReject: () => _deleteFile(file),
                                )),
                          ],
                          if (yesterdayFiles.isNotEmpty) ...[
                            _buildSectionHeader('Yesterday', colors),
                            ...yesterdayFiles.map((file) => FileCard(
                                  file: file,
                                  onAccept: () => _handlePrintFlow(file),
                                  onReject: () => _deleteFile(file),
                                )),
                          ],
                          if (olderFiles.isNotEmpty) ...[
                            _buildSectionHeader('Older Files', colors),
                            ...olderFiles.map((file) => FileCard(
                                  file: file,
                                  onAccept: () => _handlePrintFlow(file),
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
