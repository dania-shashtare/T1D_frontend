import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class DoctorAppointmentApi {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/doctor-appointments';
    }
    return 'http://10.0.2.2:5000/api/doctor-appointments';
  }

  static Future<Map<String, dynamic>> getActiveAppointment(
    String patientId,
  ) async {
    final url = Uri.parse('$baseUrl/active/$patientId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to get active doctor appointment');
  }

  static Future<List<dynamic>> getDoctors() async {
    final url = Uri.parse('$baseUrl/doctors');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to get doctors');
  }

  static Future<List<dynamic>> getAvailability({
    required String doctorId,
    required String visitType,
  }) async {
    final url = Uri.parse(
      '$baseUrl/availability/$doctorId?visitType=$visitType',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to get doctor availability');
  }

  static Future<void> bookAppointment({
    required String patientId,
    required String doctorId,
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
        'doctorId': doctorId,
        'visitType': visitType,
        'day': day,
        'time': time,
      }),
    );

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to book doctor appointment');
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
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update doctor appointment');
    }
  }

  static Future<void> cancelAppointment(String appointmentId) async {
    final url = Uri.parse('$baseUrl/$appointmentId');

    final response = await http.delete(url);

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to cancel doctor appointment');
    }
  }

  static Future<void> addAvailability({
    required String doctorId,
    required String visitType,
    required String day,
    required String startTime,
    required String endTime,
    required List<String> slots,
  }) async {
    final url = Uri.parse('$baseUrl/availability');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'doctorId': doctorId,
        'visitType': visitType,
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'slots': slots,
      }),
    );

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to add availability');
    }
  }

  static Future<List<dynamic>> getAllAvailability(String doctorId) async {
    final url = Uri.parse('$baseUrl/availability-all/$doctorId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to get all doctor availability');
  }

  static Future<void> updateAvailability({
    required String availabilityId,
    required String visitType,
    required String day,
    required String startTime,
    required String endTime,
    required List<String> slots,
  }) async {
    final url = Uri.parse('$baseUrl/availability/$availabilityId');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'visitType': visitType,
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'slots': slots,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update availability');
    }
  }

  static Future<void> deleteAvailability(String availabilityId) async {
    final url = Uri.parse('$baseUrl/availability/$availabilityId');

    final response = await http.delete(url);

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete availability');
    }
  }
}
