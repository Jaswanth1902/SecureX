// ========================================
// PERMISSIONS SERVICE
// Handles all app permission requests
// ========================================

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionsService {
  // ========================================
  // STORAGE PERMISSIONS - ANDROID 13+ AWARE
  // ========================================

  /// Request storage read/write permissions
  /// For Android 13+, requests individual media permissions instead of generic storage
  static Future<bool> requestStoragePermission() async {
    try {
      if (!Platform.isAndroid) {
        return true;
      }
      // Get Android SDK version
      final plugin = DeviceInfoPlugin();
      final info = await plugin.androidInfo;
      final sdkInt = info.version.sdkInt ?? 0;

      debugPrint('📱 Android SDK Version: $sdkInt');

      if (sdkInt >= 33) {
        // Android 13+ (API 33+) - Use scoped storage with individual media permissions
        debugPrint('🔒 Using Android 13+ scoped storage permissions');

        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        final audio = await Permission.audio.request();
        // Also request MANAGE_EXTERNAL_STORAGE for document access if possible
        final documents = await Permission.storage.request();
        final manage = await Permission.manageExternalStorage.request();

        final granted = photos.isGranted ||
            videos.isGranted ||
            audio.isGranted ||
            documents.isGranted ||
            manage.isGranted;

        debugPrint('📸 Photos: $photos');
        debugPrint('🎬 Videos: $videos');
        debugPrint('🔊 Audio: $audio');
        debugPrint('📄 Documents: $documents');

        return granted;
      }
      if (sdkInt >= 30) {
        // Android 12 and below - Use legacy storage permission
        debugPrint('💾 Using Android 12 and below storage permissions');
        // On Android 11+ we can request MANAGE_EXTERNAL_STORAGE for broad file access
        final manageStatus = await Permission.manageExternalStorage.request();
        debugPrint('🔐 Manage External Storage: $manageStatus');
        if (manageStatus.isGranted) return true;
        final status = await Permission.storage.request();
        debugPrint('💾 Storage: $status');
        return status.isGranted;
      }
      // Android 6-10 (Legacy storage)
      debugPrint('📂 Requesting Android 6-10 permissions (legacy)');
      final status = await Permission.storage.request();
      debugPrint('💾 Storage: $status');
      return status.isGranted;
      return true;
    } catch (e) {
      debugPrint('❌ Error requesting storage permission: $e');
      // Assume permission might be granted, don't fail
      return true;
    }
  }

  // ========================================
  // ANDROID 13+ MEDIA PERMISSIONS
  // ========================================

  /// Request photos permission (Android 13+)
  static Future<bool> requestPhotosPermission() async {
    try {
      final status = await Permission.photos.request();
      debugPrint('📸 Photos Permission: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting photos permission: $e');
      return true; // Assume might be granted
    }
  }

  /// Request videos permission (Android 13+)
  static Future<bool> requestVideosPermission() async {
    try {
      final status = await Permission.videos.request();
      debugPrint('🎬 Videos Permission: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting videos permission: $e');
      return true; // Assume might be granted
    }
  }

  /// Request audio permission (Android 13+)
  static Future<bool> requestAudioPermission() async {
    try {
      final status = await Permission.audio.request();
      debugPrint('🔊 Audio Permission: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting audio permission: $e');
      return true; // Assume might be granted
    }
  }

  // ========================================
  // COMBINED PERMISSIONS REQUEST
  // ========================================

  /// Request all file access permissions
  /// Smart handling for different Android versions
  static Future<bool> requestAllFilePermissions() async {
    debugPrint('🔐 Starting file permission request...');

    try {
      if (Platform.isAndroid) {
        final plugin = DeviceInfoPlugin();
        final info = await plugin.androidInfo;
        final sdkInt = info.version.sdkInt ?? 0;

        debugPrint('📱 Device Android SDK: $sdkInt');

        if (sdkInt >= 33) {
          // Android 13+ (Scoped Storage)
          debugPrint('📂 Requesting Android 13+ permissions (scoped storage)');

          final results = await Future.wait([
            Permission.photos.request(),
            Permission.videos.request(),
            Permission.audio.request(),
            Permission.storage.request(),
            Permission.manageExternalStorage.request(),
          ]);

          final allGranted = results.any((status) => status.isGranted);

          if (allGranted) {
            debugPrint('✅ File access permissions granted (Android 13+)');
          } else {
            debugPrint('⚠️ Some file permissions may be denied (Android 13+)');
          }

          return allGranted;
        } else if (sdkInt >= 30) {
          // Android 11-12 (Scoped Storage with storage permission)
          debugPrint('📂 Requesting Android 11-12 permissions');

          // Prefer requesting MANAGE_EXTERNAL_STORAGE on Android 11+ for document access
          final manage = await Permission.manageExternalStorage.request();
          final storage = await Permission.storage.request();
          final photos = await Permission.photos.request();
          final videos = await Permission.videos.request();

          final allGranted = manage.isGranted || storage.isGranted || photos.isGranted || videos.isGranted;

          debugPrint('💾 Storage: $storage');
          debugPrint('🔐 Manage External Storage: $manage');
          debugPrint('📸 Photos: $photos');
          debugPrint('🎬 Videos: $videos');

          if (allGranted) {
            debugPrint('✅ File access permissions granted (Android 11-12)');
          } else {
            debugPrint('⚠️ Some file permissions may be denied (Android 11-12)');
          }

          return allGranted;
        } else {
          // Android 6-10 (Legacy storage)
          debugPrint('📂 Requesting Android 6-10 permissions (legacy)');

          final status = await Permission.storage.request();
          debugPrint('💾 Storage: $status');

          if (status.isGranted) {
            debugPrint('✅ File access permissions granted (Android 6-10)');
          } else {
            debugPrint('⚠️ File permissions not granted (Android 6-10)');
          }

          return status.isGranted;
        }
      }

      // Non-Android platforms
      debugPrint('✅ Not Android platform, assuming permissions granted');
      return true;
    } catch (e) {
      debugPrint('❌ Error in requestAllFilePermissions: $e');
      // Don't fail completely, file picker will handle it
      return true;
    }
  }

  // ========================================
  // PERMISSION STATUS CHECK
  // ========================================

  /// Check if any file permission is granted
  static Future<bool> hasFilePermission() async {
    try {
      if (Platform.isAndroid) {
        final plugin = DeviceInfoPlugin();
        final info = await plugin.androidInfo;
        final sdkInt = info.version.sdkInt ?? 0;

        if (sdkInt >= 33) {
          // Android 13+
          final photos = await Permission.photos.status;
          final videos = await Permission.videos.status;
          final audio = await Permission.audio.status;
          final manage = await Permission.manageExternalStorage.status;
          return photos.isGranted || videos.isGranted || audio.isGranted || manage.isGranted;
        } else {
          // Android 12 and below
          final storage = await Permission.storage.status;
          final manage = await Permission.manageExternalStorage.status;
          return storage.isGranted || manage.isGranted;
        }
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error checking file permission: $e');
      return true;
    }
  }

  /// Open app settings if permissions are permanently denied
  static Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }

  /// Open app settings page to allow user to grant All Files Access (Android 11+)
  static Future<void> openAllFilesAccessSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('❌ Failed to open app settings: $e');
    }
  }
}
