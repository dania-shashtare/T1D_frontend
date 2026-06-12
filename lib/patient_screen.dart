import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_settings_provider.dart';
import 'services/glucose_api.dart';

import 'barcode_product_result_screen.dart';
import 'barcode_scanner_screen.dart';
import 'food_product.dart';
import 'low_glucose_screen.dart';
import 'services/onboarding_api.dart';
import 'services/openfoodfacts_service.dart';

import 'notifications_screen.dart';
import 'high_glucose_screen.dart';
import 'reports_screen.dart';

import 'activity_screen.dart';
import 'MealSuggestionScreen.dart';
import 'profile_page.dart';
import 'chat.dart';
import 'meal_logger.dart';
import 'meals_report.dart';
import 'water_tracker_page.dart';
import 'notification_service.dart';
import 'services/profile_api.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'contact_nutritionist_page.dart';
import 'contact_doctor_page.dart';
import 'contact_specialists_page.dart';
import 'patient_assigned_meal_plans_page.dart';

import 'services/family_api.dart';
import 'services/appointment_reminder_api.dart';
import 'services/appointment_reminder_service.dart';

import 'patient_settings_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  final String userId;

  const PatientHomeScreen({super.key, required this.userId});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen>
    with SingleTickerProviderStateMixin {
  double? currentGlucose;
  String glucoseStatus = '';
  String lastReading = '';
  Color statusColor = const Color(0xff1D9E75);

  int selectedNavIndex = 0;

  final TextEditingController _glucoseController = TextEditingController();
  List<GlucoseReading> readings = [];
  double? patientCorrectionFactor;
  final double patientTargetGlucose = 120;

  late final AnimationController _mascotController;

  static const int _baseChartPage = 5000;
  final PageController _chartDayController = PageController(
    initialPage: _baseChartPage,
  );

  DateTime selectedChartDay = DateTime.now();

  final List<Map<String, dynamic>> meals = [
    {
      'title': 'Breakfast',
      'icon': Icons.free_breakfast_rounded,
      'status': 'Not added yet',
    },
    {
      'title': 'Morning Snack',
      'icon': Icons.cookie_rounded,
      'status': 'Not added yet',
    },
    {
      'title': 'Lunch',
      'icon': Icons.lunch_dining_rounded,
      'status': 'Not added yet',
    },
    {
      'title': 'Afternoon Snack',
      'icon': Icons.icecream_rounded,
      'status': 'Not added yet',
    },
    {
      'title': 'Dinner',
      'icon': Icons.dinner_dining_rounded,
      'status': 'Not added yet',
    },
  ];

  static const Color _softBlue = Color(0xffEEF7FF);
  static const Color _softBlue2 = Color(0xffDCEEFF);
  static const Color _mainBlue = Color(0xff185FA5);
  static const Color _textBlue = Color(0xff0C447C);

  static const Color _darkBg = Color(0xff071A2F);
  static const Color _darkCard = Color(0xff102A46);
  static const Color _darkSoft = Color(0xff183A5C);
  static const Color _darkIconBg = Color(0xff173A5E);
  static const Color _darkText = Colors.white;
  static const Color _darkSubText = Color(0xffAFC7DD);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBg => _isDark ? _darkBg : const Color(0xffEAF6FF);
  Color get _cardColor => _isDark ? _darkCard : Colors.white;
  Color get _softCardColor => _isDark ? _darkSoft : _softBlue;
  Color get _iconBgColor => _isDark ? _darkIconBg : _softBlue2;
  Color get _titleColor => _isDark ? _darkText : _textBlue;
  Color get _subtitleColor => _isDark ? _darkSubText : const Color(0xff7A9AB5);
  Color get _sheetBgColor =>
      _isDark ? const Color(0xff0D223A) : const Color(0xffF9FCFF);
  Color get _borderColor =>
      _isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05);
  Color get _tileBorderColor =>
      _isDark ? Colors.white.withOpacity(0.08) : const Color(0xffD8EBFF);

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'welcomeBack': 'Welcome back',
      'todayOverview': "Today's overview",
      'currentGlucose': 'CURRENT GLUCOSE',
      'mgdl': 'mg/dL',
      'noReadingsYet':
          'No readings yet.\nAdd your first glucose reading below.',
      'noReadingsDay': 'No valid readings for this day.',
      'noReadingsYetStatus': 'No readings yet',
      'noValidReadings': 'No valid readings',
      'lowCheckNow': 'Low · check now',
      'highTakeAction': 'High · take action',
      'slightlyHigh': 'Slightly high',
      'inRange': 'In Range',
      'justNow': 'just now',
      'minAgo': 'min ago',
      'hAgo': 'h ago',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'tomorrow': 'Tomorrow',
      'readings': 'readings',
      'hourChart': '24-hour chart',
      'enterMgdl': 'Enter mg/dL...',
      'add': 'Add',
      'meals': 'Meals',
      'tapToAdd': 'Tap to add',
      'notAddedYet': 'Not added yet',
      'breakfast': 'Breakfast',
      'morningSnack': 'Morning Snack',
      'lunch': 'Lunch',
      'afternoonSnack': 'Afternoon Snack',
      'dinner': 'Dinner',
      'home': 'Home',
      'reports': 'Reports',
      'menu': 'Menu',
      'doctor': 'Doctor',
      'contact': 'Contact',
      'chatAsk': 'Chat / Ask anything',
      'mealPlans': 'Meal Plans',
      'nutritionist': 'Nutritionist',
      'water': 'Water',
      'activity': 'Activity',
      'settings': 'Settings',
      'whoContact': 'Who do you want to contact?',
      'doctorContactSub': 'Choose a doctor and start chatting',
      'nutritionistContactSub': 'Choose a nutritionist and start chatting',
      'chooseContinue': 'Choose how you want to continue',
      'addMyMeal': 'Add my meal',
      'addMyMealSub': 'Enter your meal and calculate carbs',
      'scanBarcode': 'Scan barcode',
      'scanBarcodeSub': 'Scan packaged food',
      'suggestMeal': 'Suggest a meal',
      'suggestMealSub': "Get meal ideas if you're not sure",
      'productNotFound': 'Product not found',
      'validGlucose': 'Please enter a valid glucose reading.',
      'unusualReading':
          'This reading looks unusual and was ignored on the chart.',
      'failedSave': 'Failed to save reading',
      'readingInRange': 'This reading is in range',
      'doctorAppointmentNow': 'Doctor appointment now',
      'doctorAppointmentBody': 'Your appointment with {name} is starting now.',
      'nutritionistAppointmentNow': 'Nutritionist appointment now',
      'nutritionistAppointmentBody':
          'Your appointment with {name} is starting now.',
      'yourDoctor': 'your doctor',
      'yourNutritionist': 'your nutritionist',
    },
    'ar': {
      'welcomeBack': 'أهلًا بعودتك',
      'todayOverview': 'ملخص اليوم',
      'currentGlucose': 'السكر الحالي',
      'mgdl': 'ملغم/دل',
      'noReadingsYet': 'لا توجد قراءات بعد.\nأضيفي أول قراءة سكر بالأسفل.',
      'noReadingsDay': 'لا توجد قراءات صالحة لهذا اليوم.',
      'noReadingsYetStatus': 'لا توجد قراءات بعد',
      'noValidReadings': 'لا توجد قراءات صالحة',
      'lowCheckNow': 'منخفض · افحصي الآن',
      'highTakeAction': 'مرتفع · اتخذي إجراء',
      'slightlyHigh': 'مرتفع قليلًا',
      'inRange': 'ضمن المعدل',
      'justNow': 'الآن',
      'minAgo': 'دقيقة مضت',
      'hAgo': 'ساعة مضت',
      'today': 'اليوم',
      'yesterday': 'أمس',
      'tomorrow': 'غدًا',
      'readings': 'قراءات',
      'hourChart': 'مخطط 24 ساعة',
      'enterMgdl': 'أدخلي ملغم/دل...',
      'add': 'إضافة',
      'meals': 'الوجبات',
      'tapToAdd': 'اضغطي للإضافة',
      'notAddedYet': 'لم تتم الإضافة بعد',
      'breakfast': 'الفطور',
      'morningSnack': 'سناك صباحي',
      'lunch': 'الغداء',
      'afternoonSnack': 'سناك مسائي',
      'dinner': 'العشاء',
      'home': 'الرئيسية',
      'reports': 'التقارير',
      'menu': 'القائمة',
      'doctor': 'الطبيب',
      'contact': 'التواصل',
      'chatAsk': 'الدردشة / اسألي أي شيء',
      'mealPlans': 'خطط الوجبات',
      'nutritionist': 'أخصائي التغذية',
      'water': 'الماء',
      'activity': 'النشاط',
      'settings': 'الإعدادات',
      'whoContact': 'مع من تريدين التواصل؟',
      'doctorContactSub': 'اختاري طبيبًا وابدئي المحادثة',
      'nutritionistContactSub': 'اختاري أخصائي تغذية وابدئي المحادثة',
      'chooseContinue': 'اختاري طريقة المتابعة',
      'addMyMeal': 'إضافة وجبتي',
      'addMyMealSub': 'أدخلي وجبتك واحسبي الكربوهيدرات',
      'scanBarcode': 'مسح الباركود',
      'scanBarcodeSub': 'مسح طعام مغلف',
      'suggestMeal': 'اقتراح وجبة',
      'suggestMealSub': 'احصلي على أفكار وجبات عند الحيرة',
      'productNotFound': 'لم يتم العثور على المنتج',
      'validGlucose': 'يرجى إدخال قراءة سكر صحيحة.',
      'unusualReading': 'هذه القراءة تبدو غير طبيعية وتم تجاهلها في المخطط.',
      'failedSave': 'فشل حفظ القراءة',
      'readingInRange': 'هذه القراءة ضمن المعدل',
      'doctorAppointmentNow': 'موعد الطبيب الآن',
      'doctorAppointmentBody': 'موعدك مع {name} يبدأ الآن.',
      'nutritionistAppointmentNow': 'موعد أخصائي التغذية الآن',
      'nutritionistAppointmentBody': 'موعدك مع {name} يبدأ الآن.',
      'yourDoctor': 'طبيبك',
      'yourNutritionist': 'أخصائي التغذية',
    },
  };

  String get _lang => context.read<AppSettingsProvider>().language;
  bool get _isArabic => _lang == 'ar';
  TextDirection get _pageDirection =>
      _isArabic ? TextDirection.rtl : TextDirection.ltr;

  String t(String key) {
    return _strings[_lang]?[key] ?? _strings['en']?[key] ?? key;
  }

  String _trMealTitle(String title) {
    switch (title) {
      case 'Breakfast':
        return t('breakfast');
      case 'Morning Snack':
        return t('morningSnack');
      case 'Lunch':
        return t('lunch');
      case 'Afternoon Snack':
        return t('afternoonSnack');
      case 'Dinner':
        return t('dinner');
      default:
        return title;
    }
  }

  String _trStatus(String status) {
    if (status == 'Not added yet') return t('notAddedYet');
    return status;
  }

  @override
  void initState() {
    super.initState();

    selectedChartDay = _dateOnly(DateTime.now());

    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _scheduleLantusFromProfile();
    _loadPatientProfile();
    _loadReadings();
    _schedulePatientAppointmentReminders();
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _sheetBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t('whoContact'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 20),

              _contactOptionTile(
                context: context,
                icon: Icons.medical_services_outlined,
                title: t('doctor'),
                subtitle: t('doctorContactSub'),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ContactSpecialistsPage(
                        role: 'doctor',
                        currentUserId: widget.userId,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _contactOptionTile(
                context: context,
                icon: Icons.restaurant_menu_outlined,
                title: t('nutritionist'),
                subtitle: t('nutritionistContactSub'),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ContactSpecialistsPage(
                        role: 'nutritionist',
                        currentUserId: widget.userId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _contactOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _softCardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _tileBorderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: _mainBlue, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: _subtitleColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: _isDark
                  ? const Color(0xff8CC7F5)
                  : const Color(0xFF8CC7F5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _glucoseController.dispose();
    _mascotController.dispose();
    _chartDayController.dispose();
    super.dispose();
  }

  Color _getGlucoseColor(double v) {
    if (v < 70 || v > 180) return const Color(0xffE24B4A);
    if (v > 140) return const Color(0xffEF9F27);
    return const Color(0xff1D9E75);
  }

  String _getGlucoseStatus(double v) {
    if (v < 70) return t('lowCheckNow');
    if (v > 180) return t('highTakeAction');
    if (v > 140) return t('slightlyHigh');
    return t('inRange');
  }

  String _displayGlucoseValue(double? value) {
    if (value == null) return '--';
    if (value < 40) return 'LO';
    if (value > 400) return 'HI';
    return value.toStringAsFixed(0);
  }

  String _displayReadingValue(double value) {
    if (value < 40) return 'LO';
    if (value > 400) return 'HI';
    return value.toStringAsFixed(0);
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return t('justNow');
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${t('minAgo')}';
    if (diff.inHours < 24) return '${diff.inHours} ${t('hAgo')}';
    return _formatTime(dateTime);
  }

  String _getMascotPath() {
    if (currentGlucose == null) {
      return 'lib/assets/images/sugerhappy.png';
    }
    if (currentGlucose! < 70) {
      return 'lib/assets/images/low_mascot.png';
    }
    if (currentGlucose! > 180) {
      return 'lib/assets/images/mascot_high.png';
    }
    return 'lib/assets/images/sugerhappy.png';
  }

  DateTime _dateOnly(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _dayOffsetFromToday(DateTime day) {
    final today = _dateOnly(DateTime.now());
    final cleanDay = _dateOnly(day);
    return cleanDay.difference(today).inDays;
  }

  int _compareReadings(GlucoseReading a, GlucoseReading b) {
    final timeCompare = a.time.compareTo(b.time);

    if (timeCompare != 0) return timeCompare;

    final aCreated = a.createdAt ?? a.time;
    final bCreated = b.createdAt ?? b.time;

    return aCreated.compareTo(bCreated);
  }

  String _secondKey(DateTime time) {
    return '${time.year}-${time.month}-${time.day} '
        '${time.hour}:${time.minute}:${time.second}';
  }

  double _timeToX(DateTime time) {
    return time.hour + (time.minute / 60.0) + (time.second / 3600.0);
  }

  bool _isSuspiciousJump(GlucoseReading prev, GlucoseReading curr) {
    final seconds = curr.time.difference(prev.time).inSeconds.abs();
    if (seconds <= 0) return false;

    final minutes = seconds / 60.0;
    final delta = (curr.value - prev.value).abs();
    final rate = delta / minutes;

    if (minutes <= 2 && delta >= 120) return true;
    if (minutes <= 5 && rate >= 60) return true;

    return false;
  }

  List<PreparedReading> _prepareReadingsList(List<GlucoseReading> source) {
    final list = List<GlucoseReading>.from(source);
    list.sort(_compareReadings);

    final Map<String, GlucoseReading> latestBySecond = {};

    for (final reading in list) {
      latestBySecond[_secondKey(reading.time)] = reading;
    }

    final cleaned = latestBySecond.values.toList();
    cleaned.sort(_compareReadings);

    final List<PreparedReading> prepared = [];

    for (int i = 0; i < cleaned.length; i++) {
      final current = cleaned[i];

      bool suspicious = false;
      if (i > 0) {
        final prevVisible = prepared
            .where((e) => !e.suspicious)
            .map((e) => e.reading)
            .toList();

        if (prevVisible.isNotEmpty) {
          suspicious = _isSuspiciousJump(prevVisible.last, current);
        }
      }

      prepared.add(PreparedReading(reading: current, suspicious: suspicious));
    }

    return prepared;
  }

  List<PreparedReading> _prepareReadingsForDay(DateTime day) {
    final list = readings.where((r) => _isSameDay(r.time, day)).toList();
    return _prepareReadingsList(list);
  }

  List<PreparedReading> _visiblePrepared(List<PreparedReading> items) {
    return items.where((e) => !e.suspicious).toList();
  }

  List<List<FlSpot>> _buildLineSegments(List<PreparedReading> items) {
    final visibleItems = _visiblePrepared(items);

    final List<List<FlSpot>> segments = [];
    final List<FlSpot> current = [];

    for (final item in visibleItems) {
      current.add(FlSpot(_timeToX(item.reading.time), item.reading.value));
    }

    if (current.length >= 2) {
      segments.add(current);
    }

    return segments;
  }

  List<FlSpot> _normalSpots(List<PreparedReading> items) {
    return _visiblePrepared(
      items,
    ).map((e) => FlSpot(_timeToX(e.reading.time), e.reading.value)).toList();
  }

  PreparedReading? _preparedReadingForSpot(
    FlSpot spot,
    List<PreparedReading> items,
  ) {
    final visibleItems = _visiblePrepared(items);

    if (visibleItems.isEmpty) return null;

    PreparedReading? closest;
    double bestDistance = double.infinity;

    for (final item in visibleItems) {
      final x = _timeToX(item.reading.time);
      final y = item.reading.value;

      final dx = (x - spot.x).abs();
      final dy = (y - spot.y).abs();
      final distance = dx + (dy / 1000);

      if (distance < bestDistance) {
        bestDistance = distance;
        closest = item;
      }
    }

    return closest;
  }

  double _minYForPrepared(List<PreparedReading> items) {
    final visibleItems = _visiblePrepared(items);

    if (visibleItems.isEmpty) return 40;

    final minVal = visibleItems
        .map((e) => e.reading.value)
        .reduce((a, b) => a < b ? a : b);

    final safeMin = math.min(minVal, 70.0);
    return (safeMin - 25).clamp(0, 350).toDouble();
  }

  double _maxYForPrepared(List<PreparedReading> items) {
    final visibleItems = _visiblePrepared(items);

    if (visibleItems.isEmpty) return 220;

    final maxVal = visibleItems
        .map((e) => e.reading.value)
        .reduce((a, b) => a > b ? a : b);

    final safeMax = math.max(maxVal, 180.0);
    return (safeMax + 25).clamp(90, 620).toDouble();
  }

  String _formatChartDay(DateTime day) {
    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    if (_isSameDay(day, today)) return t('today');
    if (_isSameDay(day, yesterday)) return t('yesterday');
    if (_isSameDay(day, tomorrow)) return t('tomorrow');

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

    return '${months[day.month - 1]} ${day.day}, ${day.year}';
  }

  void _goToPreviousDay() {
    _chartDayController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goToNextDay() {
    _chartDayController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _scheduleLantusFromProfile() async {
    try {
      final data = await ProfileApi.getProfile(widget.userId);

      final lantusTime = data.lantusTime;

      if (lantusTime == null || lantusTime.trim().isEmpty) {
        print('NO LANTUS TIME FOUND');
        return;
      }

      final cleanedTime = lantusTime.trim().toUpperCase();

      final isPm = cleanedTime.contains('PM');
      final isAm = cleanedTime.contains('AM');

      final timeOnly = cleanedTime
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim();

      final parts = timeOnly.split(':');

      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (isPm && hour != 12) {
        hour += 12;
      }

      if (isAm && hour == 12) {
        hour = 0;
      }

      print('BEFORE CALLING NOTIFICATION SERVICE');

      try {
        await NotificationService.scheduleLantusNotification(
          userId: widget.userId,
          hour: hour,
          minute: minute,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('daily_lantus')
            .doc(_todayKey())
            .set({
              'scheduledTime': lantusTime,
              'taken': false,
              'familyAlertSent': false,
              'date': _todayKey(),
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        _scheduleFamilyLantusMissedCheck(
          hour: hour,
          minute: minute,
          scheduledTimeText: lantusTime,
        );

        print('AFTER CALLING NOTIFICATION SERVICE');
      } catch (e) {
        print('NOTIFICATION SERVICE ERROR: $e');
      }

      print('LANTUS SCHEDULED FROM PATIENT HOME AT: $hour:$minute');
    } catch (e) {
      print('FAILED TO SCHEDULE LANTUS FROM HOME: $e');
    }
  }

  void _scheduleFamilyLantusMissedCheck({
    required int hour,
    required int minute,
    required String scheduledTimeText,
  }) {
    final now = DateTime.now();

    DateTime scheduled = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final checkTime = scheduled.add(const Duration(minutes: 10));
    final delay = checkTime.difference(now);

    print(
      'FAMILY LANTUS MISSED CHECK SCHEDULED AFTER: ${delay.inMinutes} minutes',
    );

    Future.delayed(delay, () async {
      try {
        final todayKey = _todayKey();

        final lantusDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('daily_lantus')
            .doc(todayKey);

        final lantusDoc = await lantusDocRef.get();

        final data = lantusDoc.data();

        final taken = data?['taken'] == true;
        final familyAlertSent = data?['familyAlertSent'] == true;

        if (taken || familyAlertSent) {
          print(
            'LANTUS FAMILY ALERT NOT SENT: taken=$taken, familyAlertSent=$familyAlertSent',
          );
          return;
        }

        await FamilyApi.notifyFamilyLantusMissed(
          patientId: widget.userId,
          scheduledTime: scheduledTimeText,
        );

        await lantusDocRef.set({
          'scheduledTime': scheduledTimeText,
          'taken': false,
          'familyAlertSent': true,
          'familyAlertSentAt': FieldValue.serverTimestamp(),
          'date': todayKey,
        }, SetOptions(merge: true));

        print('CRITICAL LANTUS ALERT SENT TO FAMILY');
      } catch (e) {
        debugPrint('Failed to send Lantus missed alert to family: $e');
      }
    });
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';
  }

  Future<void> _loadPatientProfile() async {
    try {
      final patientProfile = await OnboardingApi.getPatientProfile(
        userId: widget.userId,
      );

      if (patientProfile == null) return;

      setState(() {
        patientCorrectionFactor = double.tryParse(
          (patientProfile['correctionFactor'] ?? '').toString(),
        );
      });
    } catch (e) {
      debugPrint('Failed to load patient profile: $e');
    }
  }

  Future<void> _schedulePatientAppointmentReminders() async {
    try {
      final doctorAppointments =
          await AppointmentReminderApi.getPatientDoctorAppointments(
            widget.userId,
          );

      for (final appointment in doctorAppointments) {
        final doctor = appointment['doctorId'];

        final doctorName = doctor is Map
            ? '${doctor['firstName'] ?? ''} ${doctor['lastName'] ?? ''}'.trim()
            : t('yourDoctor');

        AppointmentReminderService.scheduleAppointment(
          id: 'patient-doctor-${appointment['_id']}',
          userId: widget.userId,
          day: appointment['day']?.toString() ?? '',
          time: appointment['time']?.toString() ?? '',
          title: t('doctorAppointmentNow'),
          body: t('doctorAppointmentBody').replaceAll('{name}', doctorName),
          type: 'doctor_appointment',
        );
      }

      final nutritionistAppointments =
          await AppointmentReminderApi.getPatientNutritionistAppointments(
            widget.userId,
          );

      for (final appointment in nutritionistAppointments) {
        final nutritionist = appointment['nutritionistId'];

        final nutritionistName = nutritionist is Map
            ? '${nutritionist['firstName'] ?? ''} ${nutritionist['lastName'] ?? ''}'
                  .trim()
            : t('yourNutritionist');

        AppointmentReminderService.scheduleAppointment(
          id: 'patient-nutritionist-${appointment['_id']}',
          userId: widget.userId,
          day: appointment['day']?.toString() ?? '',
          time: appointment['time']?.toString() ?? '',
          title: t('nutritionistAppointmentNow'),
          body: t(
            'nutritionistAppointmentBody',
          ).replaceAll('{name}', nutritionistName),
          type: 'nutritionist_appointment',
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule patient appointment reminders: $e');
    }
  }

  Future<void> _loadReadings() async {
    try {
      final data = await GlucoseApi.getReadings(widget.userId);

      final loaded = data.map((e) => GlucoseReading.fromApiJson(e)).toList();

      loaded.sort(_compareReadings);
      _reindexReadings(loaded);

      final preparedAll = _prepareReadingsList(loaded);
      final visibleAll = _visiblePrepared(preparedAll);

      final DateTime dayToShow = visibleAll.isNotEmpty
          ? _dateOnly(visibleAll.last.reading.time)
          : _dateOnly(DateTime.now());

      setState(() {
        readings = loaded;
        selectedChartDay = dayToShow;
        _refreshCurrentReading();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_chartDayController.hasClients) return;

        final page = _baseChartPage + _dayOffsetFromToday(dayToShow);
        _chartDayController.jumpToPage(page);
      });
    } catch (e) {
      debugPrint('Failed to load readings: $e');
    }
  }

  void _reindexReadings(List<GlucoseReading> list) {
    for (int i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(x: i.toDouble());
    }
  }

  void _refreshCurrentReading() {
    if (readings.isEmpty) {
      currentGlucose = null;
      glucoseStatus = t('noReadingsYetStatus');
      lastReading = '';
      statusColor = const Color(0xff1D9E75);
      return;
    }

    final preparedAll = _prepareReadingsList(readings);
    final visibleAll = _visiblePrepared(preparedAll);

    if (visibleAll.isEmpty) {
      currentGlucose = null;
      glucoseStatus = t('noValidReadings');
      lastReading = '';
      statusColor = const Color(0xff1D9E75);
      return;
    }

    final latest = visibleAll.last.reading;

    currentGlucose = latest.value;
    glucoseStatus = _getGlucoseStatus(latest.value);
    statusColor = _getGlucoseColor(latest.value);
    lastReading = _formatRelative(latest.time);
  }

  Future<void> _addReading() async {
    final val = double.tryParse(_glucoseController.text.trim());

    if (val == null || val < 1 || val > 600) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t('validGlucose'))));
      return;
    }

    try {
      final saved = await GlucoseApi.addReading(
        userId: widget.userId,
        value: val,
        readingTime: DateTime.now(),
      );

      await _sendFamilyGlucoseAlertIfNeeded(
        patientId: widget.userId,
        glucoseValue: val,
      );

      final newReading = GlucoseReading.fromApiJson(saved);

      setState(() {
        readings.add(newReading);
        readings.sort(_compareReadings);
        _reindexReadings(readings);

        final preparedAll = _prepareReadingsList(readings);
        final visibleAll = _visiblePrepared(preparedAll);

        selectedChartDay = visibleAll.isNotEmpty
            ? _dateOnly(visibleAll.last.reading.time)
            : _dateOnly(newReading.time);

        _refreshCurrentReading();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_chartDayController.hasClients) return;

        final page = _baseChartPage + _dayOffsetFromToday(selectedChartDay);
        _chartDayController.jumpToPage(page);
      });

      _glucoseController.clear();

      final preparedAll = _prepareReadingsList(readings);
      final visibleAll = _visiblePrepared(preparedAll);
      final isNewReadingVisible = visibleAll.any(
        (item) => item.reading.id == newReading.id,
      );

      if (!mounted) return;

      if (!isNewReadingVisible) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t('unusualReading'))));
        return;
      }

      if (val < 70) {
        await _openLowGlucoseScreen(
          readingId: saved['_id'].toString(),
          glucoseValue: val,
        );
      }

      if (val > 180) {
        _openHighGlucoseScreen(val);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${t('failedSave')}: $e')));
    }
  }

  Future<void> _sendFamilyGlucoseAlertIfNeeded({
    required String patientId,
    required double glucoseValue,
  }) async {
    if (glucoseValue >= 70 && glucoseValue <= 180) {
      return;
    }

    try {
      await FamilyApi.notifyFamilyGlucose(
        patientId: patientId,
        glucoseValue: glucoseValue,
      );
    } catch (e) {
      debugPrint('Failed to notify family from backend: $e');
    }
  }

  Future<void> _openLowGlucoseScreen({
    required String readingId,
    required double glucoseValue,
  }) async {
    final profile = await ProfileApi.getProfile(widget.userId);

    final double patientWeight =
        double.tryParse(profile.weight.toString()) ?? 50;

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LowGlucoseScreen(
          readingId: readingId,
          glucoseValue: glucoseValue,
          userId: widget.userId,
          patientWeightKg: patientWeight,
        ),
      ),
    );

    if (!mounted) return;

    if (result != null && result is Map && result['saved'] == true) {
      await _loadReadings();
    }
  }

  void _openHighGlucoseScreen(double glucoseValue) {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HighGlucoseScreen(
          glucoseValue: glucoseValue,
          userId: widget.userId,
          correctionFactor: patientCorrectionFactor,
          targetGlucose: patientTargetGlucose,
        ),
      ),
    );
  }

  Future<void> _openReadingFromChart(GlucoseReading reading) async {
    if (reading.id == null) return;

    if (reading.value < 70) {
      await _openLowGlucoseScreen(
        readingId: reading.id!,
        glucoseValue: reading.value,
      );
      return;
    }

    if (reading.value > 180) {
      _openHighGlucoseScreen(reading.value);
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${t('readingInRange')}: ${_displayReadingValue(reading.value)} ${t('mgdl')}',
        ),
      ),
    );
  }

  Widget _buildAnimatedMascot({double size = 118}) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _mascotController,
        builder: (context, child) {
          final t = _mascotController.value;
          double dy = 0;
          double dx = 0;
          double scale = 1;
          double angle = 0;

          if (currentGlucose == null) {
            dy = math.sin(t * 2 * math.pi) * 2.5;
          } else if (currentGlucose! < 70) {
            dy = math.sin(t * 2 * math.pi) * 4;
            dx = math.sin(t * 4 * math.pi) * 1.5;
            angle = math.sin(t * 4 * math.pi) * 0.015;
          } else if (currentGlucose! > 180) {
            dy = math.sin(t * 2 * math.pi) * 3;
            scale = 1 + (math.sin(t * 2 * math.pi) * 0.02);
          } else {
            dy = math.sin(t * 2 * math.pi) * 2.5;
            angle = math.sin(t * 2 * math.pi) * 0.008;
          }

          return Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: Image.asset(
          _getMascotPath(),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white70,
              size: 50,
            );
          },
        ),
      ),
    );
  }

  List<LineTooltipItem?> _buildTooltipItems(
    List<LineBarSpot> touchedSpots,
    List<PreparedReading> prepared,
  ) {
    final List<LineTooltipItem?> items = [];

    for (int i = 0; i < touchedSpots.length; i++) {
      if (i > 0) {
        items.add(null);
        continue;
      }

      final touched = touchedSpots[i];
      final item = _preparedReadingForSpot(touched, prepared);

      if (item == null) {
        items.add(null);
        continue;
      }

      final reading = item.reading;

      items.add(
        LineTooltipItem(
          '${_displayReadingValue(reading.value)} mg/dL\n${_formatTime(reading.time)}',
          TextStyle(
            color: _getGlucoseColor(reading.value),
            fontWeight: FontWeight.w600,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildLeftTitle(double value, TitleMeta meta) {
    final rounded = value.round();

    if (rounded % 100 != 0 && rounded != 50) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text(
        '$rounded',
        style: const TextStyle(
          fontSize: 9.5,
          color: Colors.white70,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBottomTitle(double value, TitleMeta meta) {
    String label;

    if (value == 0) {
      label = '12A';
    } else if (value == 6) {
      label = '6A';
    } else if (value == 12) {
      label = '12P';
    } else if (value == 18) {
      label = '6P';
    } else if (value == 24) {
      label = '12A';
    } else {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Colors.white70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppSettingsProvider>().language;

    return Directionality(
      textDirection: _pageDirection,
      child: Scaffold(
        backgroundColor: _pageBg,
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: _buildBottomNav(),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildGlucoseCard(),
                const SizedBox(height: 10),
                _buildInputRow(),
                const SizedBox(height: 14),
                _buildMealsCard(),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('welcomeBack'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t('todayOverview'),
                style: TextStyle(
                  fontSize: 13,
                  color: _isDark ? _darkSubText : const Color(0xff378ADD),
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data?.docs.length ?? 0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            NotificationsScreen(userId: widget.userId),
                      ),
                    );
                  },
                  child: _circleIcon(Icons.notifications_none_rounded),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
          child: _circleIcon(Icons.person_outline_rounded),
        ),
      ],
    );
  }

  Widget _buildGlucoseCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          decoration: BoxDecoration(
            color: const Color(0xff185FA5),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff185FA5).withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              if (isMobile) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCurrentGlucoseBlock()),
                    const SizedBox(width: 8),
                    _buildAnimatedMascot(size: 86),
                  ],
                ),
                const SizedBox(height: 10),
                _buildChartDayInfo(),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentGlucoseBlock(),
                    const SizedBox(width: 12),
                    Expanded(child: _buildChartDayInfo()),
                    const SizedBox(width: 12),
                    _buildAnimatedMascot(size: 118),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: isMobile ? 260 : 245,
                child: readings.isEmpty
                    ? Center(
                        child: Text(
                          t('noReadingsYet'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: isMobile ? 34 : 44,
                              right: isMobile ? 18 : 38,
                            ),
                            child: PageView.builder(
                              controller: _chartDayController,
                              onPageChanged: (page) {
                                final diff = page - _baseChartPage;
                                setState(() {
                                  selectedChartDay = _dateOnly(
                                    DateTime.now().add(Duration(days: diff)),
                                  );
                                });
                              },
                              itemBuilder: (context, page) {
                                final diff = page - _baseChartPage;
                                final pageDay = _dateOnly(
                                  DateTime.now().add(Duration(days: diff)),
                                );

                                final prepared = _prepareReadingsForDay(
                                  pageDay,
                                );
                                final visiblePrepared = _visiblePrepared(
                                  prepared,
                                );
                                final segments = _buildLineSegments(prepared);
                                final normalSpots = _normalSpots(prepared);

                                if (visiblePrepared.isEmpty) {
                                  return Center(
                                    child: Text(
                                      t('noReadingsDay'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  );
                                }

                                return LineChart(
                                  LineChartData(
                                    backgroundColor: Colors.white.withOpacity(
                                      0.12,
                                    ),
                                    minX: 0,
                                    maxX: 24,
                                    minY: _minYForPrepared(prepared),
                                    maxY: _maxYForPrepared(prepared),
                                    rangeAnnotations: RangeAnnotations(
                                      horizontalRangeAnnotations: [
                                        HorizontalRangeAnnotation(
                                          y1: 70,
                                          y2: 180,
                                          color: Colors.green.withOpacity(0.18),
                                        ),
                                      ],
                                    ),
                                    lineTouchData: LineTouchData(
                                      handleBuiltInTouches: false,
                                      touchTooltipData: LineTouchTooltipData(
                                        getTooltipColor: (_) => Colors.white,
                                        tooltipRoundedRadius: 12,
                                        fitInsideHorizontally: true,
                                        fitInsideVertically: true,
                                        getTooltipItems: (touchedSpots) {
                                          return _buildTooltipItems(
                                            touchedSpots,
                                            prepared,
                                          );
                                        },
                                      ),
                                      touchCallback:
                                          (
                                            FlTouchEvent event,
                                            LineTouchResponse? response,
                                          ) async {
                                            if (response == null ||
                                                response.lineBarSpots == null ||
                                                response
                                                    .lineBarSpots!
                                                    .isEmpty) {
                                              return;
                                            }

                                            if (event is FlTapUpEvent) {
                                              final spot =
                                                  response.lineBarSpots!.first;

                                              final item =
                                                  _preparedReadingForSpot(
                                                    spot,
                                                    prepared,
                                                  );

                                              if (item == null) return;

                                              await _openReadingFromChart(
                                                item.reading,
                                              );
                                            }
                                          },
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: isMobile ? 28 : 34,
                                          interval: isMobile ? 100 : 50,
                                          getTitlesWidget: _buildLeftTitle,
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          interval: isMobile ? 6 : 3,
                                          getTitlesWidget: _buildBottomTitle,
                                        ),
                                      ),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: true,
                                      verticalInterval: isMobile ? 6 : 3,
                                      horizontalInterval: isMobile ? 50 : 25,
                                      getDrawingVerticalLine: (_) => FlLine(
                                        color: Colors.white.withOpacity(0.08),
                                        strokeWidth: 1,
                                      ),
                                      getDrawingHorizontalLine: (_) => FlLine(
                                        color: Colors.white.withOpacity(0.08),
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      ...segments.map(
                                        (segment) => LineChartBarData(
                                          spots: segment,
                                          isCurved: true,
                                          curveSmoothness: 0.14,
                                          preventCurveOverShooting: true,
                                          color: const Color(0xffA9D2FF),
                                          barWidth: isMobile ? 2.8 : 3.2,
                                          isStrokeCapRound: true,
                                          dotData: const FlDotData(show: false),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: Colors.white.withOpacity(
                                              0.04,
                                            ),
                                          ),
                                        ),
                                      ),
                                      LineChartBarData(
                                        spots: normalSpots,
                                        isCurved: false,
                                        color: Colors.transparent,
                                        barWidth: 0,
                                        belowBarData: BarAreaData(show: false),
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter:
                                              (spot, percent, barData, index) {
                                                return FlDotCirclePainter(
                                                  radius: isMobile ? 5.2 : 5.8,
                                                  color: _getGlucoseColor(
                                                    spot.y,
                                                  ),
                                                  strokeColor: Colors.white,
                                                  strokeWidth: 2,
                                                );
                                              },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _chartSideArrow(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: _goToPreviousDay,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _chartSideArrow(
                              icon: Icons.arrow_forward_ios_rounded,
                              onTap: _goToNextDay,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentGlucoseBlock() {
    return SizedBox(
      width: 138,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('currentGlucose'),
            style: TextStyle(
              fontSize: 11,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _displayGlucoseValue(currentGlucose),
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  t('mgdl'),
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    lastReading.isEmpty
                        ? glucoseStatus
                        : '$glucoseStatus · $lastReading',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartDayInfo() {
    final dayReadings = _prepareReadingsForDay(selectedChartDay);
    final validCount = _visiblePrepared(dayReadings).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTiny = constraints.maxWidth < 290;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 0.8,
            ),
          ),
          child: isTiny
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatChartDay(selectedChartDay),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$validCount ${t('readings')} · ${t('hourChart')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      _formatChartDay(selectedChartDay),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      '$validCount ${t('readings')}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      t('hourChart'),
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _chartSideArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _glucoseController,
            style: TextStyle(color: _titleColor),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: t('enterMgdl'),
              hintStyle: TextStyle(color: _subtitleColor),
              filled: true,
              fillColor: _cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _isDark ? Colors.white24 : const Color(0xffB5D4F4),
                  width: 0.7,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _isDark ? Colors.white24 : const Color(0xffB5D4F4),
                  width: 0.7,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xff378ADD),
                  width: 1.2,
                ),
              ),
            ),
            onSubmitted: (_) => _addReading(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _addReading,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff185FA5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          ),
          child: Text(
            t('add'),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildMealsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t('meals'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _titleColor,
                ),
              ),
              Text(
                t('tapToAdd'),
                style: TextStyle(fontSize: 11, color: _subtitleColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...meals.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _mealTile(
                title: _trMealTitle(e.value['title'] as String),
                status: _trStatus(e.value['status'] as String),
                icon: e.value['icon'] as IconData,
                onTap: () => _showMealOptions(e.value['title'] as String),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'key': 'home'},
      {'icon': Icons.restaurant_menu_rounded, 'key': 'meals'},
      {'icon': Icons.insert_chart_outlined_rounded, 'key': 'reports'},
      {'icon': Icons.grid_view_rounded, 'key': 'menu'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final key = item['key'] as String;
          final isMenu = key == 'menu';
          final selected = selectedNavIndex == index && !isMenu;

          return GestureDetector(
            onTap: () {
              if (isMenu) {
                _showMainMenu();
                return;
              }

              if (key == 'reports') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportsScreen(userId: widget.userId),
                  ),
                );
                return;
              }

              if (key == 'meals') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealReportApp(),
                  ),
                );
                return;
              }

              setState(() => selectedNavIndex = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? (_isDark
                          ? const Color(0xff183A5C)
                          : const Color(0xffDDEEFF))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color:
                              (_isDark ? Colors.black : const Color(0xffC9E2FB))
                                  .withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 19,
                    color: selected
                        ? (_isDark
                              ? const Color(0xff8CC7F5)
                              : const Color(0xff185FA5))
                        : (_isDark ? _darkSubText : const Color(0xff888780)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t(key),
                    style: TextStyle(
                      fontSize: 10,
                      color: selected
                          ? (_isDark
                                ? const Color(0xff8CC7F5)
                                : const Color(0xff185FA5))
                          : (_isDark ? _darkSubText : const Color(0xff888780)),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      child: Icon(
        icon,
        size: 18,
        color: _isDark ? const Color(0xff8CC7F5) : const Color(0xff378ADD),
      ),
    );
  }

  Widget _mealTile({
    required String title,
    required String status,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0xffBFE2FF).withOpacity(0.35),
        highlightColor: const Color(0xffD9EEFF).withOpacity(0.45),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _softCardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _tileBorderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _iconBgColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 20, color: _mainBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      style: TextStyle(fontSize: 11, color: _subtitleColor),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xff9FC9F5),
              ),
            ],
          ),
        ),
      ),
    );
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

  void _showMealOptions(String mealTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          decoration: BoxDecoration(
            color: _sheetBgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 14),
              Text(
                _trMealTitle(mealTitle),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t('chooseContinue'),
                style: TextStyle(fontSize: 13, color: _subtitleColor),
              ),
              const SizedBox(height: 18),
              _sheetOption(
                icon: Icons.edit_note_rounded,
                title: t('addMyMeal'),
                subtitle: t('addMyMealSub'),
                onTap: () {
                  final mealType = _mealTypeFromTitle(mealTitle);

                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MealLoggerScreen(mealType: mealType),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _sheetOption(
                icon: Icons.qr_code_scanner_rounded,
                title: t('scanBarcode'),
                subtitle: t('scanBarcodeSub'),
                onTap: () async {
                  Navigator.pop(context);
                  final barcode = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BarcodeScannerScreen(),
                    ),
                  );

                  if (barcode == null || barcode.toString().isEmpty) return;
                  if (!mounted) return;

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  final FoodProduct? product =
                      await OpenFoodFactsService.getProductByBarcode(barcode);

                  if (mounted) Navigator.pop(context);
                  if (!mounted) return;

                  if (product == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t('productNotFound'))),
                    );
                    return;
                  }

                  final patientProfile = await OnboardingApi.getPatientProfile(
                    userId: widget.userId,
                  );

                  final double? carbRatio =
                      patientProfile != null &&
                          patientProfile['carbRatio'] != null
                      ? double.tryParse(patientProfile['carbRatio'].toString())
                      : null;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BarcodeProductResultScreen(
                        mealTitle: mealTitle,
                        product: product,
                        carbRatio: carbRatio,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _sheetOption(
                icon: Icons.lightbulb_outline_rounded,
                title: t('suggestMeal'),
                subtitle: t('suggestMealSub'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) => MealSuggestionScreen(
                        mealType: mealTitle,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _menuDisplayLabel(String label) {
    switch (label) {
      case 'Doctor':
        return t('doctor');
      case 'Contact':
        return t('contact');
      case 'Chat / Ask anything':
        return t('chatAsk');
      case 'Meal Plans':
        return t('mealPlans');
      case 'Nutritionist':
        return t('nutritionist');
      case 'Water':
        return t('water');
      case 'Activity':
        return t('activity');
      case 'Settings':
        return t('settings');
      default:
        return label;
    }
  }

  void _showMainMenu() {
    final menuItems = [
      {'icon': Icons.medical_information_outlined, 'label': 'Doctor'},
      {'icon': Icons.contact_support_outlined, 'label': 'Contact'},
      {
        'icon': Icons.chat_bubble_outline_rounded,
        'label': 'Chat / Ask anything',
      },
      {'icon': Icons.restaurant_menu_rounded, 'label': 'Meal Plans'},
      {'icon': Icons.restaurant_outlined, 'label': 'Nutritionist'},
      {'icon': Icons.water_drop_outlined, 'label': 'Water'},
      {'icon': Icons.bolt_rounded, 'label': 'Activity'},
      {'icon': Icons.settings_outlined, 'label': 'Settings'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            decoration: BoxDecoration(
              color: _sheetBgColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _sheetHandle(),
                const SizedBox(height: 14),
                Text(
                  t('menu'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: menuItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _menuTile(
                      icon: menuItems[i]['icon'] as IconData,
                      label: _menuDisplayLabel(menuItems[i]['label'] as String),
                      onTap: () {
                        final label = menuItems[i]['label'] as String;

                        Navigator.pop(context);
                        if (label == 'Settings') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PatientSettingsScreen(userId: widget.userId),
                            ),
                          );
                          return;
                        }

                        if (label == 'Activity') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ActivityScreen(userId: widget.userId),
                            ),
                          );
                          return;
                        }
                        if (label == 'Meal Plans') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PatientAssignedMealPlansPage(
                                    patientId: widget.userId,
                                  ),
                            ),
                          );
                          return;
                        }
                        if (label == 'Chat / Ask anything') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatScreen(),
                            ),
                          );
                          return;
                        }

                        if (label == 'Water') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WaterTrackerPage(userId: widget.userId),
                            ),
                          );
                          return;
                        }
                        if (label == 'Nutritionist') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContactNutritionistPage(
                                patientId: widget.userId,
                              ),
                            ),
                          );
                        }

                        if (label == 'Doctor') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ContactDoctorPage(patientId: widget.userId),
                            ),
                          );
                        }
                        if (label == 'Contact') {
                          _showContactOptions(context);
                          return;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: _isDark
            ? Colors.white.withOpacity(0.18)
            : const Color(0xffC8DDEC),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0xffBFE2FF).withOpacity(0.35),
        highlightColor: const Color(0xffD9EEFF).withOpacity(0.45),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _softCardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _tileBorderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: _mainBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: _subtitleColor),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xff9FC9F5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0xffBFE2FF).withOpacity(0.35),
        highlightColor: const Color(0xffD9EEFF).withOpacity(0.45),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _softCardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _tileBorderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: _mainBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: _titleColor,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xff9FC9F5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PreparedReading {
  final GlucoseReading reading;
  final bool suspicious;

  PreparedReading({required this.reading, this.suspicious = false});
}

class GlucoseReading {
  final String? id;
  final double x;
  final double value;
  final DateTime time;
  final DateTime? createdAt;

  GlucoseReading({
    this.id,
    required this.x,
    required this.value,
    required this.time,
    this.createdAt,
  });

  GlucoseReading copyWith({
    String? id,
    double? x,
    double? value,
    DateTime? time,
    DateTime? createdAt,
  }) {
    return GlucoseReading(
      id: id ?? this.id,
      x: x ?? this.x,
      value: value ?? this.value,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory GlucoseReading.fromApiJson(Map<String, dynamic> json) {
    return GlucoseReading(
      id: json['_id']?.toString(),
      x: 0,
      value: (json['value'] as num).toDouble(),
      time: DateTime.parse(json['readingTime']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
