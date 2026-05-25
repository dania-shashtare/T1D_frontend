import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FamilyMealsApi {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/meals';
    } else {
      return 'http://10.0.2.2:5000/api/meals';
    }
  }

  static Future<Map<String, dynamic>> getMealReport({
    required String patientId,
    String filter = 'all',
  }) async {
    final url = Uri.parse('$baseUrl/$patientId?filter=$filter');

    print('MEALS URL: $url');

    final response = await http.get(url);

    print('MEALS STATUS: ${response.statusCode}');
    print('MEALS BODY: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to load meal report. Status: ${response.statusCode}, Body: ${response.body}',
    );
  }
}
