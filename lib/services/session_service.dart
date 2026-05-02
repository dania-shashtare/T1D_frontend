import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _userIdKey = 'userId';
  static const String _roleKey = 'role';

  static Future<void> saveUserSession({
    required String userId,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_userIdKey, userId);

    if (role != null) {
      await prefs.setString(_roleKey, role);
    }
  }

  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);

    if (userId == null || userId.trim().isEmpty) {
      throw Exception('User ID not found. Please login again.');
    }

    return userId.trim();
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_roleKey);
  }
}