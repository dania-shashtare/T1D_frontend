import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/profile_model.dart';
import 'package:flutter/foundation.dart';

class ProfileApi {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/profile';
    } else {
      return 'http://10.0.2.2:5000/api/profile';
    }
  }

  static Future<ProfileModel> getProfile(String userId) async {
    final url = '$baseUrl/$userId';
    print('PROFILE URL: $url');

    final response = await http.get(Uri.parse(url));

    print('PROFILE STATUS: ${response.statusCode}');
    print('PROFILE BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProfileModel.fromJson(data);
    } else {
      throw Exception(
        'Failed to load profile. Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  static Future<void> updateProfile({
    required String userId,
    required double height,
    required double weight,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'height': height, 'weight': weight}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }
}
