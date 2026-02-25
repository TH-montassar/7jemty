import 'dart:convert';
import 'package:flutter/foundation.dart'; // 👈 Bech na3rfou kIsWeb
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 👈 Bech njibou l'Token

class SalonService {
  // 🧩 L'IP e-thkiya kima fel AuthService
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/salon';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/salon';
    } else {
      return 'http://localhost:3000/api/salon';
    }
  }

  // 📝 Fonction mta3 Creation l'Salon
  static Future<Map<String, dynamic>> createSalon({
    required String name,
    required String address,
  }) async {
    try {
      // 1. Njibou e-Token elli khabbineh wa9t l'Login
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      // Ken mal9inech token, ma3neha l'user mouch connecté
      if (token == null) {
        throw Exception('Rak mouch connecté! (Token manquant)');
      }

      // 2. Naba3thou l'Request lel backend m3a l'Token
      final response = await http.post(
        Uri.parse('$baseUrl/create'), // L'Lien mta3 l'API
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // 👈 E-S7OR HOUNI! L'pass mta3 l'Backend
        },
        body: jsonEncode({'name': name, 'address': address}),
      );

      final data = jsonDecode(response.body);

      // 201 ma3neha "Created" b naje7 fel Backend
      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la création du salon',
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 📝 Fonction bech nzidou info lil salon existant
  static Future<Map<String, dynamic>> updateSalonInfo({
    String? description,
    String? contactPhone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Rak mouch connecté! (Token manquant)');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (description != null) 'description': description,
          if (contactPhone != null) 'contactPhone': contactPhone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la mise à jour du salon',
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 📝 Fonction bech njibou l'salon mta3 Patron el connecté
  static Future<Map<String, dynamic>> getMySalon() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Rak mouch connecté! (Token manquant)');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/my-salon'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la récupération du salon',
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
