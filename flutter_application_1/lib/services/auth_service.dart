import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AuthService {
  static String get baseUrl {
    if (kIsWeb) {
      // كان تخدم على Chrome (Web)
      return 'http://localhost:3000/api/auth';
    } else if (Platform.isAndroid) {
      // كان تخدم على Android Emulator
      return 'http://10.0.2.2:3000/api/auth';
    } else {
      // كان تخدم على iOS Simulator
      return 'http://localhost:3000/api/auth';
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String phoneNumber,
    required String password,
    String role = 'CLIENT', // ديما نحطوه CLIENT بار ديفو
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'password': password,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // الأمور 5/5
        return data;
      } else {
        // الـ Zod ولا الـ Service رجعو Error (مثلا النومرو مستعمل)
        throw Exception(data['message'] ?? '8alta fi tsjil');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // الأمور واضحة والـ Login تم بنجاح
        return data;
      } else {
        // الـ Backend رجع Error (mot de passe ghalet / user mouch mawjoud)
        throw Exception(data['message'] ?? 'Erreur lors de la connexion');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
