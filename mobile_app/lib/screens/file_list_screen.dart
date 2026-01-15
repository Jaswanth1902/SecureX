// ========================================
// MOBILE APP - FILE LIST SCREEN
// Displays user's uploaded files
// ========================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/file_history_service.dart';
import 'print_screen.dart';

// ========================================
// FILE LIST SCREEN
// ========================================

class FileListScreen extends StatefulWidget {
  const FileListScreen({super.key});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  final apiService = ApiService();
  final fileHistoryService = FileHistoryService();

  List<Map<String, dynamic>> files = [];
  List<Map<String, dynamic>> filteredFiles = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedFilter =
      'ALL'; // Filter: ALL, WAITING, APPROVED, REJECTED, COMPLETED

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

      // Get user's files from API using service
      final validatedFiles = await apiService.listFiles();

      // Merge with local history to detect rejected files
      final mergedFiles = await fileHistoryService.mergeWithServerFiles(
        validatedFiles
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
            .toList(),
      );
      debugPrint(
          '📝 Merged ${validatedFiles.length} server files with local history, total: ${mergedFiles.length}');

      // Filter out dismissed files (files user explicitly removed from history)
      final filteredFilesList =
          await fileHistoryService.filterDismissedFiles(mergedFiles);
      debugPrint(
          '🗑️ Filtered out ${mergedFiles.length - filteredFilesList.length} dismissed files');

