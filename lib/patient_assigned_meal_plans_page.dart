import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PatientAssignedMealPlansPage extends StatefulWidget {
  final String patientId;

  const PatientAssignedMealPlansPage({
    super.key,
    required this.patientId,
  });

  @override
  State<PatientAssignedMealPlansPage> createState() =>
      _PatientAssignedMealPlansPageState();
}

class _PatientAssignedMealPlansPageState
    extends State<PatientAssignedMealPlansPage> {
  bool isLoading = true;
  List<dynamic> plans = [];

  final Color deepBlue = const Color(0xFF0A4FA3);
  final Color pageBg = const Color(0xFFEAF6FF);
  final Color cardBg = const Color(0xFFF8FCFF);
  final Color darkText = const Color(0xFF102A43);
  final Color subText = const Color(0xFF5F7896);
  final Color borderColor = const Color(0xFFBFDFFF);

  String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    return 'http://10.0.2.2:5000';
  }

  @override
  void initState() {
    super.initState();
    fetchPatientMealPlans();
  }

  Future<void> fetchPatientMealPlans() async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/nutritionist-meal-plans/patient/${widget.patientId}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          plans = data['plans'] ?? [];
          isLoading = false;
        });
      } else {
        debugPrint('Failed to load meal plans: ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Meal plans error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String nutritionistName(dynamic plan) {
    final nutritionist = plan['nutritionistId'];

    if (nutritionist is Map<String, dynamic>) {
      final first = nutritionist['firstName']?.toString() ?? '';
      final last = nutritionist['lastName']?.toString() ?? '';
      final name = '$first $last'.trim();

      if (name.isNotEmpty) return name;
    }

    return 'Nutritionist';
  }

  String formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '-';

    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Meal Plans'),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: deepBlue),
            )
          : plans.isEmpty
              ? Center(
                  child: Text(
                    'No meal plans assigned yet.',
                    style: TextStyle(
                      color: subText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: plans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildPlanCard(plans[index]);
                  },
                ),
    );
  }

  Widget _buildPlanCard(dynamic plan) {
    final title = plan['planTitle']?.toString() ?? 'Meal Plan';
    final goal = plan['clinicalGoal']?.toString() ?? '';
    final startDate = formatDate(plan['startDate']);
    final endDate = formatDate(plan['endDate']);
    final meals = plan['meals'] ?? {};
    final totals = plan['dailyTotals'] ?? {};
    final targets = plan['glucoseTargets'] ?? {};

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: darkText,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Assigned by ${nutritionistName(plan)}',
            style: TextStyle(
              color: deepBlue,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          if (goal.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              goal,
              style: TextStyle(
                color: subText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 16),

          Row(
            children: [
              _buildInfoBox('Start', startDate),
              const SizedBox(width: 10),
              _buildInfoBox('End', endDate),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              _buildInfoBox(
                'Fasting',
                targets['fasting']?.toString() ?? '-',
              ),
              const SizedBox(width: 10),
              _buildInfoBox(
                'Post Meal',
                targets['postMeal']?.toString() ?? '-',
              ),
              const SizedBox(width: 10),
              _buildInfoBox(
                'HbA1c',
                targets['hba1cTarget']?.toString() ?? '-',
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildTotalsRow(totals),

          const SizedBox(height: 18),

          _buildMealSection('Breakfast', meals['breakfast']),
          _buildMealSection('Lunch', meals['lunch']),
          _buildMealSection('Dinner', meals['dinner']),
          _buildMealSection('Snack', meals['snack']),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: subText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: darkText,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsRow(dynamic totals) {
    return Row(
      children: [
        _buildTotalBox('Calories', '${totals['calories'] ?? 0}'),
        const SizedBox(width: 8),
        _buildTotalBox('Carbs', '${totals['carbs'] ?? 0}g'),
        const SizedBox(width: 8),
        _buildTotalBox('Protein', '${totals['protein'] ?? 0}g'),
        const SizedBox(width: 8),
        _buildTotalBox('Fat', '${totals['fat'] ?? 0}g'),
      ],
    );
  }

  Widget _buildTotalBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFDFF1FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: deepBlue,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: subText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(String title, dynamic meal) {
    if (meal is! Map<String, dynamic>) return const SizedBox.shrink();

    final foodItems = meal['foodItems']?.toString() ?? '';
    final carbs = meal['carbs']?.toString() ?? '0';
    final calories = meal['calories']?.toString() ?? '0';
    final protein = meal['protein']?.toString() ?? '0';
    final fat = meal['fat']?.toString() ?? '0';
    final notes = meal['notes']?.toString() ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: deepBlue,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            foodItems.isEmpty ? 'No food items added.' : foodItems,
            style: TextStyle(
              color: darkText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMacroChip('Carbs', '${carbs}g'),
              _buildMacroChip('Calories', calories),
              _buildMacroChip('Protein', '${protein}g'),
              _buildMacroChip('Fat', '${fat}g'),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Notes: $notes',
              style: TextStyle(
                color: subText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: deepBlue,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}