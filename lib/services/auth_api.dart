import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AuthApi {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/auth';
    }

    return 'http://10.0.2.2:5000/api/auth';
  }

  static Future<Map<String, dynamic>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
    required DateTime birthDate,
  }) async {
    final url = Uri.parse('$baseUrl/signup');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'password': password,
        'role': role,
        'birthDate': birthDate.toIso8601String(),
      }),
    );

    print('SIGNUP URL: $url');
    print('SIGNUP STATUS: ${res.statusCode}');
    print('SIGNUP BODY: ${res.body}');

    if (res.body.trim().startsWith('<')) {
      throw Exception('Backend returned HTML instead of JSON');
    }

    final data = jsonDecode(res.body);

    if (res.statusCode == 201) {
      return data;
    }

    throw Exception(data['message'] ?? 'Signup failed');
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );

    print('LOGIN URL: $url');
    print('LOGIN STATUS: ${response.statusCode}');
    print('LOGIN BODY: ${response.body}');

    if (response.body.trim().startsWith('<')) {
      throw Exception('Backend returned HTML instead of JSON');
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Login failed');
  }

  static Future<Map<String, dynamic>> checkGoogleUser(String email) async {
    final url = Uri.parse('$baseUrl/check-google-user');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );

    print('CHECK GOOGLE URL: $url');
    print('CHECK GOOGLE STATUS: ${response.statusCode}');
    print('CHECK GOOGLE BODY: ${response.body}');

    if (response.body.trim().startsWith('<')) {
      throw Exception('Backend returned HTML instead of JSON');
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Failed to check user');
  }

  static Future<void> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/forgot-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );

    print('FORGOT URL: $url');
    print('FORGOT STATUS: ${response.statusCode}');
    print('FORGOT BODY: ${response.body}');

    if (response.body.trim().startsWith('<')) {
      throw Exception('Backend returned HTML instead of JSON');
    }

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to send reset code');
    }
  }

  static Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final url = Uri.parse('$baseUrl/verify-reset-code');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'code': code.trim()}),
    );

    print('VERIFY CODE URL: $url');
    print('VERIFY CODE STATUS: ${response.statusCode}');
    print('VERIFY CODE BODY: ${response.body}');

    if (response.body.trim().startsWith('<')) {
      throw Exception('Backend returned HTML instead of JSON');
    }

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Invalid code');
    }
  }

  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/reset-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      }),
    );

    print('RESET URL: $url');
    print('RESET STATUS: ${response.statusCode}');
    print('RESET BODY: ${response.body}');

    if (response.body.trim().startsWith('<')) {
      throw Exception('Backend returned HTML instead of JSON');
    }

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to reset password');
    }
  }
}
