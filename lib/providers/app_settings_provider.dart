import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  bool _darkMode = false;
  String _language = 'en';

  bool get darkMode => _darkMode;
  String get language => _language;

  ThemeMode get themeMode {
    return _darkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _darkMode = prefs.getBool('darkMode') ?? false;
    _language = prefs.getString('language') ?? 'en';

    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);

    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);

    notifyListeners();
  }
}
