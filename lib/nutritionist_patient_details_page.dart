import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'meals_report.dart';
import 'reports_screen.dart';

class NutritionistPatientDetailsPage extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String nutritionistId;

  const NutritionistPatientDetailsPage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.nutritionistId,
  });

  @override
  State<NutritionistPatientDetailsPage> createState() =>
      _NutritionistPatientDetailsPageState();
}

class _NutritionistPatientDetailsPageState
    extends State<NutritionistPatientDetailsPage> {
  final Color primaryBlue = const Color(0xFF0D8BFF);
  final Color deepBlue = const Color(0xFF0A4FA3);
  final Color pageBg = const Color(0xFFEAF6FF);
  final Color cardBg = const Color(0xFFF8FCFF);
  final Color darkText = const Color(0xFF102A43);
  final Color subText = const Color(0xFF5F7896);
  final Color borderColor = const Color(0xFFBFDFFF);

  bool isLoading = true;

  Map<String, dynamic>? patientProfile;
  List<dynamic> glucoseReadings = [];
  List<dynamic> meals = [];

  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    return 'http://10.0.2.2:5000';
  }

  @override
  void initState() {
    super.initState();
    fetchPatientDetails();
  }

  Future<void> fetchPatientDetails() async {
    try {
      setState(() {
        isLoading = true;
      });

      await Future.wait([
        fetchPatientProfile(),
        fetchGlucoseReadings(),
        fetchMeals(),
      ]);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading patient details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchPatientProfile() async {
    try {
      final url = Uri.parse('$baseUrl/api/patient/${widget.patientId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          patientProfile = data['profile'] ?? data;
        }
      } else {
        debugPrint('Failed to fetch patient profile: ${response.body}');
      }
    } catch (e) {
      debugPrint('Patient profile error: $e');
    }
  }

  Future<void> fetchGlucoseReadings() async {
    try {
      final url = Uri.parse('$baseUrl/api/glucose/${widget.patientId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          glucoseReadings = data;
        } else if (data is Map<String, dynamic>) {
          glucoseReadings = data['readings'] ?? data['data'] ?? [];
        }
      } else {
        debugPrint('Failed to fetch glucose: ${response.body}');
      }
    } catch (e) {
      debugPrint('Glucose error: $e');
    }
  }

  Future<void> fetchMeals() async {
    try {
      final url = Uri.parse('$baseUrl/api/meals/${widget.patientId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          meals = data;
        } else if (data is Map<String, dynamic>) {
          meals = data['meals'] ?? data['data'] ?? [];
        }
      } else {
        debugPrint('Failed to fetch meals: ${response.body}');
      }
    } catch (e) {
      debugPrint('Meals error: $e');
    }
  }

  String get initials {
    final parts = widget.patientName.trim().split(' ');
    if (widget.patientName.trim().isEmpty) return 'P';

    final first = parts.isNotEmpty && parts[0].isNotEmpty
        ? parts[0][0].toUpperCase()
        : '';
    final last = parts.length > 1 && parts[1].isNotEmpty
        ? parts[1][0].toUpperCase()
        : '';

    final result = '$first$last';
    return result.isNotEmpty ? result : 'P';
  }

  num? get lastGlucose {
    if (cleanedGlucoseReadings.isEmpty) return null;

    final sorted = [...cleanedGlucoseReadings];

    sorted.sort((a, b) => _readingTime(b).compareTo(_readingTime(a)));

    return _readingValue(sorted.first);
  }

  double get sevenDayAverage {
    if (weeklySummaryReadings.isEmpty) return 0;

    final values = weeklySummaryReadings.map(_readingValue).toList();

    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }

  int get highCount {
    return weeklySummaryReadings.where((reading) {
      return _readingValue(reading) > 180;
    }).length;
  }

  int get lowCount {
    return weeklySummaryReadings.where((reading) {
      return _readingValue(reading) < 70;
    }).length;
  }

  DateTime _dateOnly(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  String _secondKey(DateTime time) {
    return '${time.year}-${time.month}-${time.day} '
        '${time.hour}:${time.minute}:${time.second}';
  }

  double _readingValue(dynamic reading) {
    final raw = reading['value'] ?? reading['glucose'];
    return raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0;
  }

  DateTime _readingTime(dynamic reading) {
    return DateTime.tryParse(reading['readingTime']?.toString() ?? '') ??
        DateTime.tryParse(reading['createdAt']?.toString() ?? '') ??
        DateTime(2000);
  }

  bool _isSuspiciousJump(dynamic prev, dynamic curr) {
    final prevTime = _readingTime(prev);
    final currTime = _readingTime(curr);

    final seconds = currTime.difference(prevTime).inSeconds.abs();
    if (seconds <= 0) return false;

    final minutes = seconds / 60.0;
    final delta = (_readingValue(curr) - _readingValue(prev)).abs();
    final rate = delta / minutes;

    if (minutes <= 2 && delta >= 120) return true;
    if (minutes <= 5 && rate >= 60) return true;

    return false;
  }

  List<dynamic> get cleanedGlucoseReadings {
    final sorted = [...glucoseReadings];

    sorted.sort((a, b) {
      final timeCompare = _readingTime(a).compareTo(_readingTime(b));
      if (timeCompare != 0) return timeCompare;

      final aCreated =
          DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
          _readingTime(a);
      final bCreated =
          DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
          _readingTime(b);

      return aCreated.compareTo(bCreated);
    });

    final latestBySecond = <String, dynamic>{};

    for (final reading in sorted) {
      latestBySecond[_secondKey(_readingTime(reading))] = reading;
    }

    final cleaned = latestBySecond.values.toList()
      ..sort((a, b) => _readingTime(a).compareTo(_readingTime(b)));

    final visible = <dynamic>[];

    for (final reading in cleaned) {
      if (visible.isEmpty) {
        visible.add(reading);
        continue;
      }

      final prev = visible.last;

      if (!_isSuspiciousJump(prev, reading)) {
        visible.add(reading);
      }
    }

    return visible;
  }

  List<dynamic> get weeklySummaryReadings {
    final now = DateTime.now();
    final from = _dateOnly(now).subtract(const Duration(days: 6));
    final to = _dateOnly(now).add(const Duration(days: 1));

    return cleanedGlucoseReadings.where((reading) {
      final date = _readingTime(reading);
      return !date.isBefore(from) && date.isBefore(to);
    }).toList();
  }

  Map<String, dynamic>? get lastMeal {
    if (meals.isEmpty) return null;

    final sorted = [...meals];

    sorted.sort((a, b) {
      final aTime =
          DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
          DateTime.tryParse(a['mealTime']?.toString() ?? '') ??
          DateTime(2000);

      final bTime =
          DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
          DateTime.tryParse(b['mealTime']?.toString() ?? '') ??
          DateTime(2000);

      return bTime.compareTo(aTime);
    });

    return Map<String, dynamic>.from(sorted.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryBlue))
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            _buildHeaderCard(),
                            const SizedBox(height: 18),
                            Container(
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: borderColor),
                              ),
                              child: TabBar(
                                labelColor: deepBlue,
                                unselectedLabelColor: subText,
                                indicatorColor: deepBlue,
                                tabs: const [
                                  Tab(text: 'Summary'),
                                  Tab(text: 'Glucose Report'),
                                  Tab(text: 'Meal Report'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildSummaryTab(),
                                  ReportsScreen(
                                    userId: widget.patientId,
                                    embedded: true,
                                  ),
                                  MealReportScreen(
                                    patientId: widget.patientId,
                                    openedFromNutritionist: true,
                                    embedded: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAFF),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_rounded, color: deepBlue),
          ),
          const SizedBox(width: 8),
          Text(
            'Patient Details',
            style: TextStyle(
              color: darkText,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: fetchPatientDetails,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: deepBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: const Color(0xFFDFF1FF),
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF0A4FA3),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.patientName,
                style: TextStyle(
                  color: darkText,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    final profile = patientProfile ?? {};

    final weight = profile['weight']?.toString() ?? '-';
    final height = profile['height']?.toString() ?? '-';
    final diagnosisDate = _formatDate(
      profile['diagnosisDate']?.toString() ?? '',
    );

    final managementType = profile['managementType']?.toString() ?? '-';

    final carbRatio = profile['carbRatio']?.toString().trim() ?? '';
    final correctionFactor =
        profile['correctionFactor']?.toString().trim() ?? '';

    final hasFoodAllergy = profile['hasFoodAllergy'] == true;
    final allergyDetails = profile['allergyDetails']?.toString().trim() ?? '';

    final usesRapidInsulin = profile['usesRapidInsulin'] == true;
    final usesBasalInsulin = profile['usesBasalInsulin'] == true;
    final usesMixedInsulin = profile['usesMixedInsulin'] == true;
    final usesPump = profile['usesPump'] == true;
    final usesPills = profile['usesPills'] == true;
    final usesOtherTreatment = profile['usesOtherTreatment'] == true;
    final otherTreatmentName =
        profile['otherTreatmentName']?.toString().trim() ?? '';

    final breakfastDose = profile['breakfastDose']?.toString() ?? '-';
    final lunchDose = profile['lunchDose']?.toString() ?? '-';
    final dinnerDose = profile['dinnerDose']?.toString() ?? '-';
    final lantusDose = profile['lantusDose']?.toString() ?? '-';

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Last Glucose',
                  lastGlucose != null ? '${lastGlucose!.round()} mg/dL' : '-',
                  Icons.bloodtype_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  '7-Day Average',
                  sevenDayAverage > 0
                      ? '${sevenDayAverage.round()} mg/dL'
                      : '-',
                  Icons.show_chart_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  'High Readings',
                  highCount.toString(),
                  Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  'Low Readings',
                  lowCount.toString(),
                  Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildSectionCard(
            title: 'Patient Overview',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildProfileInfo('Weight', '$weight kg')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildProfileInfo('Height', '$height cm')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileInfo(
                        'Diagnosis Date',
                        diagnosisDate.isNotEmpty ? diagnosisDate : '-',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProfileInfo(
                        'Management Type',
                        managementType.isNotEmpty ? managementType : '-',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildSectionCard(
            title: 'Nutrition Important Info',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileInfo(
                        'Carb Ratio',
                        carbRatio.isNotEmpty ? carbRatio : '-',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProfileInfo(
                        'Correction Factor',
                        correctionFactor.isNotEmpty ? correctionFactor : '-',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileInfo(
                        'Food Allergy',
                        hasFoodAllergy ? 'Yes' : 'No',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProfileInfo(
                        'Allergy Details',
                        hasFoodAllergy && allergyDetails.isNotEmpty
                            ? allergyDetails
                            : '-',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildSectionCard(
            title: 'Treatment Info',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileInfo(
                        'Rapid Insulin',
                        usesRapidInsulin ? 'Yes' : 'No',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProfileInfo(
                        'Basal Insulin',
                        usesBasalInsulin ? 'Yes' : 'No',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileInfo(
                        'Mixed Insulin',
                        usesMixedInsulin ? 'Yes' : 'No',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProfileInfo('Pump', usesPump ? 'Yes' : 'No'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileInfo(
                        'Pills',
                        usesPills ? 'Yes' : 'No',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProfileInfo(
                        'Other Treatment',
                        usesOtherTreatment
                            ? (otherTreatmentName.isNotEmpty
                                  ? otherTreatmentName
                                  : 'Yes')
                            : 'No',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildSectionCard(
            title: 'Meal Doses',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileInfo(
                        'Breakfast Dose',
                        breakfastDose == 'null' ? '-' : breakfastDose,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProfileInfo(
                        'Lunch Dose',
                        lunchDose == 'null' ? '-' : lunchDose,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileInfo(
                        'Dinner Dose',
                        dinnerDose == 'null' ? '-' : dinnerDose,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProfileInfo(
                        'Lantus Dose',
                        lantusDose == 'null' ? '-' : lantusDose,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlucoseReportTab() {
    if (glucoseReadings.isEmpty) {
      return _buildEmptyState('No glucose readings found.');
    }

    return SingleChildScrollView(
      child: _buildSectionCard(
        title: 'Glucose Readings Report',
        child: Column(
          children: [
            _buildReportHeader(['Value', 'Type', 'Date', 'Note']),
            ...glucoseReadings.take(20).map((reading) {
              final value =
                  reading['value']?.toString() ??
                  reading['glucose']?.toString() ??
                  '-';
              final type = reading['readingType']?.toString() ?? '-';
              final date =
                  reading['readingTime']?.toString() ??
                  reading['createdAt']?.toString() ??
                  '-';
              final note = reading['note']?.toString() ?? '-';

              return _buildReportRow([
                '$value mg/dL',
                type,
                _formatDate(date),
                note,
              ]);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMealReportTab() {
    if (meals.isEmpty) {
      return _buildEmptyState('No meals found.');
    }

    return SingleChildScrollView(
      child: _buildSectionCard(
        title: 'Meal Report',
        child: Column(
          children: [
            _buildReportHeader(['Meal', 'Carbs', 'Insulin', 'Date']),
            ...meals.take(20).map((meal) {
              final mealType = meal['mealType']?.toString() ?? '-';
              final carbs =
                  meal['carbs']?.toString() ??
                  meal['carbsGrams']?.toString() ??
                  '-';
              final insulin =
                  meal['insulin']?.toString() ??
                  meal['insulinUnits']?.toString() ??
                  '-';
              final date =
                  meal['createdAt']?.toString() ??
                  meal['mealTime']?.toString() ??
                  '-';

              return _buildReportRow([
                mealType,
                '$carbs g',
                '$insulin units',
                _formatDate(date),
              ]);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF1FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: TextStyle(color: subText, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: darkText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildProfileInfo(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: subText, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: darkText,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportHeader(List<String> titles) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF1FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: titles
            .map(
              (title) => Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: darkText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildReportRow(List<String> values) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: values
            .map(
              (value) => Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: darkText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          color: subText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(String rawDate) {
    if (rawDate.trim().isEmpty) return '-';

    final date = DateTime.tryParse(rawDate);
    if (date == null) return rawDate;

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: borderColor),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0D47A1),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    );
  }
}
