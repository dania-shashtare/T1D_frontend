import 'dart:convert';
import 'package:http/http.dart' as http;

class AiReportApi {
  //static const String baseUrl = 'http://localhost:5000/api';
  static const String baseUrl = "http://10.0.2.2:5000";

  static Future<Map<String, dynamic>> analyzeReport({
    required Map<String, dynamic> report,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai-report/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'report': report}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['ai']);
    }

    throw Exception(data['message'] ?? 'Failed to generate AI report');
  }
}
