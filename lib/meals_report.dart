import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'patient_screen.dart';

import 'services/meal_report_api.dart';

void main() {
  runApp(const MealReportApp());
}

const Color kPrimary = Color(0xFF1A3A6B);
const Color kAccent = Color(0xFF2B7FD4);
const Color kLight = Color(0xFFEAF2FF);
const Color kBar = Color(0xFF3A8FE8);
const double kGoal = 200.0;

Future<String> getCurrentUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');

  if (userId == null || userId.trim().isEmpty) {
    throw Exception('User ID not found. Please login again.');
  }

  return userId.trim();
}

String formatShortDate(DateTime date) {
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
    'Dec',
  ];

  return '${date.day} ${months[date.month - 1]}';
}

String formatLongDate(DateTime date) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
}

String mealTypeLabel(String type) {
  switch (type) {
    case 'breakfast':
      return 'Breakfast';
    case 'morningSnack':
      return 'Morning Snack';
    case 'lunch':
      return 'Lunch';
    case 'eveningSnack':
      return 'Afternoon Snack';
    case 'dinner':
      return 'Dinner';
    default:
      return 'Meal';
  }
}

class MealIngredient {
  final String name;
  final String amount;
  final double carbs;

  const MealIngredient({
    required this.name,
    required this.amount,
    required this.carbs,
  });

