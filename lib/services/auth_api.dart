import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  static const String baseUrl = "http://localhost:5000";
  // static const String baseUrl = "http://10.0.2.2:5000";

  static Future<Map<String, dynamic>> signup({
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

    if (res.statusCode == 201) {
      return data;
    }

    throw Exception(data["message"] ?? "Signup failed");
  }
}
