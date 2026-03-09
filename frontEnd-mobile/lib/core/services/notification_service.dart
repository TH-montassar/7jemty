import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // For ValueNotifier
import 'package:hjamty/config/api_config.dart';
import 'package:hjamty/core/services/fcm_service.dart';

class NotificationService {
  // Reactive state for unread notifications count
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  static Future<List<dynamic>> getMyNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Veuillez vous connecter pour voir vos notifications.');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.host}/api/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des notifications.');
    }
  }

  static Future<int> getUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse('${ApiConfig.host}/api/notifications/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final count = data['count'] ?? 0;
        unreadCountNotifier.value = count;
        return count;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static void refreshUnreadCount() {
    getUnreadCount();
  }

  static http.StreamedResponse? _streamResponse;
  static final http.Client _client = http.Client();

  static void listenToNotificationsStream() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return;

      final request = http.Request(
        'GET',
        Uri.parse('${ApiConfig.host}/api/notifications/stream'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      _client.send(request).then((response) {
        _streamResponse = response;
        response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              (line) {
                if (line.startsWith('data: ')) {
                  final dataStr = line.substring(6);
                  if (dataStr.trim() == '{"connected":true}') return;
                  try {
                    final data = json.decode(dataStr);

                    // Bridge to FcmService for real-time UI refresh
                    if (data is Map<String, dynamic>) {
                      FcmService.dispatchMessage(data);
                    }

                    if (data['id'] != null ||
                        data['type'] == 'NOTIFICATION_READ') {
                      refreshUnreadCount();
                    }
                  } catch (e) {
                    debugPrint('SSE Decode Error: $e');
                  }
                }
              },
              onDone: () {
                debugPrint('SSE Stream closed. Reconnecting in 5s...');
                Future.delayed(
                  const Duration(seconds: 5),
                  () => listenToNotificationsStream(),
                );
              },
              onError: (e) {
                debugPrint('SSE Stream error: $e. Reconnecting in 5s...');
                Future.delayed(
                  const Duration(seconds: 5),
                  () => listenToNotificationsStream(),
                );
              },
            );
      });
    } catch (e) {
      debugPrint('SSE Connection Error: $e');
    }
  }

  static Future<void> markAsRead(int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return;

    await http.patch(
      Uri.parse('${ApiConfig.host}/api/notifications/$notificationId/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}
