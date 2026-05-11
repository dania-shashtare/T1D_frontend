import 'dart:convert';
import 'package:http/http.dart' as http;

class NutritionistAppointmentApi {
  static const String baseUrl =
      'http://10.0.2.2:5000/api/nutritionist-appointments';

  static Future<Map<String, dynamic>> getActiveAppointment(
    String patientId,
  ) async {
    final url = Uri.parse('$baseUrl/active/$patientId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to get active appointment');
  }

  static Future<List<dynamic>> getNutritionists() async {
    final url = Uri.parse('$baseUrl/nutritionists');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to get nutritionists');
  }

  static Future<List<dynamic>> getAvailability({
    required String nutritionistId,
    required String visitType,
  }) async {
    final url = Uri.parse(
      '$baseUrl/availability/$nutritionistId?visitType=$visitType',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to get availability');
  }

  static Future<void> cancelAppointment(String appointmentId) async {
    final url = Uri.parse('$baseUrl/$appointmentId');

    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel appointment');
    }
  }

  static Future<void> updateAppointment({
    required String appointmentId,
    required String visitType,
    required String day,
    required String time,
  }) async {
    final url = Uri.parse('$baseUrl/$appointmentId');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'visitType': visitType, 'day': day, 'time': time}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update appointment');
    }
  }

  static Future<void> bookAppointment({
    required String patientId,
    required String nutritionistId,
    required String visitType,
    required String day,
    required String time,
  }) async {
    final url = Uri.parse(baseUrl);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'patientId': patientId,
        'nutritionistId': nutritionistId,
        'visitType': visitType,
        'day': day,
        'time': time,
      }),
    );

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to book appointment');
    }
  }
}
