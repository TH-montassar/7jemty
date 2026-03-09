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

  // Manual dispatch for SSE or other sources
  static void dispatchMessage(Map<String, dynamic> data) {
    _messageStreamController.add(data);
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
      await _localNotifications.initialize(settings: initializationSettings);

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

      // 4. Token refresh listener
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
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
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
    );
  }
}

// Global background handler (MUST be outside any class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}
