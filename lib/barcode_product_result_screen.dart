import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'food_product.dart';
import 'services/meal_api.dart';

class BarcodeProductResultScreen extends StatefulWidget {
  final String mealTitle;
  final FoodProduct product;
  final double? carbRatio;

  const BarcodeProductResultScreen({
    super.key,
    required this.mealTitle,
    required this.product,
    this.carbRatio,
  });

  @override
  State<BarcodeProductResultScreen> createState() =>
      _BarcodeProductResultScreenState();
}

class _BarcodeProductResultScreenState
    extends State<BarcodeProductResultScreen> {
  final TextEditingController gramsController = TextEditingController();

  double totalCarbs = 0.0;
  int? suggestedInsulin;
  double enteredGrams = 0.0;
  bool hasCalculated = false;
  bool isSaving = false;

  @override
  void dispose() {
    gramsController.dispose();
    super.dispose();
  }

  String _mealTypeFromTitle(String mealTitle) {
    switch (mealTitle) {
      case 'Breakfast':
        return 'breakfast';
      case 'Morning Snack':
        return 'morningSnack';
      case 'Lunch':
        return 'lunch';
      case 'Afternoon Snack':
        return 'eveningSnack';
      case 'Dinner':
        return 'dinner';
      default:
        return 'breakfast';
    }
  }

  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null || userId.trim().isEmpty) {
      throw Exception('User ID not found. Please login again.');
    }

    return userId.trim();
  }

  void calculateValues() {
    final grams = double.tryParse(gramsController.text.trim()) ?? 0.0;

    if (grams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount in grams.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      hasCalculated = true;
      enteredGrams = grams;
      totalCarbs = (widget.product.carbsPer100g * grams) / 100;

      if (widget.carbRatio != null && widget.carbRatio! > 0) {
        suggestedInsulin = (totalCarbs / widget.carbRatio!).round();
      } else {
        suggestedInsulin = null;
      }
    });
  }

  Future<void> _saveBarcodeMeal() async {
    if (!hasCalculated || enteredGrams <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calculate the meal first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final userId = await _getCurrentUserId();
      final mealType = _mealTypeFromTitle(widget.mealTitle);

      final meal = {
        'mealType': mealType,
        'mealName': widget.product.name,
        'servingSize': '${enteredGrams.toStringAsFixed(0)}g',
        'ingredients': [
          {
            'name': widget.product.name,
            'quantity': enteredGrams,
            'unit': 'g',
            'gramsUsed': enteredGrams,
            'carbs': double.parse(totalCarbs.toStringAsFixed(1)),
            'source': 'database',
          },
        ],
        'totalCarbs': double.parse(totalCarbs.toStringAsFixed(1)),
        'carbRatio': widget.carbRatio,
        'insulinUnits': suggestedInsulin,
        'insulinMessage': suggestedInsulin == null
            ? 'No carb ratio found. Please consult your doctor.'
            : '',
      };

      final result = await MealApi.saveMeal(userId: userId, meal: meal);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Meal saved successfully'),
          backgroundColor: const Color(0xff17466E),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bool hasCarbRatio = widget.carbRatio != null && widget.carbRatio! > 0;

    return Scaffold(
      backgroundColor: const Color(0xffEAF6FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xffEAF6FF),
        foregroundColor: const Color(0xff17466E),
        title: Text(
          widget.mealTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xff17466E),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xff2B6CB0),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 700;

                    if (isSmallScreen) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                color: const Color(0xff1F5E9D),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: product.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.network(
                                        product.imageUrl!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.fastfood_rounded,
                                              size: 70,
                                              color: Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.fastfood_rounded,
                                      size: 70,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _simpleInfoRow(
                            "Carbs / 100g",
                            "${product.carbsPer100g.toStringAsFixed(1)} g",
                            isDark: true,
                          ),
                          if (product.carbsPerServing != null)
                            _simpleInfoRow(
                              "Carbs / serving",
                              "${product.carbsPerServing!.toStringAsFixed(1)} g",
                              isDark: true,
                            ),
                          if (product.servingSize != null &&
                              product.servingSize!.isNotEmpty)
                            _simpleInfoRow(
                              "Serving size",
                              product.servingSize!,
                              isDark: true,
                            ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            color: const Color(0xff1F5E9D),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: product.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.network(
                                    product.imageUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.fastfood_rounded,
                                      size: 70,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.fastfood_rounded,
                                  size: 70,
                                  color: Colors.white,
                                ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _simpleInfoRow(
                                "Carbs / 100g",
                                "${product.carbsPer100g.toStringAsFixed(1)} g",
                                isDark: true,
                              ),
                              if (product.carbsPerServing != null)
                                _simpleInfoRow(
                                  "Carbs / serving",
                                  "${product.carbsPerServing!.toStringAsFixed(1)} g",
                                  isDark: true,
                                ),
                              if (product.servingSize != null &&
                                  product.servingSize!.isNotEmpty)
                                _simpleInfoRow(
                                  "Serving size",
                                  product.servingSize!,
                                  isDark: true,
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "How much did you eat?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff17466E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Enter grams, then press calculate",
                      style: TextStyle(fontSize: 14, color: Color(0xff7A9AB5)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: gramsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff17466E),
                      ),
                      decoration: InputDecoration(
                        hintText: "Example: 45",
                        hintStyle: const TextStyle(
                          color: Color(0xff9BB7CF),
                          fontSize: 18,
                        ),
                        filled: true,
                        fillColor: const Color(0xffF5FAFE),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.scale_rounded,
                          color: Color(0xff2F7DB7),
                        ),
                        suffixText: "g",
                        suffixStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff17466E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: calculateValues,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2B6CB0),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Calculate",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xffDDF0FF),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _resultBox(
                                  title: "Grams",
                                  value: "${enteredGrams.toStringAsFixed(0)} g",
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _resultBox(
                                  title: "Carbs",
                                  value: "${totalCarbs.toStringAsFixed(1)} g",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (hasCarbRatio && suggestedInsulin != null)
                            _bigResultBox(
                              title: "Suggested meal insulin",
                              value: "$suggestedInsulin units",
                            )
                          else if (hasCalculated)
                            _messageBox(
                              message:
                                  "You don’t have a carb ratio saved. Please check with your doctor.",
                            )
                          else
                            _bigResultBox(
                              title: "Suggested meal insulin",
                              value: "0 units",
                            ),
                        ],
                      ),
                    ),
                    if (hasCalculated) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _saveBarcodeMeal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff17466E),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xff9BB7CF),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Save meal to database",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _simpleInfoRow(String label, String value, {bool isDark = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? const Color(0xffCFE4FF)
                    : const Color(0xff7A9AB5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xff17466E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultBox({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xff7A9AB5),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xff17466E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigResultBox({required String title, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xff7A9AB5),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xff17466E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBox({required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xff17466E),
        ),
      ),
    );
  }
}
