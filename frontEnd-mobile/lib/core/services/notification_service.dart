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

  static void resetUnreadCount() {
    unreadCountNotifier.value = 0;
  }

  static Future<List<dynamic>> getMyNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      resetUnreadCount();
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
      if (token == null) {
        resetUnreadCount();
        return 0;
      }

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
      resetUnreadCount();
      return 0;
    } catch (e) {
      resetUnreadCount();
      return 0;
    }
  }

  static Timer? _refreshUnreadCountTimer;

  static void refreshUnreadCount() {
    _refreshUnreadCountTimer?.cancel();
    _refreshUnreadCountTimer = Timer(const Duration(milliseconds: 250), () {
      getUnreadCount();
    });
  }

  static http.StreamedResponse? _streamResponse;
  static final http.Client _client = http.Client();
  static StreamSubscription<String>? _streamSubscription;
  static Timer? _reconnectTimer;
  static bool _isConnecting = false;
  static String? _activeToken;

  static void listenToNotificationsStream() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        stopListeningToNotificationsStream();
        resetUnreadCount();
        return;
      }

      final isAlreadyListening =
          _activeToken == token &&
          (_isConnecting || _streamSubscription != null || _streamResponse != null);
      if (isAlreadyListening) {
        return;
      }

      if (_activeToken != null && _activeToken != token) {
        stopListeningToNotificationsStream();
      }

      _isConnecting = true;
      _activeToken = token;
      _reconnectTimer?.cancel();

      final request = http.Request(
        'GET',
        Uri.parse('${ApiConfig.host}/api/notifications/stream'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      _client.send(request).then((response) {
        _isConnecting = false;
        _streamResponse = response;
        _streamSubscription = response.stream
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
                        data['type'] == 'NOTIFICATION_READ' ||
                        data['type'] == 'NOTIFICATIONS_READ_ALL') {
                      refreshUnreadCount();
                    }
                  } catch (e) {
                    debugPrint('SSE Decode Error: $e');
                  }
                }
              },
              onDone: () {
                debugPrint('SSE Stream closed. Reconnecting in 5s...');
                _streamSubscription = null;
                _streamResponse = null;
                _scheduleReconnect();
              },
              onError: (e) {
                debugPrint('SSE Stream error: $e. Reconnecting in 5s...');
                _streamSubscription = null;
                _streamResponse = null;
                _scheduleReconnect();
              },
            );
      }).catchError((e) {
        _isConnecting = false;
        _streamResponse = null;
        debugPrint('SSE Connection Error: $e');
        _scheduleReconnect();
      });
    } catch (e) {
      debugPrint('SSE Connection Error: $e');
    }
  }

  static void stopListeningToNotificationsStream() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _streamResponse = null;
    _isConnecting = false;
    _activeToken = null;
  }

  static void _scheduleReconnect() {
    if (_reconnectTimer != null || _activeToken == null) return;
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _reconnectTimer = null;
      listenToNotificationsStream();
    });
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

  static Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) return;

    final response = await http.patch(
      Uri.parse('${ApiConfig.host}/api/notifications/read-all'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      unreadCountNotifier.value = 0;
      return;
    }

    throw Exception('Erreur lors du marquage de toutes les notifications.');
  }
}