  factory MealIngredient.fromJson(Map<String, dynamic> json) {
    final quantity = json['quantity']?.toString() ?? '';
    final unit = json['unit']?.toString() ?? '';
    final amount = '$quantity $unit'.trim();

    return MealIngredient(
      name: json['name']?.toString() ?? 'Ingredient',
      amount: amount.isEmpty ? '-' : amount,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Meal {
  final String id;
  final String mealType;
  final String name;
  final String serving;
  final double totalCarbs;
  final int? insulinUnits;
  final List<MealIngredient> ingredients;

  const Meal({
    required this.id,
    required this.mealType,
    required this.name,
    required this.serving,
    required this.totalCarbs,
    required this.insulinUnits,
    required this.ingredients,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      mealType: json['mealType']?.toString() ?? '',
      name: json['mealName']?.toString() ?? 'Unnamed meal',
      serving: json['servingSize']?.toString() ?? '',
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? 0,
      insulinUnits: json['insulinUnits'] == null
          ? null
          : (json['insulinUnits'] as num).toInt(),
      ingredients: (json['ingredients'] as List? ?? [])
          .map(
            (e) => MealIngredient.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}

class DayRecord {
  final DateTime date;
  final double totalCarbs;
  final double totalInsulin;
  final List<Meal> meals;

  const DayRecord({
    required this.date,
    required this.totalCarbs,
    required this.totalInsulin,
    required this.meals,
  });

  factory DayRecord.fromJson(Map<String, dynamic> json) {
    return DayRecord(
      date: DateTime.parse(json['date'].toString()),
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? 0,
      totalInsulin: (json['totalInsulin'] as num?)?.toDouble() ?? 0,
      meals: (json['meals'] as List? ?? [])
          .map((e) => Meal.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class ReportSummary {
  final double totalCarbs;
  final double totalInsulin;
  final double dailyAverage;
  final double highestDay;
  final int overGoalDays;
  final int totalMeals;
  final double dailyCarbGoal;

  const ReportSummary({
    required this.totalCarbs,
    required this.totalInsulin,
    required this.dailyAverage,
    required this.highestDay,
    required this.overGoalDays,
    required this.totalMeals,
    required this.dailyCarbGoal,
  });

  factory ReportSummary.empty() {
    return const ReportSummary(
      totalCarbs: 0,
      totalInsulin: 0,
      dailyAverage: 0,
      highestDay: 0,
      overGoalDays: 0,
      totalMeals: 0,
      dailyCarbGoal: kGoal,
    );
  }

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? 0,
      totalInsulin: (json['totalInsulin'] as num?)?.toDouble() ?? 0,
      dailyAverage: (json['dailyAverage'] as num?)?.toDouble() ?? 0,
      highestDay: (json['highestDay'] as num?)?.toDouble() ?? 0,
      overGoalDays: (json['overGoalDays'] as num?)?.toInt() ?? 0,
      totalMeals: (json['totalMeals'] as num?)?.toInt() ?? 0,
      dailyCarbGoal: (json['dailyCarbGoal'] as num?)?.toDouble() ?? kGoal,
    );
  }
}

class MealReportApp extends StatelessWidget {
  final String? patientId;
  final bool openedFromNutritionist;

  const MealReportApp({
    super.key,
    this.patientId,
    this.openedFromNutritionist = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meal Report',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
        useMaterial3: true,
        scaffoldBackgroundColor: kLight,
      ),
      home: MealReportScreen(
        patientId: patientId,
        openedFromNutritionist: openedFromNutritionist,
      ),
    );
  }
}

class MealReportScreen extends StatefulWidget {
  final String? patientId;
  final bool openedFromNutritionist;
  final bool embedded;

  const MealReportScreen({
    super.key,
    this.patientId,
    this.openedFromNutritionist = false,
    this.embedded = false,
  });

  @override
  State<MealReportScreen> createState() => _MealReportScreenState();
}

class _MealReportScreenState extends State<MealReportScreen> {
  String _filter = 'all';
  bool _loading = true;
  String? _error;

  ReportSummary _summary = ReportSummary.empty();
  List<DayRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId =
          widget.patientId != null && widget.patientId!.trim().isNotEmpty
          ? widget.patientId!.trim()
          : await getCurrentUserId();

      final data = await MealReportApi.getMealReport(
        userId: userId,
        filter: _filter,
      );

      final summary = ReportSummary.fromJson(
        Map<String, dynamic>.from(data['summary'] as Map? ?? {}),
      );

      final days = (data['days'] as List? ?? [])
          .map((e) => DayRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      setState(() {
        _summary = summary;
        _records = days;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _changeFilter(String value) {
    setState(() => _filter = value);
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      onRefresh: _loadReport,
      color: kAccent,
      child: CustomScrollView(
        slivers: [
          if (!widget.embedded)
            SliverAppBar(
              pinned: true,
              expandedHeight: 130,
              backgroundColor: kPrimary,
              automaticallyImplyLeading: false,
              leadingWidth: 56,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () async {
                  if (widget.openedFromNutritionist) {
                    Navigator.pop(context);
                    return;
                  }

                  final prefs = await SharedPreferences.getInstance();
                  final userId = prefs.getString('userId') ?? '';

                  if (!context.mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientHomeScreen(userId: userId),
                    ),
                  );
                },
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(64, 0, 16, 16),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Meal Report',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Meals, carbs and insulin',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFAAC8EE),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Daily goal',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFAAC8EE),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${_summary.dailyCarbGoal.toInt()}g carbs',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _records.isEmpty ? null : _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  tooltip: 'Export PDF',
                ),
              ],
            ),

          if (widget.embedded)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Meal Report',
                        style: TextStyle(
                          color: kPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _records.isEmpty ? null : _exportPdf,
                      icon: const Icon(Icons.picture_as_pdf, color: kPrimary),
                      tooltip: 'Export PDF',
                    ),
                  ],
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Container(
              color: widget.embedded ? Colors.transparent : kAccent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterBtn('All', 'all'),
                    const SizedBox(width: 8),
                    _filterBtn('Today', 'today'),
                    const SizedBox(width: 8),
                    _filterBtn('This week', 'week'),
                    const SizedBox(width: 8),
                    _filterBtn('This month', 'month'),
                  ],
                ),
              ),
            ),
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: kAccent)),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ),
            )
          else if (_records.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No meals saved for this period yet.',
                  style: TextStyle(
                    color: kPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    final cardWidth = isWide
                        ? (constraints.maxWidth - 10) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          height: 118,
                          child: _StatCard(
                            label: 'Total carbs',
                            value: '${_summary.totalCarbs.toStringAsFixed(0)}g',
                            sub: '${_summary.totalMeals} meals logged',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          height: 118,
                          child: _StatCard(
                            label: 'Total insulin',
                            value:
                                '${_summary.totalInsulin.toStringAsFixed(0)}u',
                            sub: 'Units for selected period',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          height: 118,
                          child: _StatCard(
                            label: 'Daily average',
                            value:
                                '${_summary.dailyAverage.toStringAsFixed(0)}g',
                            sub: 'Goal: ${_summary.dailyCarbGoal.toInt()}g/day',
                            showBar: true,
                            barValue:
                                _summary.dailyAverage / _summary.dailyCarbGoal,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          height: 118,
                          child: _StatCard(
                            label: 'Highest day',
                            value: '${_summary.highestDay.toStringAsFixed(0)}g',
                            sub: 'Peak daily intake',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(child: _ChartSection(data: _records)),
            SliverToBoxAdapter(child: _MealDetailsSection(data: _records)),
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ],
      ),
    );

    if (widget.embedded) {
      return Container(color: kLight, child: content);
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _records.isEmpty ? null : _exportPdf,
        backgroundColor: kPrimary,
        icon: Icon(
          widget.openedFromNutritionist ? Icons.picture_as_pdf : Icons.send,
          color: Colors.white,
        ),
        label: Text(
          widget.openedFromNutritionist ? 'Export PDF' : 'Send to doctor',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: content,
    );
  }

  Widget _filterBtn(String label, String value) {
    final selected = _filter == value;

    final Color selectedBg = widget.embedded ? kAccent : Colors.white;
    final Color unselectedBg = widget.embedded
        ? Colors.white
        : Colors.transparent;

    final Color selectedText = widget.embedded ? Colors.white : kAccent;
    final Color unselectedText = widget.embedded ? kPrimary : Colors.white;

    final Color selectedBorder = widget.embedded ? kAccent : Colors.white;
    final Color unselectedBorder = widget.embedded
        ? const Color(0xFFBBDEFB)
        : Colors.white54;

    return GestureDetector(
      onTap: () => _changeFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? selectedBorder : unselectedBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? selectedText : unselectedText,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData(defaultTextStyle: const pw.TextStyle(fontSize: 12)),
        header: (context) => pw.Container(
          color: PdfColor.fromHex('#1A3A6B'),
          padding: const pw.EdgeInsets.all(16),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Meal Report',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Daily goal: ${_summary.dailyCarbGoal.toInt()}g carbs',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              _pdfCard(
                'Total carbs',
                '${_summary.totalCarbs.toStringAsFixed(0)}g',
              ),
              pw.SizedBox(width: 8),
              _pdfCard(
                'Total insulin',
                '${_summary.totalInsulin.toStringAsFixed(0)}u',
              ),
              pw.SizedBox(width: 8),
              _pdfCard(
                'Daily average',
                '${_summary.dailyAverage.toStringAsFixed(0)}g',
              ),
              pw.SizedBox(width: 8),
              _pdfCard(
                'Highest day',
                '${_summary.highestDay.toStringAsFixed(0)}g',
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          ..._records.map((day) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  color: PdfColor.fromHex('#EAF2FF'),
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: pw.Text(
                    '${formatLongDate(day.date)} | ${day.totalCarbs.toStringAsFixed(1)}g carbs | ${day.totalInsulin.toStringAsFixed(0)}u insulin',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      color: PdfColor.fromHex('#1A3A6B'),
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                ...day.meals.map((meal) => _pdfMealBlock(meal)),
                pw.Divider(),
                pw.SizedBox(height: 10),
              ],
            );
          }),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _pdfCard(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#1A3A6B'),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfMealBlock(Meal meal) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#BBDEFB'), width: 1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#2B7FD4'),
              borderRadius: const pw.BorderRadius.only(
                topRight: pw.Radius.circular(6),
                topLeft: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${meal.name} (${mealTypeLabel(meal.mealType)})',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  '${meal.totalCarbs.toStringAsFixed(1)}g | ${meal.insulinUnits ?? 0}u',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('#E3F2FD'),
                width: 0.5,
              ),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#EAF2FF'),
                  ),
                  children: ['Ingredient', 'Amount', 'Carbs']
                      .map(
                        (h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            h,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                ...meal.ingredients.map(
                  (ing) => pw.TableRow(
                    children:
                        [
                              ing.name,
                              ing.amount,
                              '${ing.carbs.toStringAsFixed(1)}g',
                            ]
                            .map(
                              (value) => pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  value,
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool showBar;
  final double barValue;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    this.showBar = false,
    this.barValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    final unit = value.endsWith('g')
        ? 'g'
        : value.endsWith('u')
        ? 'u'
        : '';

    final numericValue = value.replaceAll('g', '').replaceAll('u', '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFAAC8EE), fontSize: 12),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                numericValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    ' $unit',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFAAC8EE), fontSize: 11),
          ),
          if (showBar) ...[
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: barValue.clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF64B5F6),
                ),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final List<DayRecord> data;

  const _ChartSection({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final highestValue = data
        .map((d) => d.totalCarbs)
        .reduce((a, b) => a > b ? a : b);

    final maxY = math.max(kGoal, highestValue + 40).ceilToDouble();
    final barWidth = data.length <= 4 ? 34.0 : 24.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily carbohydrates (g)',
            style: TextStyle(
              color: kAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 230,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: true),
                barGroups: data.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.totalCarbs,
                        color: kBar,
                        width: barWidth,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 40,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}g',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black45,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= data.length) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            formatShortDate(data[index].date),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 40,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealDetailsSection extends StatelessWidget {
  final List<DayRecord> data;

  const _MealDetailsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final sortedData = [...data]..sort((a, b) => b.date.compareTo(a.date));

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Meal details',
            style: TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),

          ...sortedData.map((day) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DayHeader(day: day),
                const SizedBox(height: 8),
                ...day.meals.map((meal) => _MealCard(meal: meal)),
                const SizedBox(height: 14),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DayRecord day;

  const _DayHeader({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatLongDate(day.date),
              style: const TextStyle(
                color: kPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${day.totalCarbs.toStringAsFixed(1)}g carbs · ${day.totalInsulin.toStringAsFixed(0)}u insulin',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatefulWidget {
  final Meal meal;

  const _MealCard({required this.meal});

  @override
  State<_MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<_MealCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBDEFB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.meal.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.meal.totalCarbs.toStringAsFixed(1)}g',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: kAccent,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Padding(
              padding: const EdgeInsets.only(right: 14, left: 14, bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.restaurant, size: 14, color: kAccent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${mealTypeLabel(widget.meal.mealType)} · Serving: ${widget.meal.serving.isEmpty ? '-' : widget.meal.serving}',
                      style: const TextStyle(color: kAccent, fontSize: 12),
                    ),
                  ),
                  if (widget.meal.insulinUnits != null)
                    Text(
                      'Insulin: ${widget.meal.insulinUnits}u',
                      style: const TextStyle(
                        color: kPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              color: const Color(0xFFF0F7FF),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Ingredient',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Amount',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Carbs',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...widget.meal.ingredients.map(
              (ingredient) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade100, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        ingredient.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        ingredient.amount,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${ingredient.carbs.toStringAsFixed(1)}g',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 13,
                          color: kAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
