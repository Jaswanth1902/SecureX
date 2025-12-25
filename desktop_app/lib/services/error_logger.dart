import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ErrorLogger {
  static const String _logFileName = 'error_log.txt';
  
  // Singleton instance
  static final ErrorLogger _instance = ErrorLogger._internal();
  factory ErrorLogger() => _instance;
  ErrorLogger._internal();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_logFileName');
  }

  Future<void> logError({
    required String context,
    required String message,
    StackTrace? stackTrace,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final platform = defaultTargetPlatform.toString();
    
    final logEntry = '''
[$timestamp] [$platform] [$context]
Message: $message
Stack Trace: ${stackTrace?.toString() ?? 'None'}
--------------------------------------------------------------------------------
''';

    // Print to console for dev visibility
    debugPrint('🔴 Error Logged: $message');

    // Write to file (non-blocking)
    try {
      final file = await _localFile;
      await file.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      // Fallback if writing fails - just print to console
      debugPrint('❌ Failed to write to error log: $e');
    }
  }

  Future<String> getLogs() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        return await file.readAsString();
      }
      return 'No logs found.';
    } catch (e) {
      return 'Error reading logs: $e';
    }
  }

  Future<void> clearLogs() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error clearing logs: $e');
    }
  }
}
