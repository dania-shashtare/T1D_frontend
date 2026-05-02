import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'services/meal_api.dart';

class Ingredient {
  final String name;
  final String quantity;

  Ingredient({required this.name, required this.quantity});

  factory Ingredient.fromJson(Map<String, dynamic> j) {
    return Ingredient(name: j['name'] ?? '', quantity: j['quantity'] ?? '');
  }
}

class Meal {
  final String name;
  final String description;
  final int carbs;
  final double? insulinUnits;
  final int calories;
  final List<Ingredient> ingredients;
  final List<String> steps;
  final String insulinNote;
  final String imageQuery;

  Meal({
    required this.name,
    required this.description,
    required this.carbs,
    required this.insulinUnits,
    required this.calories,
    required this.ingredients,
    required this.steps,
    required this.insulinNote,
    required this.imageQuery,
  });

  factory Meal.fromJson(Map<String, dynamic> j) {
    return Meal(
      name: j['name'] ?? '',
      description: j['description'] ?? '',
      carbs: (j['carbs'] ?? 0).toInt(),
      insulinUnits: j['insulin_units'] == null
          ? null
          : (j['insulin_units'] as num).toDouble(),
      calories: (j['calories'] ?? 0).toInt(),
      ingredients: (j['ingredients'] as List? ?? [])
          .map((e) => Ingredient.fromJson(e))
          .toList(),
      steps: List<String>.from(j['steps'] ?? []),
      insulinNote: j['insulin_note'] ?? '',
      imageQuery: j['image_query'] ?? j['name'] ?? '',
    );
  }
}

// خلي Pexels هون مؤقتًا إذا بدك الصور تضل تشتغل.
// الأفضل لاحقًا ننقله للباك كمان.
const String _pexelsKey =
    '36pYRNHhXD1sdl1qwsWjx8ltRmusydlEZSJa9DL72CzVnB9efH10mi9v';

// إذا بتجربي على Chrome خليه localhost.
// إذا Android Emulator استخدمي: http://10.0.2.2:5000
// إذا موبايل حقيقي استخدمي IP اللابتوب مثل: http://192.168.1.5:5000
//const String _baseUrl = 'http://localhost:5000';
const String _baseUrl = 'http://10.0.2.2:5000';

const _blue900 = Color(0xFF042C53);
const _blue800 = Color(0xFF0C447C);
const _blue600 = Color(0xFF185FA5);
const _blue400 = Color(0xFF378ADD);
const _blue200 = Color(0xFF85B7EB);
const _blue100 = Color(0xFFB5D4F4);
const _blue50 = Color(0xFFE6F1FB);
const _amber50 = Color(0xFFFAEEDA);
const _amber800 = Color(0xFF633806);
const _green50 = Color(0xFFEAF3DE);

class MealSuggestionScreen extends StatefulWidget {
  final String mealType;
  final String userId;

  const MealSuggestionScreen({
    super.key,
    required this.mealType,
    required this.userId,
  });

  @override
  State<MealSuggestionScreen> createState() => _MealSuggestionScreenState();
}

class _MealSuggestionScreenState extends State<MealSuggestionScreen> {
  final TextEditingController _queryCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  List<Meal> _meals = [];
  List<String> _mealImages = [];

  Future<String> _fetchPexelsImage(String query) async {
    try {
      final q = Uri.encodeComponent('$query food');

      final res = await http.get(
        Uri.parse(
          'https://api.pexels.com/v1/search?query=$q&per_page=1&orientation=square',
        ),
        headers: {'Authorization': _pexelsKey},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final photos = data['photos'] as List;

        if (photos.isNotEmpty) {
          return photos[0]['src']['large'] as String;
        }
      }
    } catch (_) {}

    return '';
  }

