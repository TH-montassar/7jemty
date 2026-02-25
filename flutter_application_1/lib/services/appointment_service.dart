import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppointmentService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/appointment';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/appointment';
    } else {
      return 'http://localhost:3000/api/appointment';
    }
  }

  // Changer le statut (CONFIRMED, DECLINED, COMPLETED, CANCELLED)
  static Future<Map<String, dynamic>> updateStatus({
    required int appointmentId,
    required String status,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Rak mouch connecté!');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/$appointmentId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la mise à jour du statut',
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // TODO: Add fetch employee appointments endpoint in backend if needed.
  // We can mock it in front-end for the UI for now since getting all appointments is usually a separate route.
}
