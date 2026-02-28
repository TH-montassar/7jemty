import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';

class ProgressMultipartRequest extends http.MultipartRequest {
  final void Function(int bytes, int total) onProgress;

  ProgressMultipartRequest(String method, Uri url, {required this.onProgress})
    : super(method, url);

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    int bytes = 0;

    return http.ByteStream(
      byteStream.map((chunk) {
        bytes += chunk.length;
        onProgress(bytes, total);
        return chunk;
      }),
    );
  }
}

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

  static Future<Map<String, dynamic>> getMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data; // returns { success: true, data: user }
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la récupération du profil',
        );
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (fullName != null) 'fullName': fullName,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          if (email != null) 'email': email,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          if (bio != null) 'bio': bio,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Erreur lors de la mise à jour du profil',
        );
      }
    } catch (e) {
      throw Exception(e.toString());
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

  static Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
    required void Function(double progress) onProgress,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('No token found');
      }

      final uri = Uri.parse(baseUrl.replaceFirst('/auth', '/upload'));
      final request = ProgressMultipartRequest(
        'POST',
        uri,
        onProgress: (bytes, total) {
          final progress = bytes / total;
          onProgress(progress);
        },
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['url'] as String;
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de l\'upload');
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }
}
