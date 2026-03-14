import 'package:firebase_core/firebase_core.dart';
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
  static const String _androidChannelId = 'hjamty_main_channel';
  static const String _androidChannelName = 'Hjamty Notifications';
  static const String _androidChannelDescription =
      'Notifications for appointments and account activity.';
  static const String _pendingFcmTokenPrefsKey = 'pending_fcm_token';

  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _androidNotificationChannel =
      AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.max,
      );
  static bool _localNotificationsInitialized = false;

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
  static final Map<String, int> _recentMessageSignatures = {};
  static const Duration _messageDeduplicationWindow = Duration(seconds: 2);

  static bool get _isPushSupportedPlatform => !kIsWeb;

  // Manual dispatch for SSE or other sources
  static void dispatchMessage(Map<String, dynamic> data) {
    final normalizedPayload = _normalizePayload(data);
    if (normalizedPayload.isEmpty) return;

    final signature = _buildMessageSignature(normalizedPayload);
    final now = DateTime.now().millisecondsSinceEpoch;
    _recentMessageSignatures.removeWhere(
      (_, seenAt) => now - seenAt > _messageDeduplicationWindow.inMilliseconds,
    );

    final lastSeenAt = _recentMessageSignatures[signature];
    if (lastSeenAt != null &&
        now - lastSeenAt <= _messageDeduplicationWindow.inMilliseconds) {
      return;
    }

    _recentMessageSignatures[signature] = now;
    _messageStreamController.add(normalizedPayload);
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
    if (!_isPushSupportedPlatform) {
      debugPrint('Skipping FCM initialization on Web.');
      return;
    }

    await ensureLocalNotificationsInitialized();

    // 1. Request Permission from User
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final androidImplementation =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidImplementation?.requestNotificationsPermission();

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    debugPrint('User granted native notification permissions.');

    // 2. Fetch FCM Token
    await syncCurrentTokenWithBackend();

    // 3. Listen to foreground messages (while app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');

      // Push the payload to the stream so UI can react in real-time
      if (message.data.isNotEmpty) {
        dispatchMessage(message.data);
      }

      if (_hasVisibleNotificationContent(message)) {
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
  }

  static Future<void> ensureLocalNotificationsInitialized() async {
    if (!_isPushSupportedPlatform) return;
    if (_localNotificationsInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    final androidImplementation =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidImplementation?.createNotificationChannel(
      _androidNotificationChannel,
    );

    _localNotificationsInitialized = true;
  }

  static Future<void> syncCurrentTokenWithBackend() async {
    if (!_isPushSupportedPlatform) {
      debugPrint('Skipping FCM token sync on Web.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final currentToken = await _firebaseMessaging.getToken();
    final tokenToSync =
        currentToken?.trim().isNotEmpty == true
            ? currentToken!.trim()
            : prefs.getString(_pendingFcmTokenPrefsKey);

    if (tokenToSync == null || tokenToSync.isEmpty) {
      debugPrint('No FCM token available to sync.');
      return;
    }

    if (!kReleaseMode) {
      debugPrint('FCM Token ready: $tokenToSync');
    }

    await syncTokenWithBackend(tokenToSync);
  }

  static Future<void> unregisterDeviceToken() async {
    if (!_isPushSupportedPlatform) {
      debugPrint('Skipping FCM token unregister on Web.');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('jwt_token');

      if (userToken == null || userToken.isEmpty) return;

      final response = await http.patch(
        Uri.parse('${ApiConfig.host}/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({'fcmToken': null}),
      );

      if (response.statusCode == 200) {
        await prefs.remove(_pendingFcmTokenPrefsKey);
        debugPrint('FCM token removed from backend successfully.');
      } else {
        debugPrint(
          'Failed to remove FCM token. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Failed to unregister FCM token: $e');
    }
  }

  // Helper to send the token to NestJS
  static Future<void> syncTokenWithBackend(String fcmToken) async {
    if (!_isPushSupportedPlatform) {
      debugPrint('Skipping FCM backend sync on Web.');
      return;
    }

    try {
      if (fcmToken.trim().isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('jwt_token'); // JWT auth token
      await prefs.setString(_pendingFcmTokenPrefsKey, fcmToken);

      if (userToken == null || userToken.isEmpty) {
        debugPrint('JWT missing, postponing FCM token sync until login.');
        return;
      }

      final response = await http.patch(
        Uri.parse('${ApiConfig.host}/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      if (response.statusCode == 200) {
        await prefs.remove(_pendingFcmTokenPrefsKey);
        debugPrint('FCM Token synced to backend successfully.');
      } else {
        debugPrint(
          'Failed to sync FCM token. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Failed to sync FCM Token: $e');
    }
  }

  // Local physical pop-up showing the Push logic
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    await showNotification(
      id: message.hashCode,
      title: _extractVisibleTitle(message),
      body: _extractVisibleBody(message),
      payloadData: message.data,
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payloadData,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
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

  static String _buildMessageSignature(Map<String, dynamic> payload) {
    final signaturePayload = <String, String?>{
      'type': payload['type']?.toString(),
      'eventType': payload['eventType']?.toString(),
      'appointmentId': payload['appointmentId']?.toString(),
      'newStatus': payload['newStatus']?.toString(),
      'status': payload['status']?.toString(),
      'deeplink': payload['deeplink']?.toString(),
      'title': payload['title']?.toString(),
      'body': payload['body']?.toString(),
    };

    return jsonEncode(signaturePayload);
  }

  static bool _hasVisibleNotificationContent(RemoteMessage message) {
    return _extractVisibleTitle(message).isNotEmpty ||
        _extractVisibleBody(message).isNotEmpty;
  }

  static String _extractVisibleTitle(RemoteMessage message) {
    final notificationTitle = message.notification?.title?.trim();
    if (notificationTitle != null && notificationTitle.isNotEmpty) {
      return notificationTitle;
    }

    final dataTitle = message.data['title']?.toString().trim();
    if (dataTitle != null && dataTitle.isNotEmpty) {
      return dataTitle;
    }

    final fallbackTitle = message.data['notificationTitle']?.toString().trim();
    return fallbackTitle ?? '';
  }

  static String _extractVisibleBody(RemoteMessage message) {
    final notificationBody = message.notification?.body?.trim();
    if (notificationBody != null && notificationBody.isNotEmpty) {
      return notificationBody;
    }

    final dataBody = message.data['body']?.toString().trim();
    if (dataBody != null && dataBody.isNotEmpty) {
      return dataBody;
    }

    final fallbackBody = message.data['notificationBody']?.toString().trim();
    return fallbackBody ?? '';
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
  if (kIsWeb) {
    debugPrint('Skipping background FCM handler on Web.');
    return;
  }

  await Firebase.initializeApp();
  await FcmService.ensureLocalNotificationsInitialized();
  debugPrint("Handling a background message: ${message.messageId}");

  if (message.data.isNotEmpty) {
    FcmService.dispatchMessage(message.data);
  }

  if (message.notification == null &&
      (message.data['title']?.toString().trim().isNotEmpty == true ||
          message.data['body']?.toString().trim().isNotEmpty == true)) {
    await FcmService.showNotification(
      id: message.hashCode,
      title: message.data['title']?.toString() ?? '',
      body: message.data['body']?.toString() ?? '',
      payloadData: message.data,
    );
  }
}
