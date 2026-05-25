import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FamilyApi {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/family';
    } else {
      return 'http://10.0.2.2:5000/api/family';
    }
  }

  static Future<Map<String, dynamic>> getFamilyProfile(String userId) async {
    final url = Uri.parse('$baseUrl/profile/$userId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to get family profile');
  }

  static Future<Map<String, dynamic>> updateFamilyProfile({
    required String userId,
    required String parentName,
    required String relationship,
    required String phone,
  }) async {
    final url = Uri.parse('$baseUrl/profile/$userId');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'parentName': parentName,
        'relationship': relationship,
        'phone': phone,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to update family profile: ${response.body}');
  }

  static Future<List<dynamic>> getFamiliesByPatient(String patientId) async {
    final url = Uri.parse('$baseUrl/by-patient/$patientId');

    print('GET FAMILIES BY PATIENT URL: $url');

    final response = await http.get(url);

    print('GET FAMILIES BY PATIENT STATUS: ${response.statusCode}');
    print('GET FAMILIES BY PATIENT BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['families'] ?? [];
    }

    throw Exception(
      'Failed to get families by patient. Status: ${response.statusCode}, Body: ${response.body}',
    );
  }

  static Future<void> saveFcmToken({
    required String userId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/save-fcm-token');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'token': token}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save FCM token: ${response.body}');
    }
  }

  static Future<void> notifyFamilyGlucose({
    required String patientId,
    required double glucoseValue,
  }) async {
    final url = Uri.parse('$baseUrl/notify-glucose');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'patientId': patientId, 'glucoseValue': glucoseValue}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to notify family: ${response.body}');
    }
  }

  static Future<void> notifyFamilyLantusMissed({
    required String patientId,
    required String scheduledTime,
  }) async {
    final url = Uri.parse('$baseUrl/notify-lantus-missed');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'patientId': patientId,
        'scheduledTime': scheduledTime,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to notify family about missed Lantus: ${response.body}',
      );
    }
  }
}