  Future<void> _suggest() async {
    final query = _queryCtrl.text.trim();

    setState(() {
      _loading = true;
      _error = null;
      _meals = [];
      _mealImages = [];
    });

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/ai/suggest-meals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'mealType': widget.mealType,
          'userNote': query.isEmpty ? 'none' : query,
        }),
      );

      if (res.statusCode != 200) {
        throw Exception('API error ${res.statusCode}: ${res.body}');
      }

      final parsed = jsonDecode(res.body);

      final meals = (parsed['meals'] as List)
          .map((m) => Meal.fromJson(m))
          .toList();

      final List<String> imageUrls = await Future.wait(
        meals.map((m) => _fetchPexelsImage(m.imageQuery)),
      );

      setState(() {
        _meals = meals;
        _mealImages = imageUrls;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _openDetail(Meal meal, String imageUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        meal: meal,
        imageUrl: imageUrl,
        mealType: widget.mealType,
        userId: widget.userId,
      ),
    );
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: _blue900,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.mealType,
          style: const TextStyle(
            color: _blue900,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryCtrl,
                      onSubmitted: (_) => _suggest(),
                      style: const TextStyle(fontSize: 14, color: _blue900),
                      decoration: InputDecoration(
                        hintText:
                            'e.g. high blood sugar 200, prefer warm food...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: _blue200,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: _blue50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _blue100),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _blue100),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: _blue400,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _loading ? null : _suggest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue600,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _blue100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                    ),
                    child: const Text(
                      'Suggest ←',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading) const _LoadingWidget(),
              if (_error != null) _ErrorWidget(message: _error!),
              if (_meals.isNotEmpty) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _meals.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (ctx, i) {
                    return _MealCard(
                      meal: _meals[i],
                      imageUrl: i < _mealImages.length ? _mealImages[i] : '',
                      onTap: () {
                        _openDetail(
                          _meals[i],
                          i < _mealImages.length ? _mealImages[i] : '',
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _suggest,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('More suggestions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _blue600,
                      side: const BorderSide(color: _blue100, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  final String imageUrl;
  final VoidCallback onTap;

  const _MealCard({
    required this.meal,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final insulinText = meal.insulinUnits == null
        ? 'No ratio'
        : '${meal.insulinUnits!.round()}u';

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: _blue50,
                        child: const Center(
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: _blue200,
                            size: 40,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;

                      return Container(
                        color: _blue50,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _blue400,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color: _blue50,
                    child: const Center(
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: _blue200,
                        size: 40,
                      ),
                    ),
                  ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.72),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _Pill(
                          label: '${meal.carbs}g carbs',
                          bg: _amber50,
                          fg: _amber800,
                        ),
                        _Pill(label: insulinText, bg: _blue50, fg: _blue800),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParsedQuantity {
  final double quantity;
  final String unit;

  const _ParsedQuantity({required this.quantity, required this.unit});
}

class _DetailSheet extends StatefulWidget {
  final Meal meal;
  final String imageUrl;
  final String mealType;
  final String userId;

  const _DetailSheet({
    required this.meal,
    required this.imageUrl,
    required this.mealType,
    required this.userId,
  });

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  bool _isSaving = false;

  String _mealTypeForDatabase(String mealType) {
    switch (mealType) {
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

      case 'breakfast':
      case 'morningSnack':
      case 'lunch':
      case 'eveningSnack':
      case 'dinner':
        return mealType;

      default:
        return 'breakfast';
    }
  }

  _ParsedQuantity _parseQuantity(String raw) {
    final text = raw.trim();

    if (text.isEmpty) {
      return const _ParsedQuantity(quantity: 1, unit: 'serving');
    }

    final parts = text.split(RegExp(r'\s+'));

    final number = double.tryParse(parts.first);

    if (number != null) {
      final unit = parts.length > 1 ? parts.sublist(1).join(' ') : 'serving';

      return _ParsedQuantity(
        quantity: number,
        unit: unit.isEmpty ? 'serving' : unit,
      );
    }

    return _ParsedQuantity(quantity: 1, unit: text);
  }

  List<Map<String, dynamic>> _buildIngredientsForSave() {
    final ingredients = widget.meal.ingredients.map((ing) {
      final parsed = _parseQuantity(ing.quantity);

      return {
        'name': ing.name,
        'quantity': parsed.quantity,
        'unit': parsed.unit,
        'gramsUsed': null,
        'carbs': 0,
        'source': 'database',
      };
    }).toList();

    ingredients.add({
      'name': 'Estimated total carbs',
      'quantity': 1,
      'unit': 'serving',
      'gramsUsed': null,
      'carbs': widget.meal.carbs.toDouble(),
      'source': 'database',
    });

    return ingredients;
  }

  Future<void> _saveSelectedMeal() async {
    setState(() => _isSaving = true);

    try {
      final meal = {
        'mealType': _mealTypeForDatabase(widget.mealType),
        'mealName': widget.meal.name,
        'servingSize': '1 serving',
        'ingredients': _buildIngredientsForSave(),
        'totalCarbs': widget.meal.carbs.toDouble(),
        'carbRatio': null,
        'insulinUnits': widget.meal.insulinUnits == null
            ? null
            : widget.meal.insulinUnits!.round(),
        'insulinMessage': widget.meal.insulinNote,
      };

      final result = await MealApi.saveMeal(userId: widget.userId, meal: meal);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Meal saved successfully'),
          backgroundColor: _blue800,
        ),
      );

      Navigator.pop(context);
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insulinValue = widget.meal.insulinUnits == null
        ? '--'
        : '${widget.meal.insulinUnits!.round()}u';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollCtrl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _blue100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Stack(
                  children: [
                    ClipRRect(
                      child: widget.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.imageUrl,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  height: 220,
                                  color: _blue50,
                                  child: const Center(
                                    child: Icon(
                                      Icons.restaurant_rounded,
                                      color: _blue200,
                                      size: 56,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 220,
                              color: _blue50,
                              child: const Center(
                                child: Icon(
                                  Icons.restaurant_rounded,
                                  color: _blue200,
                                  size: 56,
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: _blue900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.meal.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _blue900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.meal.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _blue600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _StatBox(
                            value: '${widget.meal.carbs}g',
                            label: 'Total carbs',
                            valueColor: _amber800,
                            bg: _amber50,
                          ),
                          const SizedBox(width: 8),
                          _StatBox(
                            value: insulinValue,
                            label: 'Insulin units',
                            valueColor: _blue800,
                            bg: _blue50,
                          ),
                          const SizedBox(width: 8),
                          _StatBox(
                            value: '${widget.meal.calories}',
                            label: 'Calories',
                            valueColor: const Color(0xFF27500A),
                            bg: _green50,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel(label: 'Ingredients'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.meal.ingredients.map((ing) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _blue50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ing.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _blue900,
                                  ),
                                ),
                                Text(
                                  ing.quantity,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _blue600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: _blue100, thickness: 0.5),
                      const SizedBox(height: 16),
                      const _SectionLabel(label: 'Preparation'),
                      const SizedBox(height: 10),
                      ...widget.meal.steps.asMap().entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: _blue50,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${e.key + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _blue800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _blue900,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _blue50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _blue100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💉 ', style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Insulin note: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _blue800,
                                      ),
                                    ),
                                    TextSpan(
                                      text: widget.meal.insulinNote,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _blue600,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveSelectedMeal,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 18,
                                ),
                          label: Text(
                            _isSaving ? 'Saving...' : 'Save selected meal',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue800,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _blue100,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _blue50 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? _blue400 : _blue100,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: active ? _blue800 : _blue400,
            fontWeight: active ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final Color bg;

  const _StatBox({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: _blue600)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _blue400,
        letterSpacing: 0.08,
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: _blue400, strokeWidth: 2),
            SizedBox(height: 12),
            Text(
              'Finding meals for you...',
              style: TextStyle(fontSize: 13, color: _blue600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;

  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: Color(0xFFA32D2D)),
      ),
    );
  }
}

// هذا للتجربة فقط.
// داخل التطبيق الحقيقي افتحي الصفحة من PatientScreen ومرري userId الحقيقي.
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MealSuggestionScreen(
        mealType: 'Breakfast',
        userId: 'PUT_TEST_USER_ID_HERE',
      ),
    ),
  );
}
