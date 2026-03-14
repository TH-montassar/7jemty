import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hjamty/config/api_config.dart';

class AdminService {
  static String get baseUrl => ApiConfig.endpoint('/api/admin');

  static Future<List<dynamic>> getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la récupération des utilisateurs',
        );
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<void> deleteUser(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<void> updateUser(
    int id, {
    String? fullName,
    String? phoneNumber,
    String? role,
    bool? isVerified,
    bool? isBlacklistedBySystem,
    Map<String, dynamic>? profile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.patch(
        Uri.parse('$baseUrl/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (fullName != null) 'fullName': fullName,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          if (role != null) 'role': role,
          if (isVerified != null) 'isVerified': isVerified,
          if (isBlacklistedBySystem != null)
            'isBlacklistedBySystem': isBlacklistedBySystem,
          if (profile != null) 'profile': profile,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<void> updateSalon(
    int id,
    Map<String, dynamic> salonData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.patch(
        Uri.parse('$baseUrl/salons/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(salonData),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<List<dynamic>> getAllSalons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('$baseUrl/salons'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la récupération des salons',
        );
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<void> updateSalonStatus(int id, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.patch(
        Uri.parse('$baseUrl/salons/$id/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<void> deleteSalon(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.delete(
        Uri.parse('$baseUrl/salons/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<Map<String, dynamic>> getSalonStats(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('$baseUrl/salons/$id/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la récupération des statistiques',
        );
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<List<dynamic>> getReviewReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse(ApiConfig.endpoint('/api/review/reports')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      }
      throw Exception(data['message'] ?? 'Erreur chargement signalements');
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<void> resolveReviewReport(
    int reportId, {
    required String action,
    String? adminNote,
    bool warnUser = false,
    bool banUser = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final endpoint = action == 'DISMISS'
          ? ApiConfig.endpoint('/api/review/reports/$reportId/dismiss')
          : ApiConfig.endpoint('/api/review/reports/$reportId/action');

      final response = await http.patch(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (adminNote != null && adminNote.isNotEmpty) 'adminNote': adminNote,
          'warnUser': warnUser,
          'banUser': banUser,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Erreur résolution signalement');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }
}
