import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/meal_api.dart';

// ─── Color Palette ───────────────────────────────────────────────────────────
const Color b50 = Color(0xFFE6F1FB);
const Color b100 = Color(0xFFB5D4F4);
const Color b200 = Color(0xFF85B7EB);
const Color b400 = Color(0xFF378ADD);
const Color b600 = Color(0xFF185FA5);
const Color b800 = Color(0xFF0C447C);
const Color b900 = Color(0xFF042C53);

// ─── Current User Helper ─────────────────────────────────────────────────────
Future<String> getCurrentUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');

  if (userId == null || userId.trim().isEmpty) {
    throw Exception('User ID not found. Please login again.');
  }

  return userId.trim();
}

String formatSavedDate(dynamic value) {
  if (value == null) return '';

  try {
    final d = DateTime.parse(value.toString()).toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  } catch (_) {
    return value.toString();
  }
}

String mealTypeTitle(String mealType) {
  switch (mealType) {
    case 'breakfast':
      return 'Breakfast';
    case 'lunch':
      return 'Lunch';
    case 'dinner':
      return 'Dinner';
    case 'morningSnack':
      return 'Morning snack';
    case 'eveningSnack':
      return 'Evening snack';
    default:
      return 'Meal';
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────
class Ingredient {
  int id;
  String name;
  String qty;
  String unit;
  double? carb;

  Ingredient({
    required this.id,
    this.name = '',
    this.qty = '',
    this.unit = 'g',
    this.carb,
  });
}

class SavedMeal {
  final String id;
  final String name;
  final String serving;
  final double totalCarb;
  final int? insulinUnits;
  final String insulinMessage;
  final List<Map<String, dynamic>> ingredients;
  final String savedAt;

  SavedMeal({
    required this.id,
    required this.name,
    required this.serving,
    required this.totalCarb,
    required this.insulinUnits,
    required this.insulinMessage,
    required this.ingredients,
    required this.savedAt,
  });

  factory SavedMeal.fromBackend(Map<String, dynamic> json) {
    return SavedMeal(
      id: json['_id']?.toString() ?? '',
      name: json['mealName']?.toString() ?? 'Unnamed meal',
      serving: json['servingSize']?.toString() ?? '',
      totalCarb: (json['totalCarbs'] as num?)?.toDouble() ?? 0,
      insulinUnits: json['insulinUnits'] == null
          ? null
          : (json['insulinUnits'] as num).toInt(),
      insulinMessage: json['insulinMessage']?.toString() ?? '',
      ingredients: (json['ingredients'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      savedAt: formatSavedDate(json['createdAt']),
    );
  }
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class MealLoggerScreen extends StatefulWidget {
  final String mealType;

  const MealLoggerScreen({
    super.key,
    required this.mealType,
  });

  @override
  State<MealLoggerScreen> createState() => _MealLoggerScreenState();
}

class _MealLoggerScreenState extends State<MealLoggerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _refreshSavedMeals = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToSavedMeals() {
    setState(() {
      _refreshSavedMeals++;
    });

    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: b50,
        appBar: AppBar(
          backgroundColor: b800,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            '${mealTypeTitle(widget.mealType)} meal',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 2,
            labelColor: Colors.white,
            unselectedLabelColor: b100,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: const [
              Tab(text: 'New meal'),
              Tab(text: 'Saved meals'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            NewMealTab(
              mealType: widget.mealType,
              onSaved: _goToSavedMeals,
            ),
            SavedMealsTab(
              mealType: widget.mealType,
              refreshKey: _refreshSavedMeals,
            ),
          ],
        ),
      );
}

// ─── New Meal Tab ─────────────────────────────────────────────────────────────
class NewMealTab extends StatefulWidget {
  final String mealType;
  final VoidCallback onSaved;

  const NewMealTab({
    super.key,
    required this.mealType,
    required this.onSaved,
  });

  @override
  State<NewMealTab> createState() => _NewMealTabState();
}

class _NewMealTabState extends State<NewMealTab> {
  final _mealNameCtrl = TextEditingController();
  final _servingCtrl = TextEditingController();

  final List<Ingredient> _ings = [];

  Map<String, dynamic>? _calculatedMealFromBackend;

  int _idCounter = 0;
  bool _isCalculating = false;
  bool _isSaving = false;
  bool _calculated = false;

  double get _totalCarb => _ings.fold(0, (sum, i) => sum + (i.carb ?? 0));

  bool get _canCalculate =>
      _ings.any((i) => i.name.trim().isNotEmpty && i.qty.trim().isNotEmpty);

  @override
  void dispose() {
    _mealNameCtrl.dispose();
    _servingCtrl.dispose();
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ings.add(Ingredient(id: ++_idCounter));
      _calculated = false;
      _calculatedMealFromBackend = null;
    });
  }

  void _deleteIngredient(int id) {
    setState(() {
      _ings.removeWhere((i) => i.id == id);
      _calculated = false;
      _calculatedMealFromBackend = null;
    });
  }

  Future<void> _calculateCarbs() async {
    final toCalc = _ings
        .where((i) => i.name.trim().isNotEmpty && i.qty.trim().isNotEmpty)
        .toList();

    if (toCalc.isEmpty) return;

    setState(() => _isCalculating = true);

    try {
      final userId = await getCurrentUserId();

      final ingredientsPayload = toCalc.map((i) {
        return {
          'name': i.name.trim(),
          'quantity': double.tryParse(i.qty.trim()) ?? 0,
          'unit': i.unit.trim(),
        };
      }).toList();

      final result = await MealApi.calculateMeal(
        userId: userId,
        mealType: widget.mealType,
        mealName: _mealNameCtrl.text.trim().isEmpty
            ? 'Unnamed meal'
            : _mealNameCtrl.text.trim(),
        servingSize: _servingCtrl.text.trim(),
        ingredients: ingredientsPayload,
      );

      final meal = Map<String, dynamic>.from(result['meal'] as Map);
      final backendIngredients = meal['ingredients'] as List? ?? [];

      setState(() {
        _calculatedMealFromBackend = meal;

        for (final ing in _ings) {
          final matched = backendIngredients.where((item) {
            final backendItem = Map<String, dynamic>.from(item as Map);

            return backendItem['name'].toString().toLowerCase().trim() ==
                ing.name.toLowerCase().trim();
          }).toList();

          if (matched.isNotEmpty) {
            final backendItem =
                Map<String, dynamic>.from(matched.first as Map);
            ing.carb = (backendItem['carbs'] as num?)?.toDouble();
          }
        }

        _calculated = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calculation failed: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCalculating = false);
      }
    }
  }

 Future<void> _saveMeal() async {
  if (_calculatedMealFromBackend == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calculate the meal first'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() => _isSaving = true);

  try {
    final userId = await getCurrentUserId();

    final mealToSave = Map<String, dynamic>.from(_calculatedMealFromBackend!);
    mealToSave['mealType'] = widget.mealType;

    final result = await MealApi.saveMeal(
      userId: userId,
      meal: mealToSave,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Meal saved successfully'),
          backgroundColor: b800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      widget.onSaved();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}

  int get _stepsDone {
    int s = 0;

    if (_mealNameCtrl.text.trim().isNotEmpty) s++;
    if (_ings.any((i) => i.name.trim().isNotEmpty && i.qty.isNotEmpty)) s++;
    if (_calculated) s++;

    return s;
  }

  @override
  Widget build(BuildContext context) {
    final backendTotalCarbs =
        (_calculatedMealFromBackend?['totalCarbs'] as num?)?.toDouble();

    final backendInsulinUnits =
        _calculatedMealFromBackend?['insulinUnits'] == null
            ? null
            : (_calculatedMealFromBackend?['insulinUnits'] as num).toInt();

    final backendInsulinMessage =
        _calculatedMealFromBackend?['insulinMessage']?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(stepsDone: _stepsDone),
          const SizedBox(height: 14),

          _FieldLabel('Meal type'),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: b200, width: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              mealTypeTitle(widget.mealType),
              style: const TextStyle(
                fontSize: 14,
                color: b800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 14),

          _FieldLabel('Meal name'),
          const SizedBox(height: 6),
          _BlueTextField(
            controller: _mealNameCtrl,
            placeholder: 'e.g. Mansaf, Maqluba, Grilled chicken...',
            onChanged: (_) {
              setState(() {
                _calculated = false;
                _calculatedMealFromBackend = null;
              });
            },
          ),

          const SizedBox(height: 14),

          _FieldLabel('Serving size'),
          const SizedBox(height: 6),
          _BlueTextField(
            controller: _servingCtrl,
            placeholder: 'e.g. 1 plate, 2 cups, 300g',
            onChanged: (_) {
              setState(() {
                _calculated = false;
                _calculatedMealFromBackend = null;
              });
            },
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ingredients',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: b800,
                ),
              ),
              TextButton(
                onPressed: _addIngredient,
                style: TextButton.styleFrom(
                  backgroundColor: b400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '+ Add ingredient',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (_ings.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No ingredients added yet',
                  style: TextStyle(fontSize: 13, color: b400),
                ),
              ),
            )
          else
            ..._ings.map(
              (ing) => _IngredientCard(
                ingredient: ing,
                onDelete: () => _deleteIngredient(ing.id),
                onChanged: () {
                  setState(() {
                    _calculated = false;
                    _calculatedMealFromBackend = null;
                  });
                },
              ),
            ),

          if (_calculated) ...[
            const SizedBox(height: 14),
            _SummaryCard(
              totalCarb: backendTotalCarbs ?? _totalCarb,
              insulinUnits: backendInsulinUnits,
              insulinMessage: backendInsulinMessage,
            ),
          ],

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _canCalculate && !_isCalculating ? _calculateCarbs : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: b800,
                foregroundColor: Colors.white,
                disabledBackgroundColor: b100,
                disabledForegroundColor: b50,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isCalculating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _calculated ? 'Recalculate' : 'Calculate carbs',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),

          if (_calculated) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSaving ? null : _saveMeal,
                style: OutlinedButton.styleFrom(
                  foregroundColor: b600,
                  side: const BorderSide(color: b200),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: b600,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save meal to database',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Saved Meals Tab ──────────────────────────────────────────────────────────
class SavedMealsTab extends StatefulWidget {
  final String mealType;
  final int refreshKey;

  const SavedMealsTab({
    super.key,
    required this.mealType,
    required this.refreshKey,
  });

  @override
  State<SavedMealsTab> createState() => _SavedMealsTabState();
}

class _SavedMealsTabState extends State<SavedMealsTab> {
  final _searchCtrl = TextEditingController();

  List<SavedMeal> _meals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  @override
  void didUpdateWidget(covariant SavedMealsTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshKey != widget.refreshKey ||
        oldWidget.mealType != widget.mealType) {
      _loadMeals();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMeals() async {
    setState(() => _loading = true);

    try {
      final userId = await getCurrentUserId();

      final data = await MealApi.getSavedMeals(
        userId: userId,
        mealType: widget.mealType,
      );

      setState(() {
        _meals = data
            .map(
              (e) => SavedMeal.fromBackend(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Load meals failed: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _deleteMeal(String id) async {
    try {
      await MealApi.deleteMeal(id);
      await _loadMeals();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Meal removed from database'),
            backgroundColor: b800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  List<SavedMeal> get _filtered {
    final q = _searchCtrl.text.toLowerCase();

    if (q.isEmpty) return _meals;

    return _meals.where((m) => m.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: b600),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 13, color: b900),
            decoration: InputDecoration(
              hintText: 'Search ${mealTypeTitle(widget.mealType)} meals...',
              hintStyle: const TextStyle(color: b200, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: b200, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: b200, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: b400, width: 1),
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: b400,
              ),
            ),
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(
                    _meals.isEmpty
                        ? 'No saved ${mealTypeTitle(widget.mealType).toLowerCase()} meals yet.\nAdd your first one!'
                        : 'No results found.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: b400),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMeals,
                  color: b600,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) => _SavedMealCard(
                      meal: _filtered[i],
                      onDelete: () => _deleteMeal(_filtered[i].id),
                      onReuse: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '"${_filtered[i].name}" loaded — ready to log',
                            ),
                            backgroundColor: b800,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int stepsDone;

  const _StepIndicator({
    required this.stepsDone,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(5, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 1,
                color: b100,
              ),
            );
          }

          final step = i ~/ 2;

          return Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step < stepsDone ? b800 : b100,
            ),
          );
        }),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: b800,
          letterSpacing: 0.5,
        ),
      );
}

class _BlueTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;

  const _BlueTextField({
    required this.controller,
    required this.placeholder,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: b900),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: b200, fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: b200, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: b200, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: b400, width: 1),
          ),
        ),
      );
}

class _IngredientCard extends StatefulWidget {
  final Ingredient ingredient;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _IngredientCard({
    required this.ingredient,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_IngredientCard> createState() => _IngredientCardState();
}

class _IngredientCardState extends State<_IngredientCard> {
  final _units = ['g', 'cup', 'tbsp', 'tsp', 'piece', 'slice', 'oz'];

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: b100, width: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 430;

            return Column(
              children: [
                if (!isSmall)
                  Row(
                    children: [
                      Expanded(child: _nameField()),
                      const SizedBox(width: 6),
                      SizedBox(width: 60, child: _qtyField()),
                      const SizedBox(width: 6),
                      SizedBox(width: 88, child: _unitDropdown()),
                      const SizedBox(width: 4),
                      _deleteButton(),
                    ],
                  )
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _nameField()),
                          const SizedBox(width: 4),
                          _deleteButton(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _qtyField()),
                          const SizedBox(width: 8),
                          Expanded(child: _unitDropdown()),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Carbs after calculation',
                      style: TextStyle(fontSize: 11, color: b200),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.ingredient.carb != null ? b100 : b50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.ingredient.carb != null
                            ? '${widget.ingredient.carb!.toStringAsFixed(1)} g'
                            : '— g',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: widget.ingredient.carb != null ? b800 : b400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

  Widget _nameField() {
    return TextField(
      onChanged: (v) {
        widget.ingredient.name = v;
        widget.ingredient.carb = null;
        widget.onChanged();
      },
      style: const TextStyle(fontSize: 13, color: b900),
      decoration: _ingDecor('Ingredient name'),
    );
  }

  Widget _qtyField() {
    return TextField(
      keyboardType: TextInputType.number,
      onChanged: (v) {
        widget.ingredient.qty = v;
        widget.ingredient.carb = null;
        widget.onChanged();
      },
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, color: b900),
      decoration: _ingDecor('Qty'),
    );
  }

  Widget _unitDropdown() {
    return DropdownButtonFormField<String>(
      value: widget.ingredient.unit,
      isDense: true,
      isExpanded: true,
      style: const TextStyle(fontSize: 12, color: b900),
      decoration: _ingDecor(''),
      items: _units
          .map(
            (u) => DropdownMenuItem(
              value: u,
              child: Text(
                u,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) {
          setState(() {
            widget.ingredient.unit = v;
            widget.ingredient.carb = null;
          });
          widget.onChanged();
        }
      },
    );
  }

  Widget _deleteButton() {
    return InkWell(
      onTap: widget.onDelete,
      borderRadius: BorderRadius.circular(20),
      child: const SizedBox(
        width: 30,
        height: 30,
        child: Icon(
          Icons.close,
          size: 17,
          color: b200,
        ),
      ),
    );
  }

  InputDecoration _ingDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: b200, fontSize: 12),
        filled: true,
        fillColor: b50,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 8,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: b100, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: b100, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: b400, width: 1),
        ),
      );
}

class _SummaryCard extends StatelessWidget {
  final double totalCarb;
  final int? insulinUnits;
  final String? insulinMessage;

  const _SummaryCard({
    required this.totalCarb,
    this.insulinUnits,
    this.insulinMessage,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: b800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total carbs',
                  style: TextStyle(fontSize: 13, color: b200),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      totalCarb.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'g',
                      style: TextStyle(fontSize: 13, color: b200),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: insulinUnits != null
                  ? Text(
                      'Suggested insulin: $insulinUnits units',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Text(
                      insulinMessage == null || insulinMessage!.isEmpty
                          ? 'No carb ratio found.'
                          : insulinMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: b100,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ],
        ),
      );
}

class _SavedMealCard extends StatelessWidget {
  final SavedMeal meal;
  final VoidCallback onDelete;
  final VoidCallback onReuse;

  const _SavedMealCard({
    required this.meal,
    required this.onDelete,
    required this.onReuse,
  });

  @override
  Widget build(BuildContext context) {
    final ingPreview = meal.ingredients
        .take(4)
        .map((i) {
          final qty = i['quantity']?.toString() ?? '';
          final unit = i['unit']?.toString() ?? '';
          final name = i['name']?.toString() ?? '';
          return '$qty$unit $name';
        })
        .join(' · ');

    final hasMore = meal.ingredients.length > 4;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: b100, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  meal.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: b900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: b800,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${meal.totalCarb.toStringAsFixed(1)} g carbs',
                  style: const TextStyle(
                    fontSize: 12,
                    color: b100,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$ingPreview${hasMore ? ' · …' : ''}',
            style: const TextStyle(fontSize: 12, color: b600),
          ),
          if (meal.serving.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Serving: ${meal.serving}',
              style: const TextStyle(fontSize: 11, color: b400),
            ),
          ],
          if (meal.insulinUnits != null) ...[
            const SizedBox(height: 2),
            Text(
              'Insulin: ${meal.insulinUnits} units',
              style: const TextStyle(
                fontSize: 11,
                color: b800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (meal.savedAt.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Saved ${meal.savedAt}',
              style: const TextStyle(fontSize: 11, color: b400),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onReuse,
                  style: TextButton.styleFrom(
                    backgroundColor: b50,
                    foregroundColor: b600,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Use this meal again',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: b100, width: 0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}