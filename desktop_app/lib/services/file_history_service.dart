import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/history_item.dart';

class FileHistoryService extends ChangeNotifier {
  static const String _fileName = 'history.json';
  List<HistoryItem> _items = [];

  List<HistoryItem> get items => _items;

  FileHistoryService() {
    _loadHistory();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  Future<void> _loadHistory() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        _items = [];
        notifyListeners();
        return;
      }

      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      
      _items = jsonList.map((json) => HistoryItem(
        fileId: json['file_id'],
        fileName: json['file_name'],
        fileSizeBytes: json['file_size_bytes'],
        uploadedAt: json['uploaded_at'],
        deletedAt: json['deleted_at'],
        status: json['status'],
        statusUpdatedAt: json['status_updated_at'],
        rejectionReason: json['rejection_reason'],
        isPrinted: json['is_printed'] ?? false,
      )).toList();
      
      // Sort by statusUpdatedAt descending
      _items.sort((a, b) => b.statusUpdatedAt.compareTo(a.statusUpdatedAt));
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final file = await _localFile;
      final jsonList = _items.map((item) => {
        'file_id': item.fileId,
        'file_name': item.fileName,
        'file_size_bytes': item.fileSizeBytes,
        'uploaded_at': item.uploadedAt,
        'deleted_at': item.deletedAt,
        'status': item.status,
        'status_updated_at': item.statusUpdatedAt,
        'rejection_reason': item.rejectionReason,
        'is_printed': item.isPrinted,
      }).toList();
      
      await file.writeAsString(jsonEncode(jsonList));
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  Future<List<HistoryItem>> getHistory() async {
    await _loadHistory(); // Ensure fresh
    return _items;
  }

  Future<void> addToHistory(HistoryItem item) async {
    // Check if exists
    final index = _items.indexWhere((i) => i.fileId == item.fileId);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.insert(0, item);
    }
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _items = [];
    final file = await _localFile;
    if (await file.exists()) {
      await file.delete();
    }
    notifyListeners();
  }
}
