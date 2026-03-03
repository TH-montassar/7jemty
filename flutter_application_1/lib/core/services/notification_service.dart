import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

class NotificationService {
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
      final notifications = await getMyNotifications();
      return notifications.where((n) => n['isRead'] == false).length;
    } catch (e) {
      return 0;
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
