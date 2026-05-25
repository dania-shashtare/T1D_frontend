import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AppointmentReminderApi {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    return 'http://10.0.2.2:5000';
  }

  static Future<List<dynamic>> getPatientDoctorAppointments(
    String patientId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/api/doctor-appointments/patient/$patientId',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['appointments'] ?? [];
    }

    throw Exception('Failed to load patient doctor appointments');
  }

  static Future<List<dynamic>> getPatientNutritionistAppointments(
    String patientId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/api/nutritionist-appointments/patient/$patientId',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['appointments'] ?? [];
    }

    throw Exception('Failed to load patient nutritionist appointments');
  }

  static Future<List<dynamic>> getDoctorAppointments(String doctorId) async {
    final url = Uri.parse('$baseUrl/api/doctor-appointments/doctor/$doctorId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load doctor appointments');
  }

  static Future<List<dynamic>> getNutritionistAppointments(
    String nutritionistId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/api/nutritionist-appointments/nutritionist/$nutritionistId',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['appointments'] ?? [];
    }

    throw Exception('Failed to load nutritionist appointments');
  }
}