      setState(() {
        files = filteredFilesList;
        _applyFilter(); // Apply selected filter
        isLoading = false;
      });
    } on AuthException catch (e) {
      setState(() {
        errorMessage =
            'Authentication failed: ${e.message}. Please login again.';
        isLoading = false;
      });
      debugPrint('❌ Auth error loading files: $e');
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      debugPrint('❌ Error loading files: $e');
    }
  }

  void _applyFilter() {
    if (selectedFilter == 'ALL') {
      filteredFiles = files;
    } else {
      filteredFiles = files.where((file) {
        final status = file['status'] ?? '';
        switch (selectedFilter) {
          case 'WAITING':
            return status == 'WAITING_FOR_APPROVAL';
          case 'APPROVED':
            return status == 'APPROVED';
          case 'REJECTED':
            return status == 'REJECTED';
          case 'COMPLETED':
            return status == 'PRINT_COMPLETED';
          default:
            return true;
        }
      }).toList();
    }
  }

  void _changeFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      _applyFilter();
    });
  }

  void _openFile(String fileId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrintScreen(fileId: fileId)),
    );
  }

  /// Safely format file ID for display: truncate to 8 chars with ellipsis or show placeholder
  String _formatFileId(dynamic fileId) {
    if (fileId == null || fileId.toString().isEmpty) {
      return 'No ID';
    }
    final idStr = fileId.toString();
    if (idStr.length <= 8) {
      return idStr;
    }
    return '${idStr.substring(0, 8)}...';
  }

  void _deleteFile(String fileId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await apiService.deleteFile(fileId: fileId);

                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('File deleted')));
                _loadFiles();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _dismissRejectedFile(String fileId) async {
    try {
      // Rejected files are already deleted from server
      // Mark as dismissed so it doesn't reappear, and remove from local history
      await fileHistoryService.markAsDismissed(fileId);
      await fileHistoryService.removeFromHistory(fileId);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          const SnackBar(content: Text('File dismissed from history')));
      _loadFiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Files'),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $errorMessage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFiles,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
          : files.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No files yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to upload
                      Navigator.pushNamed(context, '/upload');
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload a File'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Filter chips
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', 'All', Icons.list),
                        const SizedBox(width: 8),
                        _buildFilterChip('WAITING', 'Waiting', Icons.hourglass_empty),
                        const SizedBox(width: 8),
                        _buildFilterChip('APPROVED', 'Approved', Icons.thumb_up),
                        const SizedBox(width: 8),
                        _buildFilterChip('REJECTED', 'Rejected', Icons.cancel),
                        const SizedBox(width: 8),
                        _buildFilterChip('COMPLETED', 'Completed', Icons.check_circle),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                // File list
                Expanded(
                  child: filteredFiles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_list_off,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No ${selectedFilter.toLowerCase()} files',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadFiles,
                          child: ListView.builder(
                            itemCount: filteredFiles.length,
                            padding: const EdgeInsets.all(12),
                            itemBuilder: (context, index) {
                              final file = filteredFiles[index];
                              final status = file['status'] ?? 'UNKNOWN';
                              final rejectionReason = file['rejection_reason'];
                              
                              // Status color and icon mapping
                              Color statusColor;
                              IconData statusIcon;
                              switch (status) {
                                case 'WAITING_FOR_APPROVAL':
                                  statusColor = Colors.orange;
                                  statusIcon = Icons.hourglass_empty;
                                  break;
                                case 'APPROVED':
                                  statusColor = Colors.blue;
                                  statusIcon = Icons.thumb_up;
                                  break;
                                case 'BEING_PRINTED':
                                  statusColor = Colors.purple;
                                  statusIcon = Icons.print;
                                  break;
                                case 'PRINT_COMPLETED':
                                  statusColor = Colors.green;
                                  statusIcon = Icons.check_circle;
                                  break;
                                case 'REJECTED':
                                  statusColor = Colors.red;
                                  statusIcon = Icons.cancel;
                                  break;
                                case 'CANCELLED':
                                  statusColor = Colors.grey;
                                  statusIcon = Icons.cancel_outlined;
                                  break;
                                default:
                                  statusColor = Colors.grey;
                                  statusIcon = Icons.help_outline;
                              }
                              
                              String statusText = status.toString().replaceAll('_', ' ');
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: InkWell(
                                  onTap: () => _openFile(file['file_id'] ?? ''),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // File name and icon row
                                        Row(
                                          children: [
                                            Icon(statusIcon, color: statusColor, size: 28),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                file['file_name'] ?? 'Unknown',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // Cancel button for pending files
                                            if (status == 'WAITING_FOR_APPROVAL' || status == 'APPROVED')
                                              IconButton(
                                                icon: const Icon(Icons.close, color: Colors.red),
                                                tooltip: 'Cancel Request',
                                                onPressed: () => _deleteFile(file['file_id'] ?? ''),
                                              ),
                                            // Dismiss button for ALL rejected files - deletes from server
                                            if (status == 'REJECTED')
                                              IconButton(
                                                icon: const Icon(Icons.visibility_off, color: Colors.grey),
                                                tooltip: 'Dismiss',
                                                onPressed: () => _dismissRejectedFile(file['file_id'] ?? ''),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Status text
                                        Text(
                                          statusText,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        // Show rejection reason if rejected
                                        if (status == 'REJECTED' && rejectionReason != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.red.shade200),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.info_outline, color: Colors.red, size: 20),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      rejectionReason,
                                                      style: const TextStyle(color: Colors.red),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        // Upload time
                                        const SizedBox(height: 8),
                                        Text(
                                          'Uploaded: ${_formatDate(file['uploaded_at'])}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String filterValue, String label, IconData icon) {
    final isSelected = selectedFilter == filterValue;

    // Count files for this filter
    int count;
    if (filterValue == 'ALL') {
      count = files.length;
    } else {
      count = files.where((file) {
        final status = file['status'] ?? '';
        switch (filterValue) {
          case 'WAITING':
            return status == 'WAITING_FOR_APPROVAL';
          case 'APPROVED':
            return status == 'APPROVED';
          case 'REJECTED':
            return status == 'REJECTED';
          case 'COMPLETED':
            return status == 'PRINT_COMPLETED';
          default:
            return false;
        }
      }).length;
    }

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          _changeFilter(filterValue);
        }
      },
      selectedColor: Colors.blue,
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
