import 'dart:convert';
import 'package:http/http.dart' as http;

class MealReportApi {
  static const String baseUrl = 'http://localhost:5000/api/meal-reports';

  // Android emulator:
   //static const String baseUrl = 'http://10.0.2.2:5000/api/meal-reports';

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
