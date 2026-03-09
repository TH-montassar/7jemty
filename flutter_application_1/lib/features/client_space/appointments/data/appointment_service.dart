import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hjamty/config/api_config.dart';

class AppointmentService {
  static String get baseUrl => ApiConfig.endpoint('/api/appointment');

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

  static Future<List<dynamic>> getAppointmentsForSalonId(int salonId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Rak mouch connecté!');
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.endpoint('/api/admin')}/salons/$salonId/appointments',
      ),
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
        data['message'] ??
            'Erreur lors de la récupération des rendez-vous par l\'admin',
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
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception(data['message'] ?? 'Erreur availability');
    }
  }

  static Future<List<String>> getAvailableDates({
    required int salonId,
    required String startDate,
    required String endDate,
    int? barberId,
    List<int>? serviceIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final queryParams = {
      'salonId': salonId.toString(),
      'startDate': startDate,
      'endDate': endDate,
    };

    if (barberId != null) {
      queryParams['barberId'] = barberId.toString();
    }

    if (serviceIds != null && serviceIds.isNotEmpty) {
      queryParams['serviceIds'] = serviceIds.join(',');
    }

    final uri = Uri.parse(
      '$baseUrl/available-dates',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return List<String>.from(data['data'] ?? []);
    } else {
      throw Exception(data['message'] ?? 'Erreur available-dates');
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

  static Future<Map<String, dynamic>> extendAppointment({
    required int appointmentId,
    required int minutes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Rak mouch connecté!');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/$appointmentId/extend'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'minutes': minutes}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de l\'extension du temps',
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<List<dynamic>> getUnreviewedAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Rak mouch connecté!');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/unreviewed'),
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
        data['message'] ?? 'Erreur lors de la récupération des rdvs sans avis',
      );
    }
  }

  static Future<Map<String, dynamic>> submitReview({
    required int appointmentId,
    required int salonId,
    required int rating,
    String? comment,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Rak mouch connecté!');
      }

      final body = {
        'salonId': salonId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/$appointmentId/review'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de l\'envois de l\'avis',
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
