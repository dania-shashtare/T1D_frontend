import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  // ✅ لو انتي بتشغلي Flutter Web على نفس الجهاز
  static const String baseUrl = "http://localhost:5000";

  // لو Android Emulator بدليها:
  // static const String baseUrl = "http://10.0.2.2:5000";
static Future<void> signup({
  required String firstName,
  required String lastName,
  required String email,
  required String password,
  required String role,
  required DateTime birthDate,
}) async {
  final url = Uri.parse("$baseUrl/api/auth/signup");

  final res = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "firstName": firstName.trim(),
      "lastName": lastName.trim(),
      "email": email.trim(),
      "password": password,
      "role": role,
      "birthDate": birthDate.toIso8601String(),
    }),
  );

  final data = jsonDecode(res.body);

  if (res.statusCode == 201) return;

  throw Exception(data["message"] ?? "Signup failed");
}
  static Future<Map<String, dynamic>> checkGoogleUser(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/check-google-user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.body.trim().startsWith('<')) {
      throw Exception('Backend returned HTML instead of JSON');
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to check user');
    }
  }
  static Future<Map<String, dynamic>> login({
  required String email,
  required String password,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email.trim(),
      'password': password,
    }),
  );

  if (response.body.trim().startsWith('<')) {
    throw Exception('Backend returned HTML instead of JSON');
  }

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data;
  } else {
    throw Exception(data['message'] ?? 'Login failed');
  }
}
static Future<void> forgotPassword(String email) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/auth/forgot-password'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email.trim()}),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode != 200) {
    throw Exception(data['message'] ?? 'Failed to send reset code');
  }
}
static Future<void> verifyResetCode({
  required String email,
  required String code,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/auth/verify-reset-code'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email.trim(),
      'code': code.trim(),
    }),
  );

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
  final response = await http.post(
    Uri.parse('$baseUrl/api/auth/reset-password'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email.trim(),
      'code': code.trim(),
      'newPassword': newPassword,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode != 200) {
    throw Exception(data['message'] ?? 'Failed to reset password');
  }
}
}
