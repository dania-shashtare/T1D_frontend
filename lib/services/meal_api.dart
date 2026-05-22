import 'dart:convert';
import 'package:http/http.dart' as http;

class MealApi {
  //static const String baseUrl = 'http://localhost:5000/api/meals';
   static const String baseUrl = 'http://10.0.2.2:5000/api/meals';

  static Future<Map<String, dynamic>> calculateMeal({
    required String userId,
    required String mealType,
    required String mealName,
    required String servingSize,
    required List<Map<String, dynamic>> ingredients,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/calculate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'mealType': mealType,
        'mealName': mealName,
        'servingSize': servingSize,
        'ingredients': ingredients,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to calculate meal');
    }

    return data;
  }

  static Future<Map<String, dynamic>> saveMeal({
    required String userId,
    required Map<String, dynamic> meal,
  }) async {
    final body = {
      'userId': userId,
      'mealType': meal['mealType'],
      'mealName': meal['mealName'],
      'servingSize': meal['servingSize'] ?? '',
      'ingredients': meal['ingredients'] ?? [],
      'totalCarbs': meal['totalCarbs'],
      'carbRatio': meal['carbRatio'],
      'insulinUnits': meal['insulinUnits'],
      'insulinMessage': meal['insulinMessage'] ?? '',
    };

    print('SAVE MEAL BODY: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print('SAVE MEAL STATUS: ${response.statusCode}');
    print('SAVE MEAL RESPONSE: ${response.body}');

    Map<String, dynamic> data = {};

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid server response: ${response.body}');
    }

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        data['error'] ?? data['message'] ?? 'Failed to save meal',
      );
    }

    return data;
  }

  static Future<List<dynamic>> getSavedMeals({
    required String userId,
    required String mealType,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$userId?mealType=$mealType'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['error'] ?? data['message'] ?? 'Failed to load meals',
      );
    }

    return data['meals'] ?? [];
  }

  static Future<void> deleteMeal(String mealId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$mealId'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to delete meal');
    }
  }
}
