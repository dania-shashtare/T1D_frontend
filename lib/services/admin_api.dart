import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AdminApi {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/admin';
    }
    return 'http://10.0.2.2:5000/api/admin';
  }

  static String get fileBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/uploads';
    }
    return 'http://10.0.2.2:5000/uploads';
  }

  static Future<Map<String, dynamic>> getStats() async {
    final response = await http.get(Uri.parse('$baseUrl/stats'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load admin stats');
  }

  static Future<List<dynamic>> getPatients() async {
    final response = await http.get(Uri.parse('$baseUrl/patients'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['patients'] ?? [];
    }

    throw Exception('Failed to load patients');
  }

  static Future<List<dynamic>> getFamily() async {
    final response = await http.get(Uri.parse('$baseUrl/family'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['family'] ?? [];
    }

    throw Exception('Failed to load family');
  }

  static Future<List<dynamic>> getDoctors() async {
    final response = await http.get(Uri.parse('$baseUrl/doctors'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['doctors'] ?? [];
    }

    throw Exception('Failed to load doctors');
  }

  static Future<List<dynamic>> getNutritionists() async {
    final response = await http.get(Uri.parse('$baseUrl/nutritionists'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['nutritionists'] ?? [];
    }

    throw Exception('Failed to load nutritionists');
  }

  static Future<void> updateDoctorStatus({
    required String doctorProfileId,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/doctors/$doctorProfileId/verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update doctor status');
    }
  }

  static Future<void> updateNutritionistStatus({
    required String nutritionistProfileId,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/nutritionists/$nutritionistProfileId/verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update nutritionist status');
    }
  }
}
