// ========================================
// MOBILE APP - FILE LIST SCREEN (JOBS)
// Displays user's uploaded files with grouped history
// ========================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';
import '../services/file_history_service.dart';
import '../widgets/glass_container.dart';
import 'print_screen.dart';
import '../utils/constants.dart';

class FileListScreen extends StatefulWidget {
  const FileListScreen({super.key});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  final apiService = ApiService();
  final userService = UserService();
  final fileHistoryService = FileHistoryService();

  List<Map<String, dynamic>> files = [];
  List<Map<String, dynamic>> filteredFiles = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedFilter = 'ALL'; // Filter: ALL, WAITING, APPROVED, REJECTED, PRINTED

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Use stored token
      String? accessToken = await userService.getAccessToken();
      
      if (accessToken == null) {
        throw Exception('Not authenticated. Please log in first.');
      }
      
      // Get user's files from API
      final response = await http
          .get(
            Uri.parse('${apiService.baseUrl}/api/files'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        List<Map<String, dynamic>> validatedFiles = [];
        try {
          if (data['files'] is List) {
            validatedFiles = (data['files'] as List)
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          }
        } catch (e) {
          debugPrint('⚠️ Error validating files list: $e');
          validatedFiles = [];
        }
        
        // Merge with local history to detect rejected files
        final mergedFiles = await fileHistoryService.mergeWithServerFiles(validatedFiles);
        
        // Filter out dismissed files
        final activeFiles = await fileHistoryService.filterDismissedFiles(mergedFiles);
        
        if (mounted) {
          setState(() {
            files = activeFiles;
            _applyFilter();
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load files: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
      debugPrint('❌ Error loading files: $e');
    }
  }

  void _applyFilter() {
    setState(() {
      if (selectedFilter == 'ALL') {
        filteredFiles = List.from(files);
      } else {
        filteredFiles = files.where((file) {
          final status = file['status'] ?? '';
          switch (selectedFilter) {
            case 'WAITING':
              return status == 'WAITING_FOR_APPROVAL';
            case 'PRINTED':
              return status == 'PRINT_COMPLETED' || status == 'BEING_PRINTED'; // Simplify 'Printed' tab
            case 'REJECTED':
              return status == 'REJECTED';
            default:
              return true;
          }
        }).toList();
      }
      
      // Sort by upload time descending
      filteredFiles.sort((a, b) {
        final dateA = DateTime.tryParse(a['uploaded_at'] ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['uploaded_at'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });
    });
  }

  void _changeFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      _applyFilter();
    });
  }

  // Group files by date (Today, Yesterday, Older)
  Map<String, List<Map<String, dynamic>>> _groupFilesByDate(List<Map<String, dynamic>> filesToGroup) {
    final grouped = <String, List<Map<String, dynamic>>>{
      'Today': [],
      'Yesterday': [],
      'Older': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var file in filesToGroup) {
      final uploadedAtStr = file['uploaded_at'];
      if (uploadedAtStr != null) {
        final date = DateTime.tryParse(uploadedAtStr)?.toLocal(); // Convert to local time
        if (date != null) {
          final fileDate = DateTime(date.year, date.month, date.day);
          if (fileDate == today) {
            grouped['Today']!.add(file);
          } else if (fileDate == yesterday) {
            grouped['Yesterday']!.add(file);
          } else {
            grouped['Older']!.add(file);
          }
        } else {
          grouped['Older']!.add(file);
        }
      } else {
        grouped['Older']!.add(file);
      }
    }
    
    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);
    
    return grouped;
  }

  void _deleteFile(String fileId) async {
    // Show confirmation dialog before deleting/cancelling
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel this print request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final accessToken = await userService.getAccessToken();
      if (accessToken == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${apiService.baseUrl}/api/delete/$fileId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request cancelled')));
        _loadFiles();
      } else {
        throw Exception('Cancel failed');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _dismissRejectedFile(String fileId) async {
    try {
      await fileHistoryService.markAsDismissed(fileId);
      await fileHistoryService.removeFromHistory(fileId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File dismissed')));
      _loadFiles();
    } catch (e) {
      // ignore
    }
  }
  
  // -- UI Helpers --

  Color _getStatusColor(String status) {
    if (status == 'WAITING_FOR_APPROVAL') return Colors.orange.shade300;
    if (status == 'APPROVED') return Colors.blue.shade300;
    if (status == 'PRINT_COMPLETED') return Colors.green.shade300;
    if (status == 'REJECTED') return Colors.red.shade300;
    return Colors.grey.shade300;
  }
  
  Color _getStatusBgColor(String status) {
    if (status == 'WAITING_FOR_APPROVAL') return Colors.orange.withOpacity(0.2);
    if (status == 'APPROVED') return Colors.blue.withOpacity(0.2);
    if (status == 'PRINT_COMPLETED') return Colors.green.withOpacity(0.2);
    if (status == 'REJECTED') return Colors.red.withOpacity(0.2);
    return Colors.grey.withOpacity(0.2);
  }

  String _getStatusText(String status) {
    if (status == 'WAITING_FOR_APPROVAL') return 'Waiting';
    if (status == 'APPROVED') return 'Approved';
    if (status == 'BEING_PRINTED') return 'Printing';
    if (status == 'PRINT_COMPLETED') return 'Printed';
    if (status == 'REJECTED') return 'Rejected';
    return status.replaceAll('_', ' ');
  }

  // Get file icon based on extension (simple heuristic)
  Widget _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    IconData icon;
    Color color;

    if (['pdf'].contains(ext)) {
      icon = Icons.picture_as_pdf;
      color = Colors.orange.shade400; // Reference uses orange for PDF
    } else if (['doc', 'docx'].contains(ext)) {
      icon = Icons.description;
      color = Colors.blue.shade400;
    } else if (['jpg', 'jpeg', 'png'].contains(ext)) {
      icon = Icons.image;
      color = Colors.red.shade400;
    } else if (['xls', 'xlsx'].contains(ext)) {
      icon = Icons.table_chart;
      color = Colors.green.shade400;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey.shade400;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, color: color.withOpacity(0.8), size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group files
    final groupedFiles = _groupFilesByDate(filteredFiles);
    
    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Navigator.canPop(context) 
              ? IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null,
          centerTitle: true,
          title: const Text(
            'File History',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 28),
              onPressed: () {
                // Search functionality to be implemented
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search coming soon')));
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Filter Chips
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All'),
                    const SizedBox(width: 12),
                    _buildFilterChip('WAITING', 'Waiting for approval'),
                    const SizedBox(width: 12),
                    _buildFilterChip('PRINTED', 'Printed'),
                    const SizedBox(width: 12),
                    _buildFilterChip('REJECTED', 'Rejected'),
                  ],
                ),
              ),
            ),
            
            // File List content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white, size: 48),
                              const SizedBox(height: 16),
                              Text(errorMessage!, style: const TextStyle(color: Colors.white)),
                              TextButton(
                                onPressed: _loadFiles,
                                child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        )
                      : groupedFiles.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.folder_open, size: 64, color: Colors.white.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No files found',
                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 18),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadFiles,
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: groupedFiles.entries.map((entry) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8, bottom: 12, top: 4),
                                        child: Text(
                                          entry.key, // Today / Yesterday / Older
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                                          ),
                                        ),
                                      ),
                                      ...entry.value.map((file) => _buildFileItem(file)),
                                      const SizedBox(height: 16),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
            ),
          ],
        ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => _changeFilter(filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isSelected ? [
             BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file) {
    final status = file['status'] ?? '';
    final fileName = file['file_name'] ?? 'Unknown';
    final sizeBytes = file['file_size_bytes'] ?? 0;
    final uploadedAtStr = file['uploaded_at'];
    
    // Format Time
    String timeStr = '';
    if (uploadedAtStr != null) {
      final date = DateTime.tryParse(uploadedAtStr)?.toLocal();
      if (date != null) {
        timeStr = DateFormat('hh:mm a').format(date);
      }
    }

    // Format Size
    String sizeStr = '';
    if (sizeBytes < 1024 * 1024) {
      sizeStr = '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    } else {
      sizeStr = '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return Dismissible(
      key: Key(file['file_id'].toString()),
      direction: status == 'REJECTED' ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withOpacity(0.5),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _dismissRejectedFile(file['file_id']),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Action on tap? maybe show details or print screen if approved
        },
        child: Row(
          children: [
            _getFileIcon(fileName),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        sizeStr,
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: CircleAvatar(radius: 2, backgroundColor: Colors.white.withOpacity(0.4)),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status Badge
            if (status == 'WAITING_FOR_APPROVAL') // Allow Cancel
              GestureDetector(
                onTap: () => _deleteFile(file['file_id']),
                 child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(status),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
                    ),
                    child: Text(
                      'Waiting',
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                 ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusBgColor(status),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
                ),
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

