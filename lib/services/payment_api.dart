import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentApi {
  static const String baseUrl = 'http://10.0.2.2:5000/api/payments';

  static Future<Map<String, dynamic>> payAppointment({
    required String appointmentType, // doctor أو nutritionist
    required String appointmentId,
    String paymentMethod = 'demo_card',
  }) async {
    final url = Uri.parse('$baseUrl/$appointmentType/$appointmentId/pay');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'paymentMethod': paymentMethod}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Payment failed');
    }
  }
}
