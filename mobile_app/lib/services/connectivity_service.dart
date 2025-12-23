// ========================================
// CONNECTIVITY SERVICE
// Checks internet connection before operations
// ========================================

import 'dart:io';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/secure_logger.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  
  // ========================================
  // CHECK CONNECTIVITY
  // ========================================
  
  /// Check if device has any network connectivity
  static Future<bool> hasConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      SecureLogger.error('Connectivity check failed', e);
      return false; // Assume no connectivity on error
    }
  }
  
  /// Check if device can actually reach the internet (not just connected to WiFi)
  static Future<bool> hasInternetAccess() async {
    try {
      // Try to lookup a reliable DNS
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (e) {
      SecureLogger.error('Internet check failed', e);
      return false;
    }
  }
  
  // ========================================
  // WRAPPER FOR OPERATIONS
  // ========================================
  
  /// Execute an operation only if internet is available
  /// Throws ConnectivityException if no internet
  static Future<T> withConnectivityCheck<T>(
    Future<T> Function() operation, {
    bool checkInternet = true,
  }) async {
    // First, check basic connectivity
    if (!await hasConnectivity()) {
      throw ConnectivityException('No network connection detected. Please check your WiFi or mobile data.');
    }
    
    // Optionally, verify actual internet access
    if (checkInternet && !await hasInternetAccess()) {
      throw ConnectivityException('Connected to network but no internet access. Please check your connection.');
    }
    
    // Execute the operation
    return await operation();
  }
  
  /// Get current connectivity status as user-friendly string
  static Future<String> getConnectionStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      
      switch (result) {
        case ConnectivityResult.wifi:
          return 'Connected via WiFi';
        case ConnectivityResult.mobile:
          return 'Connected via Mobile Data';
        case ConnectivityResult.ethernet:
          return 'Connected via Ethernet';
        case ConnectivityResult.vpn:
          return 'Connected via VPN';
        case ConnectivityResult.bluetooth:
          return 'Connected via Bluetooth';
        case ConnectivityResult.none:
          return 'No internet connection';
        default:
          return 'Unknown connection status';
      }
    } catch (e) {
      return 'Unable to determine connection status';
    }
  }
  
  // ========================================
  // STREAM FOR REAL-TIME MONITORING
  // ========================================
  
  /// Listen to connectivity changes
  static Stream<ConnectivityResult> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
}

// ========================================
// CONNECTIVITY EXCEPTION
// ========================================

class ConnectivityException implements Exception {
  final String message;
  
  ConnectivityException(this.message);
  
  @override
  String toString() => message;
}
