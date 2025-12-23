// ========================================
// OPERATION TIMEOUT UTILITY
// Prevents app freezing on slow operations
// ========================================

import 'dart:async';

class OperationTimeout {
  // ========================================
  // TIMEOUT DURATIONS
  // ========================================
  
  static const Duration fileEncryption = Duration(minutes: 5);
  static const Duration fileUpload = Duration(minutes: 10);
  static const Duration apiCall = Duration(seconds: 30);
  static const Duration keyFetch = Duration(seconds: 15);
  
  // ========================================
  // TIMEOUT WRAPPER WITH CUSTOM MESSAGE
  // ========================================
  
  static Future<T> withTimeout<T>({
    required Future<T> Function() operation,
    required Duration timeout,
    required String operationName,
  }) async {
    try {
      return await operation().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            '$operationName timed out after ${timeout.inSeconds} seconds. '
            'Please check your connection and try again.',
          );
        },
      );
    } on TimeoutException {
      rethrow;
    } catch (e) {
      // Re-throw other exceptions as-is
      rethrow;
    }
  }
 
 // ========================================
  // CANCELLABLE OPERATION
  // ========================================
  
  static Future<T> cancellable<T>({
    required Future<T> Function(CancellationToken token) operation,
    required String operationName,
  }) async {
    final token = CancellationToken();
    
    try {
      return await operation(token);
    } catch (e) {
      if (token.isCancelled) {
        throw OperationCancelledException(operationName);
      }
      rethrow;
    }
  }
}

// ========================================
// CANCELLATION TOKEN
// ========================================

class CancellationToken {
  bool _isCancelled = false;
  
  bool get isCancelled => _isCancelled;
  
  void cancel() {
    _isCancelled = true;
  }
  
  void throwIfCancelled() {
    if (_isCancelled) {
      throw OperationCancelledException('Operation was cancelled');
    }
  }
}

// ========================================
// CUSTOM EXCEPTIONS
// ========================================

class OperationCancelledException implements Exception {
  final String message;
  
  OperationCancelledException(String operationName)
      : message = '$operationName was cancelled by user';
  
  @override
  String toString() => message;
}

class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
