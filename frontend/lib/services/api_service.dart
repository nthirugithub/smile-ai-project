import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../services/session_service.dart';
class ApiService {

  // -----------------------------------
  // BASE URL
  // -----------------------------------

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000';
    } else {
      return 'http://192.168.43.151:5000';
    }
  }


  static Future<Map<String, String>> _authHeaders() async {

    final token =
    await SessionService.getAccessToken();

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // -----------------------------------
  // ANALYZE SMILE
  // -----------------------------------

  static Future<Map<String, dynamic>>
  analyzeSmile(
      Uint8List imageBytes,
      String fileName,
      int userId,
      ) async {

    try {

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict'),
      );
      final token = await SessionService.getAccessToken();

      request.headers['Authorization'] =
      'Bearer $token';


      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
          contentType: http.MediaType('image', 'png'),
        ),
      );

      request.headers['Accept'] =
      'application/json';

      var response =
      await request.send().timeout(
        const Duration(seconds: 60),
      );

      var responseData =
      await response.stream.bytesToString();

      final decodedData =
      jsonDecode(responseData);

      if (response.statusCode == 200) {

        return {
          'success': true,
          'data': decodedData,
        };
      }

      return {
        'success': false,
        'error':
        decodedData['error'] ??
            'Unknown server error',
      };

    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // -----------------------------------
  // REGISTER USER
  // -----------------------------------

  static Future<Map<String, dynamic>>
  registerUser({
    required String name,
    required String email,
    required String password,
  }) async {

    try {

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type':
          'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 4));

      return jsonDecode(response.body);

    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  // -----------------------------------
  // LOGIN USER
  // -----------------------------------

  static Future<Map<String, dynamic>>
  loginUser({
    required String email,
    required String password,
  }) async {

    try {

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type':
          'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 4));

      return jsonDecode(response.body);

    } catch (e) {

      return {
        'success': false,
        'error': 'Invalid credentials provided. Access denied.',
      };
    }
  }
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {

    try {

      final response = await http.post(

        Uri.parse('$baseUrl/forgot-password'),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({
          'email': email,
        }),

      );

      return jsonDecode(response.body);

    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
      };

    }

  }
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {

    try {

      final response = await http.post(

        Uri.parse('$baseUrl/verify-otp'),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({

          'email': email,
          'otp': otp,

        }),

      );

      return jsonDecode(response.body);

    } catch (e) {

      return {

        'success': false,
        'error': e.toString(),

      };

    }

  }
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {

    try {

      final response = await http.post(

        Uri.parse('$baseUrl/reset-password'),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({

          'email': email,
          'new_password': newPassword,

        }),

      );

      return jsonDecode(response.body);

    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
      };

    }

  }
  // -----------------------------------
// GET PROFILE
// -----------------------------------

  static Future<Map<String, dynamic>> getProfile(
      int userId,
      ) async {

    try {

      final response = await http.get(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: await _authHeaders(),
      );

      return jsonDecode(response.body);

    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
      };

    }

  }
// -----------------------------------
// UPDATE PROFILE
// -----------------------------------

  static Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String name,
    required String phone,
    required String clinic,
    required String registrationNumber,
    required String specialization,
    required int experience,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'clinic': clinic,
          'registration_number': registrationNumber,
          'specialization': specialization,
          'experience': experience,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  // -----------------------------------
// GET SETTINGS
// -----------------------------------

  static Future<Map<String, dynamic>> getSettings(
      int userId,
      ) async {

    try {

      final response = await http.get(
        Uri.parse('$baseUrl/settings/$userId'),
        headers: await _authHeaders(),
      );

      return jsonDecode(response.body);

    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
      };

    }
  }

// -----------------------------------
// UPDATE SETTINGS
// -----------------------------------

  static Future<Map<String, dynamic>> updateSettings({
    required int userId,
    required bool emailNotifications,
    required bool autoBackupReports,
    required String theme,
  }) async {

    try {

      final response = await http.put(

        Uri.parse('$baseUrl/settings/$userId'),

        headers: await _authHeaders(),

        body: jsonEncode({

          'email_notifications':
          emailNotifications,

          'auto_backup_reports':
          autoBackupReports,

          'theme':
          theme,

        }),
      );

      return jsonDecode(response.body);

    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
      };

    }
  }
  static Future<Map<String, dynamic>> getReports({
    required int userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports?user_id=$userId'),
        headers: await _authHeaders(),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  static Future<Map<String, dynamic>> getReportById(int reportId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/$reportId'),
        headers: await _authHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        return data["report"];
      }

      throw Exception(data["error"] ?? "Failed to load report");
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  static Future<List<dynamic>> searchPatients(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/search-patients?q=${Uri.encodeComponent(query)}',
        ),
        headers: await _authHeaders(),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        return data["patients"] ?? [];
      }

      return [];
    } catch (e) {
      return [];
    }
  }
  static Future<bool> markReportReviewed(int reportId) async {

    try {

      final headers = await _authHeaders();

      final response = await http.put(
        Uri.parse(
          '$baseUrl/reports/$reportId/review',
        ),
        headers: headers,
      );


      final data = jsonDecode(
        response.body,
      );


      return data['success'] == true;


    } catch (e) {

      print(
        "Mark reviewed error: $e",
      );

      return false;

    }
  }
  // -----------------------------------
// GET NOTIFICATIONS
// -----------------------------------

  static Future<Map<String, dynamic>> getNotifications({
    required int userId,
  }) async {

    try {

      final response = await http.get(
        Uri.parse('$baseUrl/notifications?user_id=$userId'),
        headers: await _authHeaders(),
      );

      return jsonDecode(response.body);

    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
      };

    }

  }
  // -----------------------------------
// MARK NOTIFICATIONS AS READ
// -----------------------------------

  static Future<Map<String, dynamic>> markNotificationsAsRead({
    required int userId,
  }) async {

    try {

      final response = await http.put(

        Uri.parse('$baseUrl/notifications/read'),

        headers: await _authHeaders(),

        body: jsonEncode({
          'user_id': userId,
        }),

      );

      return jsonDecode(response.body);

    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
      };

    }

  }
  // -----------------------------------
// CHANGE PASSWORD
// -----------------------------------

  static Future<Map<String, dynamic>> changePassword({

    required int userId,
    required String currentPassword,
    required String newPassword,

  }) async {

    try {

      final response = await http.put(

        Uri.parse(
          '$baseUrl/change-password/$userId',
        ),

        headers: await _authHeaders(),

        body: jsonEncode({

          'current_password': currentPassword,
          'new_password': newPassword,

        }),
      );

      return jsonDecode(response.body);

    } catch (e) {

      return {

        'success': false,
        'error': e.toString(),

      };

    }

  }
}



