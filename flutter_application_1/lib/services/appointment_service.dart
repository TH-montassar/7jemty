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

  // Changer le statut (CONFIRMED, DECLINED, COMPLETED, CANCELLED, IN_PROGRESS, STARTED)
  static Future<Map<String, dynamic>> updateStatus({
    required int appointmentId,
    required String status,
    int? actualDuration, // Optionnel pour COMPLETED
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Rak mouch connecté!');
      }

      final body = {
        'status': status,
        if (actualDuration != null) 'actualDuration': actualDuration,
      };

      final response = await http.patch(
        Uri.parse('$baseUrl/$appointmentId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
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

  static Future<List<dynamic>> getSalonAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Rak mouch connecté!');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/salon'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'] ?? [];
    } else {
      throw Exception(
        data['message'] ?? 'Erreur lors de la récupération des rendez-vous',
      );
    }
  }

  static Future<List<dynamic>> getClientAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Rak mouch connecté!');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/client'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'] ?? [];
    } else {
      throw Exception(
        data['message'] ?? 'Erreur lors de la récupération des rendez-vous',
      );
    }
  }

  static Future<List<dynamic>> getEmployeeAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Rak mouch connecté!');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/employee'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'] ?? [];
    } else {
      throw Exception(
        data['message'] ?? 'Erreur lors de la récupération des rendez-vous',
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getAvailability({
    required int salonId,
    required String date,
    int? barberId,
    List<int>? serviceIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Rak mouch connecté!');
    }

    final queryParams = {'salonId': salonId.toString(), 'date': date};

    if (barberId != null) {
      queryParams['barberId'] = barberId.toString();
    }

    if (serviceIds != null && serviceIds.isNotEmpty) {
      queryParams['serviceIds'] = serviceIds.join(',');
    }

    final uri = Uri.parse(
      '$baseUrl/availability',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception(data['message'] ?? 'Erreur availability');
    }
  }

  static Future<Map<String, dynamic>> createAppointment({
    required int salonId,
    required int barberId,
    required String date,
    required String time,
    required List<int> serviceIds,
    String targetType = 'EMPLOYEE',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Rak mouch connecté!');
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'salonId': salonId,
        'barberId': barberId,
        'targetType': targetType,
        'date': date,
        'time': time,
        'serviceIds': serviceIds,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Erreur création rdv');
    }
  }
}
