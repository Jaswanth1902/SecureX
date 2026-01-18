import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../services/permissions_service.dart';

class LocalFile {
  final File file;
  final String path;
  final String name;
  final DateTime lastModified;
  final int sizeInBytes;

  LocalFile({
    required this.file,
    required this.path,
    required this.name,
    required this.lastModified,
    required this.sizeInBytes,
  });

  String get sizeFormatted {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get extension => name.split('.').last.toLowerCase();
}

class LocalFileService {
  static const List<String> _allowedExtensions = ['pdf', 'doc', 'docx'];

  /// Scans common directories for recently modified documents
  Future<List<LocalFile>> fetchRecentFiles({int limit = 10}) async {
    try {
      // 1. Check permissions
      final hasPermission = await PermissionsService.hasFilePermission();
      if (!hasPermission) {
        debugPrint('⚠️ No file permissions granted for scanning');
        return [];
      }

      List<LocalFile> foundFiles = [];
      List<Directory> directoriesToScan = [];

      if (Platform.isAndroid) {
        // More robust Android path discovery
        // 1. Try standard /storage/emulated/0/Download
        final List<String> commonPaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Documents',
          '/sdcard/Download',
          '/sdcard/Documents',
        ];

        for (final path in commonPaths) {
          final dir = Directory(path);
          if (await dir.exists()) {
            directoriesToScan.add(dir);
            debugPrint('📁 Found directory to scan: $path');
          }
        }
        
        // 2. Try getting external storage directory from system
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            directoriesToScan.add(externalDir);
            debugPrint('📁 Found external storage dir: ${externalDir.path}');
            
            // Also try to find the actual "Download" sibling of the app's external dir
            // Usually: /storage/emulated/0/Android/data/com.example.app/files -> /storage/emulated/0/Download
            final pathParts = externalDir.path.split('/');
            if (pathParts.contains('Android')) {
              final androidIndex = pathParts.indexOf('Android');
              final rootPath = pathParts.sublist(0, androidIndex).join('/');
              final downloadPath = '$rootPath/Download';
              final downloadDir = Directory(downloadPath);
              if (await downloadDir.exists() && !commonPaths.contains(downloadPath)) {
                directoriesToScan.add(downloadDir);
                debugPrint('📁 Found inferred Download dir: $downloadPath');
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error getting external storage dir: $e');
        }
      } else if (Platform.isIOS) {
        final docsDir = await getApplicationDocumentsDirectory();
        directoriesToScan.add(docsDir);
      }

      if (directoriesToScan.isEmpty) {
        // Fallback to app-specific directories if external ones aren't accessible
        final appDocsDir = await getApplicationDocumentsDirectory();
        directoriesToScan.add(appDocsDir);
      }

      for (var dir in directoriesToScan) {
        try {
          final List<FileSystemEntity> entities = await dir.list(recursive: false).toList();
          
          for (var entity in entities) {
            if (entity is File) {
              final fileName = entity.path.split(Platform.pathSeparator).last;
              final extension = fileName.split('.').last.toLowerCase();

              if (_allowedExtensions.contains(extension)) {
                final stat = await entity.stat();
                foundFiles.add(LocalFile(
                  file: entity,
                  path: entity.path,
                  name: fileName,
                  lastModified: stat.modified,
                  sizeInBytes: stat.size,
                ));
              }
            }
          }
        } catch (e) {
          debugPrint('❌ Error listing directory ${dir.path}: $e');
        }
      }

      // Sort by modified date (newest first)
      foundFiles.sort((a, b) => b.lastModified.compareTo(a.lastModified));

      // Limit results
      if (foundFiles.length > limit) {
        return foundFiles.sublist(0, limit);
      }

      return foundFiles;
    } catch (e) {
      debugPrint('❌ Error in fetchRecentFiles: $e');
      return [];
    }
  }
}
