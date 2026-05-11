import 'dart:convert';
import 'package:http/http.dart' as http;

class GlucoseApi {
  // static const String baseUrl = 'http://localhost:5000/api/glucose';

  // If you run on Android Emulator, use this instead:
  static const String baseUrl = 'http://10.0.2.2:5000/api/glucose';

  static Future<List<Map<String, dynamic>>> getReadings(String userId) async {
    final url = Uri.parse('$baseUrl/$userId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception(
      'Failed to fetch readings. Status: ${response.statusCode}, Body: ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> addReading({
    required String userId,
    required double value,
    required DateTime readingTime,
    String readingType = 'random',
    String source = 'manual',
    String note = '',
  }) async {
    final url = Uri.parse(baseUrl);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'value': value,
        'readingTime': readingTime.toIso8601String(),
        'readingType': readingType,
        'source': source,
        'note': note,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)['reading'];
    }

    throw Exception(
      'Failed to save reading. Status: ${response.statusCode}, Body: ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> getReadingById(String readingId) async {
    final url = Uri.parse('$baseUrl/reading/$readingId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to fetch reading. Status: ${response.statusCode}, Body: ${response.body}',
    );
  }

  static Future<List<Map<String, dynamic>>> getLowTreatmentSuggestions({
    required int carbsNeeded,
    required double weight,
  }) async {
    final url = Uri.parse('$baseUrl/low-treatment/suggestions');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'carbsNeeded': carbsNeeded, 'weight': weight}),
    );

    print('LOW AI SUGGESTIONS URL: $url');
    print('LOW AI SUGGESTIONS STATUS: ${response.statusCode}');
    print('LOW AI SUGGESTIONS BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List suggestions = data['suggestions'] ?? [];

      return suggestions.map<Map<String, dynamic>>((item) {
        return {
          'title': item['title'] ?? '',
          'amount': item['amount'] ?? item['subtitle'] ?? '',
          'carbs': item['carbs'] ?? carbsNeeded,
          'image_query':
              item['image_query'] ?? item['imageQuery'] ?? item['title'] ?? '',
        };
      }).toList();
    }

    throw Exception(
      'Failed to get low treatment suggestions. Status: ${response.statusCode}, Body: ${response.body}',
    );
  }

  static Future<Map<String, dynamic>> saveLowTreatment({
    required String readingId,
    required String type,
    String? presetKey,
    required String title,
    required String subtitle,
    String? customText,
    required bool reminderEnabled,
    required int carbsNeeded,
    required int selectedCarbs,
    String? imageUrl,
    String? imageQuery,
  }) async {
    final url = Uri.parse('$baseUrl/$readingId/low-treatment');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': type,
        'presetKey': presetKey,
        'title': title,
        'subtitle': subtitle,
        'customText': customText ?? '',
        'reminderEnabled': reminderEnabled,
        'carbsNeeded': carbsNeeded,
        'selectedCarbs': selectedCarbs,
        'imageUrl': imageUrl ?? '',
        'imageQuery': imageQuery ?? '',
      }),
    );

    print('SAVE LOW TREATMENT URL: $url');
    print('SAVE LOW TREATMENT STATUS: ${response.statusCode}');
    print('SAVE LOW TREATMENT BODY: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['reading'];
    }

    throw Exception(
      'Failed to save low treatment. Status: ${response.statusCode}, Body: ${response.body}',
    );
  }
}
