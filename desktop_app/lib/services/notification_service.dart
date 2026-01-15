import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NotificationService {
  final String baseUrl = 'http://10.85.144.137:5000';
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  http.Client? _client;
  bool _isConnected = false;

  Stream<Map<String, dynamic>> get events => _controller.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String accessToken) async {
    if (_isConnected) return;

    try {
      _client = http.Client();
      final request = http.Request(
        'GET',
        Uri.parse('$baseUrl/api/events/stream'),
      );
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.headers['Accept'] = 'text/event-stream';

      final response = await _client!.send(request);
      _isConnected = true;

      if (kDebugMode) {
        print('Connected to notification stream');
      }

      // Buffer to handle partial chunks
      String buffer = '';

      response.stream
          .transform(utf8.decoder)
          .listen(
            (data) {
              buffer += data;

              // Process complete messages (ended with double newline)
              while (buffer.contains('\n\n')) {
                final index = buffer.indexOf('\n\n');
                final message = buffer.substring(0, index);
                buffer = buffer.substring(index + 2);

                _processMessage(message);
              }
            },
            onError: (error) {
              print('Stream error: $error');
              _disconnect();
            },
            onDone: () {
              print('Stream closed');
              _disconnect();
            },
            cancelOnError: true,
          );
    } catch (e) {
      print('Connection error: $e');
      _isConnected = false;
    }
  }

  void _processMessage(String message) {
    String? event;
    String? data;

    final lines = message.split('\n');
    for (final line in lines) {
      if (line.startsWith('event: ')) {
        event = line.substring(7).trim();
      } else if (line.startsWith('data: ')) {
        data = line.substring(6).trim();
      }
    }

    if (event != null && data != null) {
      try {
        final jsonData = jsonDecode(data);
        _controller.add({'event': event, 'data': jsonData});
        if (kDebugMode) {
          print('Received event: $event');
        }
      } catch (e) {
        print('Error parsing event data: $e');
      }
    }
  }

  void _disconnect() {
    _isConnected = false;
    _client?.close();
    _client = null;
  }

  void dispose() {
    _disconnect();
    _controller.close();
  }
}
