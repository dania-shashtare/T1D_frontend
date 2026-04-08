class FoodProduct {
  final String name;
  final double carbsPer100g;
  final double? carbsPerServing;
  final String? imageUrl;
  final String? servingSize;

  FoodProduct({
    required this.name,
    required this.carbsPer100g,
    this.carbsPerServing,
    this.imageUrl,
    this.servingSize,
  });

  factory FoodProduct.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final nutriments = product['nutriments'] ?? {};

    return FoodProduct(
      name: product['product_name'] ?? 'Unknown Product',
      carbsPer100g: _toDouble(nutriments['carbohydrates_100g']),
      carbsPerServing: _nullableDouble(nutriments['carbohydrates_serving']),
      imageUrl: product['image_url'],
      servingSize: product['serving_size'],
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }
}
