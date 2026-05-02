import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/profile_model.dart';

class ProfileApi {
  static const String baseUrl = 'http://localhost:5000/api/profile';
  // إذا Android emulator:
  // static const String baseUrl = 'http://10.0.2.2:5000/api/profile';

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
}