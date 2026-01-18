import 'package:flutter/material.dart';
import 'dart:io';
import '../services/local_file_service.dart';
import '../services/permissions_service.dart';
import '../services/file_history_service.dart';
import 'recent_file_card.dart';
import 'glass_container.dart';

class RecentFilesList extends StatefulWidget {
  final Function(LocalFile) onFileSelected;

  const RecentFilesList({
    super.key,
    required this.onFileSelected,
  });

  @override
  State<RecentFilesList> createState() => _RecentFilesListState();
}

class _RecentFilesListState extends State<RecentFilesList> {
  final LocalFileService _fileService = LocalFileService();
  final FileHistoryService _historyService = FileHistoryService();
  List<LocalFile> _files = [];
  bool _isLoading = true;
  bool _hasPermission = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Fetch History Files (Always reliable, no special permission needed)
    final historyData = await _historyService.getLocalHistory();
    final List<LocalFile> historyFiles = historyData.map((data) {
      final String localPath = data['local_path'] ?? '';
      return LocalFile(
        file: localPath.isNotEmpty ? File(localPath) : File(''),
        path: localPath, 
        name: data['file_name'] ?? 'Unknown',
        lastModified: DateTime.tryParse(data['uploaded_at'] ?? '') ?? DateTime.now(),
        sizeInBytes: data['file_size_bytes'] ?? 0,
      );
    }).toList();

    // 2. Fetch Local Files (If permission granted)
    final hasPerm = await PermissionsService.hasFilePermission();
    List<LocalFile> localFiles = [];
    if (hasPerm) {
      localFiles = await _fileService.fetchRecentFiles();
    }

    // 3. Merge and De-duplicate (using name and size as a weak key)
    final Map<String, LocalFile> mergedMap = {};
    
    // History files first (older timestamp usually)
    for (var f in historyFiles) {
      mergedMap['${f.name}_${f.sizeInBytes}'] = f;
    }
    
    // Local files overwrite history if they match (more accurate path)
    for (var f in localFiles) {
      mergedMap['${f.name}_${f.sizeInBytes}'] = f;
    }

    final mergedList = mergedMap.values.toList();
    
    // Sort by date (newest first)
    mergedList.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    
    if (mounted) {
      setState(() {
        _files = mergedList;
        _hasPermission = hasPerm;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: Colors.white70),
        ),
      );
    }

    if (!_hasPermission) {
      return _buildPermissionRequest();
    }

    if (_files.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        return RecentFileCard(
          file: _files[index],
          onTap: () => widget.onFileSelected(_files[index]),
        );
      },
    );
  }

  Widget _buildPermissionRequest() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 48, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Storage Access Required',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'We need permission to scan for recently\nedited documents on your device.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final granted = await PermissionsService.requestAllFilePermissions();
              if (granted) _loadFiles();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Grant Access'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassContainer(
      padding: const EdgeInsets.all(32),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 48, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No recent documents',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'PDF and Word documents you edit\nwill appear here for quick printing.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _loadFiles,
            child: const Text('Refresh', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
