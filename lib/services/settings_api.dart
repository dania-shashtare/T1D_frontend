import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SettingsApi {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else {
      return 'http://10.0.2.2:5000/api';
    }
  }

  static Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/users/change-password/$userId');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to change password');
    }
  }
}
