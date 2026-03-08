import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 👈 Bech njibou l'Token

import 'package:hjamty/config/api_config.dart';

class SalonService {
  // 🧩 L'IP e-thkiya kima fel AuthService
  static String get baseUrl => ApiConfig.endpoint('/api/salon');

  static Future<Map<String, dynamic>> createSalon({
    required String name,
    required String address,
    String? googleMapsUrl,
    String? speciality,
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
        body: jsonEncode({
          'name': name,
          'address': address,
          if (googleMapsUrl != null && googleMapsUrl.isNotEmpty)
            'googleMapsUrl': googleMapsUrl,
          if (speciality != null && speciality.isNotEmpty)
            'speciality': speciality,
        }),
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

  static Future<Map<String, dynamic>> updateSalonInfo({
    int? salonId,
    String? name,
    String? description,
    String? contactPhone,
    String? address,
    double? latitude,
    double? longitude,
    String? googleMapsUrl,
    String? websiteUrl,
    String? coverImageUrl,
    String? speciality,
    List<Map<String, String>>? socialLinks,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Rak mouch connecté! (Token manquant)');
      }

      final body = <String, dynamic>{};
      if (name != null && name.isNotEmpty) body['name'] = name;
      if (description != null) body['description'] = description;
      if (contactPhone != null) body['contactPhone'] = contactPhone;
      if (address != null && address.isNotEmpty) body['address'] = address;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (googleMapsUrl != null) body['googleMapsUrl'] = googleMapsUrl;
      if (websiteUrl != null) body['websiteUrl'] = websiteUrl;
      if (coverImageUrl != null) body['coverImageUrl'] = coverImageUrl;
      if (speciality != null) body['speciality'] = speciality;
      if (socialLinks != null) body['socialLinks'] = socialLinks;

      final url = salonId != null
          ? ApiConfig.endpoint('/api/admin/salons/$salonId') // Use Admin Route
          : '$baseUrl/update'; // Use Patron Route

      final response = await (salonId != null ? http.patch : http.put)(
        Uri.parse(url),
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

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la récupération du salon',
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 📝 Fonction bech tzid employé we ta3melou compte User
  static Future<Map<String, dynamic>> createEmployeeAccount({
    int? salonId,
    required String name,
    required String phoneNumber,
    required String password,
    String? role,
    String? bio,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Rak mouch connecté! (Token manquant)');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/employee/create-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (salonId != null) 'salonId': salonId,
          'name': name,
          'phoneNumber': phoneNumber,
          'password': password,
          if (role != null && role.isNotEmpty) 'role': role,
          if (bio != null && bio.isNotEmpty) 'bio': bio,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la création du compte employé',
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 📝 Fonction bech njibou e-salons lkol w nrajjouhom lel client
  static Future<List<dynamic>> getAllSalons({double? lat, double? lng}) async {
    try {
      final String query = (lat != null && lng != null)
          ? '?lat=$lat&lng=$lng'
          : '';

      final response = await http.get(
        Uri.parse('$baseUrl/all$query'),
        headers: {'Content-Type': 'application/json'},
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
      throw Exception('Erreur de connexion: $e');
    }
  }

  // 📝 Fonction bech tzid service l salon
  static Future<Map<String, dynamic>> createService({
    int? salonId,
    required String name,
    required double price,
    required int durationMinutes,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Rak mouch connecté! (Token manquant)');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/service/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (salonId != null) 'salonId': salonId,
          'name': name,
          'price': price,
          'durationMinutes': durationMinutes,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la création du service',
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 📝 Fonction bech njibou les services mta3 salon
  static Future<List<dynamic>> getServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Rak mouch connecté! (Token manquant)');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/service/list'),
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
          data['message'] ?? 'Erreur lors de la récupération des services',
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 📝 Fonction bech njibou e-salons ta7it Top Rating (A7sen salonat)
  static Future<List<dynamic>> getTopRatedSalons() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/top-rated'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(
          data['message'] ??
              'Erreur lors de la récupération des salons bien notés',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // 📝 Fonction bech njibou les services mta3 patron el connecté
  static Future<List<dynamic>> getMyServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Rak mouch connecté! (Token manquant)');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/services'),
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
          data['message'] ?? 'Erreur lors de la récupération des services',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // 📝 Fonction bech nzidou service l'salon

  // 📝 Fonction bech njibou détail mta3 salon wa7ed b id mta3o
  static Future<Map<String, dynamic>> getSalonById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final salonData = data['data'] as Map<String, dynamic>;
        final reviews = salonData['reviews'];
        debugPrint(
          '[SalonService.getSalonById] id=$id, reviews type: ${reviews.runtimeType}, count: ${reviews is List ? reviews.length : "N/A"}',
        );
        return salonData;
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la récupération du salon',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // 📝 Fonction bech nlawjou 3la salonat (Recherche)
  static Future<List<dynamic>> searchSalons(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search?q=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la recherche');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
