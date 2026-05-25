import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WaterApi {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/water';
    } else {
      return 'http://10.0.2.2:5000/api/water';
    }
  }

  static Future<Map<String, dynamic>> getTodayWater(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/$userId/today'));

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addWater({
    required String userId,
    required int amountMl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'amountMl': amountMl}),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    return jsonDecode(response.body);
  }
}
