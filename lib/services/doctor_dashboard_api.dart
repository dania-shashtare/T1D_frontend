import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DoctorDashboardApi {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/doctor-dashboard';
    }
    return 'http://10.0.2.2:5000/api/doctor-dashboard';
  }

  static String get appointmentBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/doctor-appointments';
    }
    return 'http://10.0.2.2:5000/api/doctor-appointments';
  }

  static Future<Map<String, dynamic>> getDoctorProfile(String doctorId) async {
    final url = Uri.parse('$baseUrl/profile/$doctorId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to load doctor profile. Status: ${response.statusCode}, Body: ${response.body}',
    );
  }

  static Future<List<dynamic>> getDoctorAppointments(String doctorId) async {
    final url = Uri.parse('$appointmentBaseUrl/doctor/$doctorId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to load doctor appointments. Status: ${response.statusCode}, Body: ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> getPatientStatus(String doctorId) async {
    final url = Uri.parse('$baseUrl/patient-status/$doctorId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to load patient status. Status: ${response.statusCode}, Body: ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> getPatientDetails(
    String patientId,
  ) async {
    final url = Uri.parse('$baseUrl/patient-details/$patientId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to load patient details. Status: ${response.statusCode}, Body: ${response.body}',
    );
  }

  static Future<void> updateDoctorProfile({
    required String doctorId,
    required String fullName,
    required String specialty,
    required String workplace,
    required int yearsOfExperience,
    required String treatsType1,
    required bool ageChildren,
    required bool ageAdolescents,
    required bool ageAdults,
    required bool ageAllAges,
  }) async {
    final url = Uri.parse('$baseUrl/profile/$doctorId');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'specialty': specialty,
        'workplace': workplace,
        'yearsOfExperience': yearsOfExperience,
        'treatsType1': treatsType1,
        'ageChildren': ageChildren,
        'ageAdolescents': ageAdolescents,
        'ageAdults': ageAdults,
        'ageAllAges': ageAllAges,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update doctor profile');
    }
  }

  static Future<void> updatePatientMedicalParams({
    required String patientId,
    required String carbRatio,
    required String correctionFactor,
    required double lantusDose,
    required String lantusTime,
    required double weight,
    required double height,
    required bool hasFoodAllergy,
    required String allergyDetails,
  }) async {
    final url = Uri.parse('$baseUrl/patient-details/$patientId');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'carbRatio': carbRatio,
        'correctionFactor': correctionFactor,
        'lantusDose': lantusDose,
        'lantusTime': lantusTime,
        'weight': weight,
        'height': height,
        'hasFoodAllergy': hasFoodAllergy,
        'allergyDetails': allergyDetails,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(
        data['message'] ?? 'Failed to update patient medical parameters',
      );
    }
  }

  static Future<Map<String, dynamic>> getPatientTrend(String patientId) async {
    final url = Uri.parse('$baseUrl/patient-trend/$patientId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to load patient trend. Status: ${response.statusCode}, Body: ${response.body}',
    );
  }

  static Future<String> getPatientAiSuggestion({
    required String patientName,
    required dynamic age,
    required List<Map<String, dynamic>> readings,
    required String trend,
    required int riskScore,
    required Map<String, double> timeInRange,
    required String carbRatio,
    required String correctionFactor,
    required dynamic lantusDose,
    required String lantusTime,
    required dynamic weight,
    required dynamic height,
  }) async {
    final url = Uri.parse('$baseUrl/patient-ai-suggestion');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'patientName': patientName,
        'age': age,
        'readings': readings,
        'trend': trend,
        'riskScore': riskScore,
        'timeInRange': timeInRange,
        'carbRatio': carbRatio,
        'correctionFactor': correctionFactor,
        'lantusDose': lantusDose,
        'lantusTime': lantusTime,
        'weight': weight,
        'height': height,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['suggestion']?.toString() ?? 'No AI suggestion generated.';
    }

    final data = jsonDecode(response.body);
    throw Exception(data['message'] ?? 'Failed to generate AI suggestion');
  }
}
