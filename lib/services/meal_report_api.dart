import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MealReportApi {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/meal-reports';
    }

    return 'http://10.0.2.2:5000/api/meal-reports';
  }

  static Future<Map<String, dynamic>> getMealReport({
    required String userId,
    required String filter,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$userId?filter=$filter'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['error'] ?? data['message'] ?? 'Failed to load meal report',
      );
    }

    return data;
  }
}
