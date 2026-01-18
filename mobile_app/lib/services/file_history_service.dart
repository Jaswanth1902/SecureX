// ========================================
// FILE HISTORY SERVICE - LOCAL STORAGE
// Tracks uploaded files locally to detect rejections
// ========================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FileHistoryService {
  static const _historyKey = 'file_upload_history';
  static const _dismissedFilesKey = 'dismissed_files';
  
  // ========================================
  // SAVE FILE TO LOCAL HISTORY
  // ========================================
  
  /// Save a file to local history after successful upload
  Future<void> saveFileToHistory({
    required String fileId,
    required String fileName,
    required int fileSizeBytes,
    required String uploadedAt,
    String status = 'WAITING_FOR_APPROVAL',
    String? localPath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getLocalHistory();
      
      // Check if file already exists in history
      final existingIndex = history.indexWhere((f) => f['file_id'] == fileId);
      
      final fileEntry = {
        'file_id': fileId,
        'file_name': fileName,
        'file_size_bytes': fileSizeBytes,
        'uploaded_at': uploadedAt,
        'status': status,
        'status_updated_at': DateTime.now().toIso8601String(),
        'is_local_only': false,
        if (localPath != null) 'local_path': localPath,
      };
      
      if (existingIndex >= 0) {
        // Update existing entry
        history[existingIndex] = fileEntry;
      } else {
        // Add new entry
        history.add(fileEntry);
      }
      
      await prefs.setString(_historyKey, jsonEncode(history));
    } catch (e) {
      // Silently fail - local history is not critical
      print('Failed to save file to history: $e');
    }
  }
  
  // ========================================
  // GET LOCAL HISTORY
  // ========================================
  
  /// Get all files from local history
  Future<List<Map<String, dynamic>>> getLocalHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> decoded = jsonDecode(historyJson);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('Failed to get local history: $e');
      return [];
    }
  }
  
  // ========================================
  // UPDATE FILE STATUS
  // ========================================
  
  /// Update the status of a file in local history
  Future<void> updateFileStatus(String fileId, String newStatus, {String? rejectionReason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getLocalHistory();
      
      final index = history.indexWhere((f) => f['file_id'] == fileId);
      if (index >= 0) {
        history[index]['status'] = newStatus;
        history[index]['status_updated_at'] = DateTime.now().toIso8601String();
        if (rejectionReason != null) {
          history[index]['rejection_reason'] = rejectionReason;
        }
        
        await prefs.setString(_historyKey, jsonEncode(history));
      }
    } catch (e) {
      print('Failed to update file status: $e');
    }
  }
  
  // ========================================
  // MERGE SERVER FILES WITH LOCAL HISTORY
  // ========================================
  
  /// Merge server files with local history
  /// - Server REJECTED files sync their rejection_reason to local history
  /// - Files in local history but missing from server are marked as REJECTED
  Future<List<Map<String, dynamic>>> mergeWithServerFiles(
    List<Map<String, dynamic>> serverFiles,
  ) async {
    final localHistory = await getLocalHistory();
    
    // Create maps for quick lookup
    final serverFileMap = <String, Map<String, dynamic>>{};
    for (final f in serverFiles) {
      serverFileMap[f['file_id']] = f;
    }
    
    // Update local history based on server response
    for (final localFile in localHistory) {
      final fileId = localFile['file_id'];
      final serverFile = serverFileMap[fileId];
      
      if (serverFile != null) {
        // File exists on server - sync status from server
        // Update local status to match server status (for all status changes)
        final serverStatus = serverFile['status'];
        if (serverStatus != null && serverStatus != localFile['status']) {
          if (serverStatus == 'REJECTED') {
            // Use server's rejection reason if available
            final serverReason = serverFile['rejection_reason'] ?? 'File was rejected';
            await updateFileStatus(fileId, 'REJECTED', rejectionReason: serverReason);
          } else {
            // Update to any other status from server
            await updateFileStatus(fileId, serverStatus);
          }
        }
      }
      // Note: If file is missing from server, we keep the local status unchanged
      // This allows files to stay in WAITING_FOR_APPROVAL until the server explicitly updates them
    }
    
    // Get updated local history
    final updatedHistory = await getLocalHistory();
    
    // Create result list: start with server files (includes REJECTED files now)
    final result = List<Map<String, dynamic>>.from(serverFiles);
    
    // Add locally-tracked REJECTED files that aren't in server response
    // (files that were removed from server completely, not just marked REJECTED)
    for (final localFile in updatedHistory) {
      final fileId = localFile['file_id'];
      if (!serverFileMap.containsKey(fileId) && localFile['status'] == 'REJECTED') {
        result.add({
          ...localFile,
          'is_local_only': true,
        });
      }
    }
    
    return result;
  }

  
  // ========================================
  // REMOVE FILE FROM HISTORY
  // ========================================
  
  /// Remove a file from local history (e.g., user dismisses rejected notification)
  Future<void> removeFromHistory(String fileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getLocalHistory();
      
      history.removeWhere((f) => f['file_id'] == fileId);
      
      await prefs.setString(_historyKey, jsonEncode(history));
    } catch (e) {
      print('Failed to remove file from history: $e');
    }
  }
  
  // ========================================
  // CLEAR OLD HISTORY
  // ========================================
  
  /// Clear history entries older than specified days
  Future<void> clearOldHistory({int daysToKeep = 30}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getLocalHistory();
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      history.removeWhere((file) {
        try {
          final uploadedAt = DateTime.parse(file['uploaded_at'] ?? '');
          return uploadedAt.isBefore(cutoffDate);
        } catch (e) {
          return false;
        }
      });
      
      await prefs.setString(_historyKey, jsonEncode(history));
    } catch (e) {
      print('Failed to clear old history: $e');
    }
  }
  
  // ========================================
  // TRACK DISMISSED FILES
  // ========================================
  
  /// Mark a file as dismissed (so it doesn't reappear)
  Future<void> markAsDismissed(String fileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissedList = await getDismissedFileIds();
      
      if (!dismissedList.contains(fileId)) {
        dismissedList.add(fileId);
        await prefs.setStringList(_dismissedFilesKey, dismissedList);
      }
    } catch (e) {
      print('Failed to mark file as dismissed: $e');
    }
  }
  
  /// Get list of dismissed file IDs
  Future<List<String>> getDismissedFileIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_dismissedFilesKey) ?? [];
    } catch (e) {
      print('Failed to get dismissed files: $e');
      return [];
    }
  }
  
  /// Filter out dismissed files from a list
  Future<List<Map<String, dynamic>>> filterDismissedFiles(List<Map<String, dynamic>> files) async {
    final dismissedIds = await getDismissedFileIds();
    return files.where((file) => !dismissedIds.contains(file['file_id'])).toList();
  }
}
