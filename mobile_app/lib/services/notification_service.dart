// ========================================
// NOTIFICATION SERVICE
// Manages in-app notifications for file status updates
// ========================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single notification
class AppNotification {
  final String id;
  final String fileId;
  final String fileName;
  final String type; // 'REJECTED' or 'PRINT_COMPLETED'
  final String message;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.fileId,
    required this.fileName,
    required this.type,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileId': fileId,
    'fileName': fileName,
    'type': type,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] ?? '',
    fileId: json['fileId'] ?? '',
    fileName: json['fileName'] ?? '',
    type: json['type'] ?? '',
    message: json['message'] ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    isRead: json['isRead'] ?? false,
  );
}

/// Service to manage notifications
class NotificationService extends ChangeNotifier {
  static const _storageKey = 'app_notifications';
  static const _lastCheckKey = 'last_status_check';
  static const int _maxNotifications = 50;
  
  List<AppNotification> _notifications = [];
  final bool _isLoading = false;
  
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;
  
  /// Initialize and load notifications from storage
  Future<void> initialize() async {
    await _loadNotifications();
  }
  
  /// Load notifications from SharedPreferences
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _notifications = decoded
            .map((item) => AppNotification.fromJson(item))
            .toList();
        // Sort by timestamp descending (newest first)
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      _notifications = [];
    }
    notifyListeners();
  }
  
  /// Save notifications to SharedPreferences
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }
  
  /// Add a new notification
  Future<void> addNotification({
    required String fileId,
    required String fileName,
    required String type,
    required String message,
  }) async {
    // Check if notification for this file+type already exists
    final existingIndex = _notifications.indexWhere(
      (n) => n.fileId == fileId && n.type == type,
    );
    
    if (existingIndex >= 0) {
      // Update existing notification
      _notifications[existingIndex] = AppNotification(
        id: _notifications[existingIndex].id,
        fileId: fileId,
        fileName: fileName,
        type: type,
        message: message,
        timestamp: DateTime.now(),
        isRead: false,
      );
    } else {
      // Add new notification
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileId: fileId,
        fileName: fileName,
        type: type,
        message: message,
        timestamp: DateTime.now(),
      );
      
      _notifications.insert(0, notification);
      
      // Limit stored notifications
      if (_notifications.length > _maxNotifications) {
        _notifications = _notifications.sublist(0, _maxNotifications);
      }
    }
    
    await _saveNotifications();
    notifyListeners();
  }
  
  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      _notifications[index].isRead = true;
      await _saveNotifications();
      notifyListeners();
    }
  }
  
  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    await _saveNotifications();
    notifyListeners();
  }
  
  /// Clear a notification
  Future<void> clearNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    notifyListeners();
  }
  
  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }
  
  /// Check for status updates from stored files and generate notifications
  /// This compares previous status with current status to detect changes
  Future<void> checkForStatusUpdates(List<Map<String, dynamic>> currentFiles) async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckJson = prefs.getString(_lastCheckKey);
    
    Map<String, String> previousStatuses = {};
    if (lastCheckJson != null) {
      try {
        final decoded = jsonDecode(lastCheckJson) as Map<String, dynamic>;
        previousStatuses = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (e) {
        debugPrint('Error parsing last check: $e');
      }
    }
    
    // Check each file for status changes
    for (final file in currentFiles) {
      final fileId = file['file_id']?.toString() ?? '';
      final fileName = file['file_name']?.toString() ?? 'Unknown file';
      final currentStatus = file['status']?.toString() ?? '';
      final rejectionReason = file['rejection_reason']?.toString();
      
      if (fileId.isEmpty) continue;
      
      final previousStatus = previousStatuses[fileId];
      
      // Generate notification if status changed to REJECTED or PRINT_COMPLETED
      if (previousStatus != null && previousStatus != currentStatus) {
        if (currentStatus == 'REJECTED') {
          await addNotification(
            fileId: fileId,
            fileName: fileName,
            type: 'REJECTED',
            message: rejectionReason ?? 'Your file was rejected',
          );
        } else if (currentStatus == 'PRINT_COMPLETED') {
          await addNotification(
            fileId: fileId,
            fileName: fileName,
            type: 'PRINT_COMPLETED',
            message: 'Your file has been printed successfully',
          );
        }
      }
      
      // Also generate notification for new files that are already rejected/completed
      if (previousStatus == null) {
        if (currentStatus == 'REJECTED') {
          await addNotification(
            fileId: fileId,
            fileName: fileName,
            type: 'REJECTED',
            message: rejectionReason ?? 'Your file was rejected',
          );
        } else if (currentStatus == 'PRINT_COMPLETED') {
          await addNotification(
            fileId: fileId,
            fileName: fileName,
            type: 'PRINT_COMPLETED',
            message: 'Your file has been printed successfully',
          );
        }
      }
    }
    
    // Save current statuses for next check
    final currentStatuses = <String, String>{};
    for (final file in currentFiles) {
      final fileId = file['file_id']?.toString() ?? '';
      final status = file['status']?.toString() ?? '';
      if (fileId.isNotEmpty) {
        currentStatuses[fileId] = status;
      }
    }
    await prefs.setString(_lastCheckKey, jsonEncode(currentStatuses));
  }
}
