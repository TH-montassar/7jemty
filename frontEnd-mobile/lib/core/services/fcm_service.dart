import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:hjamty/core/services/notification_service.dart';
import '../../../config/api_config.dart';

import 'dart:async';

class FcmService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Create a broadcast stream to listen for specific data payloads (e.g., appointment updates)
  static final StreamController<Map<String, dynamic>> _messageStreamController =
      StreamController.broadcast();
  static Stream<Map<String, dynamic>> get messageStream =>
      _messageStreamController.stream;

  static final StreamController<Map<String, dynamic>>
  _notificationTapStreamController = StreamController.broadcast();
  static Stream<Map<String, dynamic>> get notificationTapStream =>
      _notificationTapStreamController.stream;

  static Map<String, dynamic>? _pendingNotificationTapPayload;

  // Manual dispatch for SSE or other sources
  static void dispatchMessage(Map<String, dynamic> data) {
    _messageStreamController.add(data);
  }

  static Map<String, dynamic>? consumePendingNotificationTap() {
    final payload = _pendingNotificationTapPayload;
    _pendingNotificationTapPayload = null;
    return payload;
  }

  static int? extractAppointmentId(Map<String, dynamic> payload) {
    return _toInt(payload['appointmentId']);
  }

  static String? extractStatus(Map<String, dynamic> payload) {
    final dynamic rawStatus =
        payload['newStatus'] ?? payload['status'] ?? payload['appointmentStatus'];
    final status = rawStatus?.toString().trim();
    if (status == null || status.isEmpty) return null;
    return status.toUpperCase();
  }

  static bool shouldOpenHistoryTab(Map<String, dynamic> payload) {
    const historyStatuses = {'COMPLETED', 'CANCELLED', 'DECLINED'};
    final status = extractStatus(payload);
    if (status != null && historyStatuses.contains(status)) {
      return true;
    }

    final eventType = (payload['eventType'] ?? '').toString().toUpperCase();
    return eventType == 'APPT_COMPLETED' ||
        eventType == 'APPT_CANCELLED' ||
        eventType == 'APPT_DECLINED';
  }

  static bool isAppointmentPayload(Map<String, dynamic> payload) {
    if (extractAppointmentId(payload) != null) return true;
    final deeplink = (payload['deeplink'] ?? '').toString();
    return deeplink.startsWith('/appointments/');
  }

  static void dispatchNotificationTapPayload(Map<String, dynamic> payload) {
    if (payload.isEmpty) return;
    _dispatchNotificationTap(_normalizePayload(payload));
  }

  // Initialization
  static Future<void> initialize() async {
    // 1. Request Permission from User
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted native notification permissions.');

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _handleLocalNotificationTap,
      );

      // 2. Fetch FCM Token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token generated: $token');
        await syncTokenWithBackend(token);
      }

      // 3. Listen to foreground messages (while app is open)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');

        // Push the payload to the stream so UI can react in real-time
        if (message.data.isNotEmpty) {
          _messageStreamController.add(message.data);
        }

        if (message.notification != null &&
            (message.notification?.title?.isNotEmpty == true ||
                message.notification?.body?.isNotEmpty == true)) {
          _showLocalNotification(message);
          // Instantly update badge count reactively by fetching the true count
          NotificationService.refreshUnreadCount();
        }
      });

      // 4. Open app from push tap while app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageTap);

      // 5. Open app from push tap when app was terminated
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessageTap(initialMessage);
      }

      // 6. Token refresh listener
      FirebaseMessaging.instance.onTokenRefresh.listen(syncTokenWithBackend);
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  // Helper to send the token to NestJS
  static Future<void> syncTokenWithBackend(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('jwt_token'); // JWT auth token

      if (userToken == null) return; // User not logged in, ignore.

      final response = await http.patch(
        Uri.parse('${ApiConfig.host}/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM Token synced to backend successfully.');
      }
    } catch (e) {
      debugPrint('Failed to sync FCM Token: $e');
    }
  }

  // Local physical pop-up showing the Push logic
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    await showNotification(
      id: message.hashCode,
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      payloadData: message.data,
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payloadData,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'hjamty_main_channel', // channelId
          'Hjamty Notifications', // channelName
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: _encodePayload(payloadData),
    );
  }

  static void _handleRemoteMessageTap(RemoteMessage message) {
    final payload = _normalizePayload(message.data);
    if (payload.isEmpty) return;
    _dispatchNotificationTap(payload);
  }

  static void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = _decodePayload(response.payload);
    if (payload.isEmpty) return;
    _dispatchNotificationTap(payload);
  }

  static void _dispatchNotificationTap(Map<String, dynamic> payload) {
    _pendingNotificationTapPayload = payload;
    _notificationTapStreamController.add(payload);
  }

  static String? _encodePayload(Map<String, dynamic>? payload) {
    if (payload == null || payload.isEmpty) return null;
    return jsonEncode(_normalizePayload(payload));
  }

  static Map<String, dynamic> _decodePayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } catch (_) {
      // Ignore malformed payload.
    }
    return {};
  }

  static Map<String, dynamic> _normalizePayload(Map<String, dynamic> data) {
    return data.map(
      (key, value) => MapEntry(key, value is String ? value : value?.toString()),
    );
  }

  static int? _toInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }
}

// Global background handler (MUST be outside any class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}
