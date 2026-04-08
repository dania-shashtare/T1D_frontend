import 'dart:convert';
import 'package:http/http.dart' as http;
import '../food_product.dart';

class OpenFoodFactsService {
  static Future<FoodProduct?> getProductByBarcode(String barcode) async {
    final url = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode?fields=product_name,image_url,serving_size,nutriments',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 1) {
        return FoodProduct.fromJson(data);
      }
    }

    return null;
  }
}
