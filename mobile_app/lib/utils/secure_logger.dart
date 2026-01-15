// ========================================
// SECURE LOGGER - MOBILE APP
// Prevents sensitive data from being logged
// ========================================

import 'package:flutter/foundation.dart';

class SecureLogger {
  // ========================================
  // LOG LEVELS
  // ========================================
  
  static void debug(String message) {
    if (kDebugMode) {
      print('[DEBUG] $message');
    }
  }
  
  static void info(String message) {
    print('[INFO] $message');
  }
  
  static void warning(String message) {
    print('[WARNING] $message');
  }
  
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    print('[ERROR] $message');
    if (error != null) {
      print('[ERROR] Exception: $error');
    }
    if (stackTrace != null && kDebugMode) {
      print('[ERROR] Stack trace:\n$stackTrace');
    }
  }
  
  // ========================================
  // SANITIZATION - NEVER LOG SENSITIVE DATA
  // ========================================
  
  /// Sanitize sensitive strings (tokens, keys, passwords)
  /// Shows only first few characters, rest is redacted
  static String sanitize(String data, {int showLength = 8}) {
    if (data.isEmpty) return '[EMPTY]';
    if (data.length <= showLength) {
      return '[REDACTED]';
    }
    return '${data.substring(0, showLength)}...[REDACTED ${data.length - showLength} chars]';
  }
  
  /// Sanitize byte arrays (encryption keys, file data)
  /// Shows only length, never content
  static String sanitizeBytes(List<int> data) {
    return '[BINARY DATA: ${data.length} bytes]';
  }
  
  /// Sanitize email addresses (show domain, hide local part)
  static String sanitizeEmail(String email) {
    if (!email.contains('@')) return '[INVALID EMAIL]';
    final parts = email.split('@');
    if (parts[0].length <= 2) {
      return '**@${parts[1]}';
    }
    return '${parts[0].substring(0, 2)}***@${parts[1]}';
  }
  
  /// Sanitize phone numbers (show last 4 digits only)
  static String sanitizePhone(String phone) {
    if (phone.length < 4) return '[REDACTED]';
    return '****${phone.substring(phone.length - 4)}';
  }
  
  // ========================================
  // SECURITY-SAFE LOGGING HELPERS
  // ========================================
  
  static void logTokenUsage(String tokenType) {
    if (kDebugMode) {
      debug('Using $tokenType (content redacted for security)');
    }
  }
  
  static void logEncryptionOperation(String operation, int dataSize) {
    debug('$operation completed for $dataSize bytes');
  }
  
  static void logApiCall(String endpoint, {String? method}) {
    debug('API ${method ?? 'GET'}: $endpoint');
  }
  
  static void logFileOperation(String operation, String filename, int size) {
    debug('$operation: $filename ($size bytes)');
  }
  
  // ========================================
  // CONDITIONAL DEBUG (only in debug mode)
  // ========================================
  
  static void debugOnly(String message) {
    if (kDebugMode) {
      print('[DEBUG] $message');
    }
  }
  
  // ========================================
  // SECURE ASSERTION
  // ========================================
  
  static void assertCondition(bool condition, String message) {
    if (!condition) {
      error('Assertion failed: $message');
      if (kDebugMode) {
        throw AssertionError(message);
      }
    }
  }
}

// ========================================
// EXTENSION FOR EASY REDACTION
// ========================================

extension SecureString on String {
  String get redacted => SecureLogger.sanitize(this);
  String get redactedEmail => SecureLogger.sanitizeEmail(this);
  String get redactedPhone => SecureLogger.sanitizePhone(this);
}
