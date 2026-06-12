import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/glucose_api.dart';
import 'services/profile_api.dart';
import 'family_profile_page.dart';
import 'services/family_meals_api.dart';
import 'services/family_push_service.dart';
import 'package:audioplayers/audioplayers.dart';

import 'patient_settings_screen.dart';
import 'providers/app_settings_provider.dart';

class FamilyHomeScreen extends StatefulWidget {
  final String familyUserId;
  final String patientId;
  final String? initialPatientName;

  const FamilyHomeScreen({
    super.key,
    required this.familyUserId,
    required this.patientId,
    this.initialPatientName,
  });

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen>
    with SingleTickerProviderStateMixin {
  double? currentGlucose;
  String glucoseStatus = 'No readings yet';
  String lastReading = '';
  String lastSeenText = 'No reading recorded yet';

  String patientName = 'Patient';
  String lantusTime = 'Not set yet';

  String mealsTodayStatus = 'Loading meals...';
  String lastMealLogged = 'Loading last meal...';

  bool noRecentReadingWarning = false;
  bool _emergencyShownForCurrentReading = false;

  bool _criticalDialogOpen = false;

  final AudioPlayer _criticalAlarmPlayer = AudioPlayer();
  bool _criticalAlarmPlaying = false;

  final Set<String> _shownNotificationIds = {};

  Color statusColor = const Color(0xff1D9E75);

  List<GlucoseReading> readings = [];

  late final AnimationController _mascotController;

  static const Color _mainBlue = Color(0xff185FA5);
  static const Color _softBlue = Color(0xffEAF6FF);
  static const Color _textBlue = Color(0xff0C447C);
  static const Color _dangerRed = Color(0xffE24B4A);
  static const Color _warningOrange = Color(0xffEF9F27);
  static const Color _successGreen = Color(0xff1D9E75);

  static const Color _darkBg = Color(0xff071A2F);
  static const Color _darkCard = Color(0xff102A46);
  static const Color _darkTile = Color(0xff183A5C);
  static const Color _darkSubText = Color(0xffAFC7DD);

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'family': 'Family',
      'patientSafetyOverview': 'Patient safety overview',
      'notifications': 'Notifications',
      'latestPatientAlerts': 'Latest patient alerts',
      'noNotificationsYet': 'No notifications yet',
      'patientAlertsHere': 'Patient alerts will appear here.',
      'alert': 'Alert',
      'notification': 'Notification',
      'noDetailsAvailable': 'No details available.',
      'aware': 'Aware',
      'read': 'Read',
      'view': 'View',
      'emergencyAlert': 'Emergency Alert',
      'iAmAware': 'I am aware',
      'lowGlucoseAlert': 'Low Glucose Alert',
      'quickSteps': 'Quick steps:',
      'makeSureConscious': 'Make sure the patient is conscious.',
      'giveFastCarbs': 'Give fast carbs if needed.',
      'recheckAfter15': 'Recheck glucose after 15 minutes.',
      'checkImmediately': 'Check on the patient immediately.',
      'close': 'Close',
      'patientStatus': 'PATIENT STATUS',
      'patient': 'Patient',
      'noReadingsYet': 'No readings yet',
      'noReadingRecordedYet': 'No reading recorded yet',
      'lastReading': 'Last reading',
      'lowCheckNow': 'Low · check now',
      'highTakeAction': 'High · take action',
      'slightlyHigh': 'Slightly high',
      'inRange': 'In Range',
      'justNow': 'just now',
      'minAgo': 'min ago',
      'hAgo': 'h ago',
      'noGlucoseRecorded': 'No glucose reading has been recorded yet.',
      'notCheckedLong': 'The patient has not checked glucose for a long time.',
      'patientLooksOkay': 'Patient looks okay',
      'noUrgentIssue': 'No urgent issue detected from the latest data.',
      'immediateAttention': 'Immediate attention needed',
      'lowSubtitle':
          'Glucose is low. Contact the patient and follow low-glucose steps.',
      'highDetected': 'High glucose detected',
      'highSubtitle':
          'Glucose is high. Check if the patient followed the action plan.',
      'readingOutdated': 'Reading is outdated',
      'oldSubtitle': 'Ask the patient to check glucose again.',
      'mealsInsulin': 'Meals & Insulin',
      'mealsToday': 'Meals today',
      'lantusReminder': 'Lantus reminder',
      'lastMealLoggedLabel': 'Last meal logged',
      'loadingMeals': 'Loading meals...',
      'loadingLastMeal': 'Loading last meal...',
      'noMealsToday': 'No meals logged today',
      'oneMealToday': '1 meal logged today',
      'manyMealsToday': '{count} meals logged today',
      'noMealYet': 'No meal logged yet',
      'mealsNotAvailable': 'Meals data not available',
      'noMealData': 'No meal data available',
      'breakfast': 'Breakfast',
      'lunch': 'Lunch',
      'dinner': 'Dinner',
      'morningSnack': 'Morning snack',
      'eveningSnack': 'Evening snack',
      'mealLogged': 'Meal logged',
      'notSetYet': 'Not set yet',
      'lantusNotSet': 'Lantus time is not set yet',
      'scheduledAt': 'Scheduled at {time}',
      'todaysChart': "Today's Glucose Chart",
      'readingsReadOnly': '{count} readings · read-only',
      'noReadingsToday': 'No readings for today yet.',
      'settings': 'Settings',
    },
    'ar': {
      'family': 'الأهل',
      'patientSafetyOverview': 'ملخص سلامة المريض',
      'notifications': 'الإشعارات',
      'latestPatientAlerts': 'آخر تنبيهات المريض',
      'noNotificationsYet': 'لا توجد إشعارات بعد',
      'patientAlertsHere': 'ستظهر تنبيهات المريض هنا.',
      'alert': 'تنبيه',
      'notification': 'إشعار',
      'noDetailsAvailable': 'لا توجد تفاصيل متاحة.',
      'aware': 'تم الانتباه',
      'read': 'مقروء',
      'view': 'عرض',
      'emergencyAlert': 'تنبيه طارئ',
      'iAmAware': 'أنا على علم',
      'lowGlucoseAlert': 'تنبيه انخفاض السكر',
      'quickSteps': 'خطوات سريعة:',
      'makeSureConscious': 'تأكدوا أن المريض واعٍ.',
      'giveFastCarbs': 'أعطوا كربوهيدرات سريعة عند الحاجة.',
      'recheckAfter15': 'أعيدوا فحص السكر بعد 15 دقيقة.',
      'checkImmediately': 'اطمئنوا على المريض فورًا.',
      'close': 'إغلاق',
      'patientStatus': 'حالة المريض',
      'patient': 'المريض',
      'noReadingsYet': 'لا توجد قراءات بعد',
      'noReadingRecordedYet': 'لم يتم تسجيل أي قراءة بعد',
      'lastReading': 'آخر قراءة',
      'lowCheckNow': 'منخفض · افحصوا الآن',
      'highTakeAction': 'مرتفع · اتخذوا إجراء',
      'slightlyHigh': 'مرتفع قليلًا',
      'inRange': 'ضمن المعدل',
      'justNow': 'الآن',
      'minAgo': 'دقيقة مضت',
      'hAgo': 'ساعة مضت',
      'noGlucoseRecorded': 'لم يتم تسجيل أي قراءة سكر بعد.',
      'notCheckedLong': 'المريض لم يفحص السكر منذ مدة طويلة.',
      'patientLooksOkay': 'حالة المريض جيدة',
      'noUrgentIssue': 'لا توجد مشكلة طارئة حسب آخر البيانات.',
      'immediateAttention': 'يحتاج إلى انتباه فوري',
      'lowSubtitle':
          'السكر منخفض. تواصلوا مع المريض واتبعوا خطوات انخفاض السكر.',
      'highDetected': 'تم اكتشاف ارتفاع في السكر',
      'highSubtitle': 'السكر مرتفع. تحققوا إذا كان المريض اتبع خطة التصرف.',
      'readingOutdated': 'القراءة قديمة',
      'oldSubtitle': 'اطلبوا من المريض إعادة فحص السكر.',
      'mealsInsulin': 'الوجبات والإنسولين',
      'mealsToday': 'وجبات اليوم',
      'lantusReminder': 'تذكير اللانتوس',
      'lastMealLoggedLabel': 'آخر وجبة مسجلة',
      'loadingMeals': 'جاري تحميل الوجبات...',
      'loadingLastMeal': 'جاري تحميل آخر وجبة...',
      'noMealsToday': 'لا توجد وجبات مسجلة اليوم',
      'oneMealToday': 'تم تسجيل وجبة واحدة اليوم',
      'manyMealsToday': 'تم تسجيل {count} وجبات اليوم',
      'noMealYet': 'لا توجد وجبات مسجلة بعد',
      'mealsNotAvailable': 'بيانات الوجبات غير متاحة',
      'noMealData': 'لا توجد بيانات وجبات متاحة',
      'breakfast': 'الفطور',
      'lunch': 'الغداء',
      'dinner': 'العشاء',
      'morningSnack': 'سناك صباحي',
      'eveningSnack': 'سناك مسائي',
      'mealLogged': 'تم تسجيل وجبة',
      'notSetYet': 'لم يتم التحديد بعد',
      'lantusNotSet': 'وقت اللانتوس غير محدد بعد',
      'scheduledAt': 'مجدول عند {time}',
      'todaysChart': 'مخطط السكر لليوم',
      'readingsReadOnly': '{count} قراءات · للعرض فقط',
      'noReadingsToday': 'لا توجد قراءات لهذا اليوم بعد.',
      'settings': 'الإعدادات',
    },
  };

  String t(String key, {Map<String, String>? params}) {
    final lang = context.read<AppSettingsProvider>().language;
    var text = _strings[lang]?[key] ?? _strings['en']?[key] ?? key;
    params?.forEach((k, v) => text = text.replaceAll('{$k}', v));
    return text;
  }

  bool get _isArabic => context.watch<AppSettingsProvider>().language == 'ar';
  bool get _isDark => context.watch<AppSettingsProvider>().darkMode;

  TextDirection get _pageDirection =>
      _isArabic ? TextDirection.rtl : TextDirection.ltr;

  Color get _pageBg => _isDark ? _darkBg : _softBlue;
  Color get _cardColor => _isDark ? _darkCard : Colors.white;
  Color get _softCardColor => _isDark ? _darkTile : _softBlue;
  Color get _tileColor => _isDark ? _darkTile : const Color(0xffEAF6FF);
  Color get _iconBgColor =>
      _isDark ? const Color(0xff173A5E) : const Color(0xffDCEEFF);
  Color get _titleColor => _isDark ? Colors.white : _textBlue;
  Color get _subtitleColor => _isDark ? _darkSubText : const Color(0xff6D8AA5);
  Color get _panelBg =>
      _isDark ? const Color(0xff0D223A) : const Color(0xffF4FBFF);
  Color get _borderColor =>
      _isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05);

  @override
  void initState() {
    super.initState();

    if (widget.initialPatientName != null &&
        widget.initialPatientName!.trim().isNotEmpty) {
      patientName = widget.initialPatientName!;
    }

    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    FamilyPushService.initForFamily(widget.familyUserId);

    _loadPatientProfile();
    _loadReadings();
    _loadMealsSummary();
    _listenForFamilyNotifications();
  }

  @override
  void dispose() {
    _criticalAlarmPlayer.stop();
    _criticalAlarmPlayer.dispose();
    _mascotController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientProfile() async {
    try {
      print('FAMILY PAGE PATIENT ID: ${widget.patientId}');

      final profile = await ProfileApi.getProfile(widget.patientId);

      print('PROFILE DATA IN FAMILY PAGE: $profile');

      setState(() {
        patientName = profile.fullName.toString().trim().isEmpty
            ? t('patient')
            : profile.fullName.toString();

        if (profile.lantusTime != null &&
            profile.lantusTime.toString().trim().isNotEmpty) {
          lantusTime = profile.lantusTime.toString();
        } else {
          lantusTime = t('notSetYet');
        }
      });
    } catch (e) {
      debugPrint('Failed to load patient profile for family: $e');
    }
  }

  Future<void> _loadReadings() async {
    try {
      final data = await GlucoseApi.getReadings(widget.patientId);

      final loaded = data.map((e) => GlucoseReading.fromApiJson(e)).toList();

      loaded.sort((a, b) => a.time.compareTo(b.time));

      setState(() {
        readings = loaded;
        _refreshCurrentReading();
      });

      _checkEmergencyDialog();
    } catch (e) {
      debugPrint('Failed to load family readings: $e');
    }
  }

  Future<void> _loadMealsSummary() async {
    try {
      final report = await FamilyMealsApi.getMealReport(
        patientId: widget.patientId,
        filter: 'all',
      );

      final allMeals = _extractAllMeals(report);

      final todayMeals = allMeals.where((meal) {
        final createdAt = meal['createdAt'];
        final date = DateTime.tryParse(createdAt.toString());

        if (date == null) return false;

        final localDate = date.toLocal();
        final now = DateTime.now();

        return localDate.year == now.year &&
            localDate.month == now.month &&
            localDate.day == now.day;
      }).toList();

      allMeals.sort((a, b) {
        final aTime =
            DateTime.tryParse(a['createdAt'].toString()) ?? DateTime(2000);
        final bTime =
            DateTime.tryParse(b['createdAt'].toString()) ?? DateTime(2000);

        return bTime.compareTo(aTime);
      });

      final latestMeal = allMeals.isEmpty ? null : allMeals.first;

      if (!mounted) return;

      setState(() {
        if (todayMeals.isEmpty) {
          mealsTodayStatus = t('noMealsToday');
        } else if (todayMeals.length == 1) {
          mealsTodayStatus = t('oneMealToday');
        } else {
          mealsTodayStatus = t(
            'manyMealsToday',
            params: {'count': todayMeals.length.toString()},
          );
        }

        if (latestMeal == null) {
          lastMealLogged = t('noMealYet');
        } else {
          final mealType = latestMeal['mealType']?.toString() ?? '';
          final createdAt = latestMeal['createdAt'];

          final mealTypeText = _formatMealType(mealType);
          final timeText = _formatMealDateTime(createdAt);

          lastMealLogged = timeText.isEmpty
              ? mealTypeText
              : '$mealTypeText · $timeText';
        }
      });
    } catch (e) {
      debugPrint('Failed to load family meals summary: $e');

      if (!mounted) return;

      setState(() {
        mealsTodayStatus = t('mealsNotAvailable');
        lastMealLogged = t('noMealData');
      });
    }
  }

  List<Map<String, dynamic>> _extractAllMeals(Map<String, dynamic> report) {
    final meals = report['meals'];

    if (meals == null || meals is! List || meals.isEmpty) {
      return [];
    }

    return meals
        .where((meal) => meal is Map)
        .map((meal) => Map<String, dynamic>.from(meal as Map))
        .toList();
  }

  String _formatMealDateTime(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '';

    return _formatTime(date.toLocal());
  }

  String _formatMealType(String value) {
    switch (value) {
      case 'breakfast':
        return t('breakfast');
      case 'lunch':
        return t('lunch');
      case 'dinner':
        return t('dinner');
      case 'morningSnack':
        return t('morningSnack');
      case 'eveningSnack':
        return t('eveningSnack');
      default:
        return value.trim().isEmpty ? t('mealLogged') : value;
    }
  }

  void _refreshCurrentReading() {
    if (readings.isEmpty) {
      currentGlucose = null;
      glucoseStatus = t('noReadingsYet');
      lastReading = '';
      lastSeenText = t('noReadingRecordedYet');
      statusColor = _dangerRed;
      noRecentReadingWarning = true;
      return;
    }

    final latest = readings.last;
    final diff = DateTime.now().difference(latest.time);

    currentGlucose = latest.value;
    glucoseStatus = _getGlucoseStatus(latest.value);
    statusColor = _getGlucoseColor(latest.value);
    lastReading = _formatRelative(latest.time);
    lastSeenText = '${t('lastReading')}: $lastReading';

    noRecentReadingWarning = diff.inHours >= 3;
  }

  void _checkEmergencyDialog() {
    if (!mounted) return;
    if (currentGlucose == null) return;

    if (currentGlucose! < 70 && !_emergencyShownForCurrentReading) {
      _emergencyShownForCurrentReading = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLowGlucoseEmergencyDialog();
      });
    }
  }

  Color _getGlucoseColor(double value) {
    if (value < 70) return _dangerRed;
    if (value > 180) return _dangerRed;
    if (value > 140) return _warningOrange;
    return _successGreen;
  }

  String _getGlucoseStatus(double value) {
    if (value < 70) return t('lowCheckNow');
    if (value > 180) return t('highTakeAction');
    if (value > 140) return t('slightlyHigh');
    return t('inRange');
  }

  String _displayGlucoseValue(double? value) {
    if (value == null) return '--';
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

  List<GlucoseReading> _todayReadings() {
    final now = DateTime.now();

    return readings.where((reading) {
      return reading.time.year == now.year &&
          reading.time.month == now.month &&
          reading.time.day == now.day;
    }).toList();
  }

  double _timeToX(DateTime time) {
    return time.hour + (time.minute / 60.0) + (time.second / 3600.0);
  }

  double _minYForToday(List<GlucoseReading> todayReadings) {
    if (todayReadings.isEmpty) return 40;

    final minVal = todayReadings
        .map((e) => e.value)
        .reduce((a, b) => a < b ? a : b);

    final safeMin = math.min(minVal, 70.0);
    return (safeMin - 25).clamp(0, 350).toDouble();
  }

  double _maxYForToday(List<GlucoseReading> todayReadings) {
    if (todayReadings.isEmpty) return 220;

    final maxVal = todayReadings
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    final safeMax = math.max(maxVal, 180.0);
    return (safeMax + 25).clamp(90, 620).toDouble();
  }

  void _showNotificationsSidePanel() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width >= 900
                  ? 460
                  : MediaQuery.of(context).size.width * 0.88,
              height: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: BoxDecoration(
                color: _panelBg,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(26),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _notificationsPanelHeader(context),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.familyUserId)
                            .collection('notifications')
                            .orderBy('createdAt', descending: true)
                            .limit(30)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return _emptyNotificationsView();
                          }

                          final docs = _removeDuplicateNotifications(
                            snapshot.data!.docs,
                          );

                          return ListView.separated(
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;

                              return _notificationCard(
                                docId: doc.id,
                                data: data,
                                onMarkRead: () async {
                                  await doc.reference.update({'isRead': true});
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation =
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  List<QueryDocumentSnapshot> _removeDuplicateNotifications(
    List<QueryDocumentSnapshot> docs,
  ) {
    final Map<String, QueryDocumentSnapshot> latestByType = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final type = data['type']?.toString() ?? '';
      final title = data['title']?.toString() ?? t('alert');

      final key = type.isNotEmpty ? type : title;

      if (!latestByType.containsKey(key)) {
        latestByType[key] = doc;
      }
    }

    return latestByType.values.toList();
  }

  Widget _notificationsPanelHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _tileColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            color: _mainBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('notifications'),
                style: TextStyle(
                  color: _titleColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t('latestPatientAlerts'),
                style: TextStyle(color: _subtitleColor, fontSize: 12.5),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.close_rounded, color: _titleColor),
        ),
      ],
    );
  }

  Widget _notificationCard({
    required String docId,
    required Map<String, dynamic> data,
    required Future<void> Function() onMarkRead,
  }) {
    final title = data['title']?.toString() ?? t('alert');
    final body = data['body']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';
    final isRead = data['isRead'] == true;
    final createdAt = data['createdAt'];

    String timeText = '';
    if (createdAt is Timestamp) {
      timeText = _formatRelative(createdAt.toDate());
    }

    final bool isCritical =
        type.contains('critical') ||
        title.toLowerCase().contains('critical') ||
        title.toLowerCase().contains('low') ||
        title.toLowerCase().contains('high');

    final Color accentColor = isCritical ? _dangerRed : _mainBlue;
    final Color bgColor = isRead ? Colors.white : const Color(0xffEAF6FF);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRead
              ? Colors.black.withOpacity(0.04)
              : accentColor.withOpacity(0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCritical
                  ? Icons.warning_amber_rounded
                  : Icons.notifications_none_rounded,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isCritical ? _dangerRed : _textBlue,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _dangerRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  body.isEmpty ? t('noDetailsAvailable') : body,
                  style: const TextStyle(
                    color: Color(0xff52697C),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeText.isEmpty ? '-' : timeText,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (!isRead)
                      TextButton.icon(
                        onPressed: () async {
                          await onMarkRead();
                        },
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 17,
                        ),
                        label: Text(t('aware')),
                        style: TextButton.styleFrom(
                          foregroundColor: _mainBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      )
                    else
                      Text(
                        t('read'),
                        style: TextStyle(
                          color: _subtitleColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
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

  Widget _emptyNotificationsView() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: _mainBlue,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              t('noNotificationsYet'),
              style: TextStyle(
                color: _titleColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t('patientAlertsHere'),
              textAlign: TextAlign.center,
              style: TextStyle(color: _subtitleColor, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _listenForFamilyNotifications() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.familyUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          if (snapshot.docs.isEmpty) return;

          for (final doc in snapshot.docs) {
            if (_shownNotificationIds.contains(doc.id)) continue;

            _shownNotificationIds.add(doc.id);

            final data = doc.data();

            final title = data['title']?.toString() ?? t('notification');
            final body = data['body']?.toString() ?? '';
            final severity = data['severity']?.toString() ?? 'normal';

            if (severity == 'critical') {
              _showCriticalFamilyAlarmDialog(
                notificationId: doc.id,
                title: title,
                body: body,
              );
            } else {
              _showNormalFamilyNotification(title: title, body: body);
            }
          }
        });
  }

  void _showNormalFamilyNotification({
    required String title,
    required String body,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        backgroundColor: const Color(0xff185FA5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                body.isEmpty ? title : '$title\n$body',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: t('view'),
          textColor: Colors.white,
          onPressed: () async {
            await _markAllNormalFamilyNotificationsAsRead();
            _showNotificationsSidePanel();
          },
        ),
      ),
    );
  }

  Future<void> _playCriticalAlarmSound() async {
    if (_criticalAlarmPlaying) return;

    try {
      _criticalAlarmPlaying = true;

      await _criticalAlarmPlayer.setReleaseMode(ReleaseMode.loop);
      await _criticalAlarmPlayer.setVolume(1.0);

      await _criticalAlarmPlayer.play(AssetSource('sounds/critical_alarm.mp3'));
    } catch (e) {
      debugPrint('Failed to play critical alarm sound: $e');
      _criticalAlarmPlaying = false;
    }
  }

  Future<void> _stopCriticalAlarmSound() async {
    try {
      await _criticalAlarmPlayer.stop();
    } catch (e) {
      debugPrint('Failed to stop critical alarm sound: $e');
    } finally {
      _criticalAlarmPlaying = false;
    }
  }

  Future<void> _markAllNormalFamilyNotificationsAsRead() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.familyUserId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final severity = data['severity']?.toString() ?? 'normal';

        // critical ما نخليه ينقرا لحاله، لازم الأهل يكبسوا I am aware
        if (severity != 'critical') {
          batch.update(doc.reference, {
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      debugPrint('Failed to mark family notifications as read: $e');
    }
  }

  void _showCriticalFamilyAlarmDialog({
    required String notificationId,
    required String title,
    required String body,
  }) {
    if (_criticalDialogOpen) return;

    _criticalDialogOpen = true;

    _playCriticalAlarmSound();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: _isDark
              ? const Color(0xff351616)
              : const Color(0xffFFF1F1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t('emergencyAlert'),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            body.isEmpty ? title : '$title\n\n$body',
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xff7A1E1E),
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                await _stopCriticalAlarmSound();

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.familyUserId)
                    .collection('notifications')
                    .doc(notificationId)
                    .update({'isRead': true});

                _criticalDialogOpen = false;

                if (!mounted) return;

                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(t('iAmAware')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) async {
      _criticalDialogOpen = false;
      await _stopCriticalAlarmSound();
    });
  }

  void _showLowGlucoseEmergencyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: _dangerRed),
              const SizedBox(width: 8),
              Expanded(child: Text(t('lowGlucoseAlert'))),
            ],
          ),
          content: Text(
            '${t('patient')} glucose is ${_displayGlucoseValue(currentGlucose)} mg/dL.\n\n'
            '${t('quickSteps')}\n'
            '• ${t('makeSureConscious')}\n'
            '• ${t('giveFastCarbs')}\n'
            '• ${t('recheckAfter15')}\n'
            '• ${t('checkImmediately')}',
            style: const TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(t('close')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedMascot({double size = 92}) {
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
              size: 42,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _pageDirection,
      child: Scaffold(
        backgroundColor: _pageBg,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadPatientProfile();
              await _loadReadings();
              await _loadMealsSummary();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 14),
                  _buildPatientStatusCard(),
                  const SizedBox(height: 12),
                  _buildNoReadingWarningCard(),
                  const SizedBox(height: 14),
                  _buildQuickSafetyCard(),
                  const SizedBox(height: 14),
                  _buildMealsAndLantusCard(),
                  const SizedBox(height: 14),
                  _buildReadOnlyChartCard(),
                ],
              ),
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
                t('family'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                t('patientSafetyOverview'),
                style: TextStyle(
                  fontSize: 13,
                  color: _isDark ? _darkSubText : const Color(0xff378ADD),
                ),
              ),
            ],
          ),
        ),
        _buildNotificationIcon(),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PatientSettingsScreen(userId: widget.familyUserId),
              ),
            );
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: _borderColor, width: 0.5),
            ),
            child: const Icon(Icons.settings_outlined, color: _mainBlue),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    FamilyProfilePage(familyUserId: widget.familyUserId),
              ),
            );
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: _borderColor, width: 0.5),
            ),
            child: const Icon(Icons.family_restroom_rounded, color: _mainBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationIcon() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.familyUserId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () async {
                await _markAllNormalFamilyNotificationsAsRead();
                _showNotificationsSidePanel();
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: _borderColor, width: 0.5),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: _mainBlue,
                ),
              ),
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
                    color: _dangerRed,
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
    );
  }

  Widget _buildPatientStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _mainBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _mainBlue.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('patientStatus'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  patientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  glucoseStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _displayGlucoseValue(currentGlucose),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'mg/dL',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          lastSeenText,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildAnimatedMascot(size: 92),
        ],
      ),
    );
  }

  Widget _buildNoReadingWarningCard() {
    if (!noRecentReadingWarning) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffFFF1F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffF5B5B5)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xffFFE0E0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: _dangerRed),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              readings.isEmpty
                  ? t('noGlucoseRecorded')
                  : '${t('notCheckedLong')} $lastSeenText',
              style: const TextStyle(
                color: Color(0xff9B2C2C),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSafetyCard() {
    final bool isLow = currentGlucose != null && currentGlucose! < 70;
    final bool isHigh = currentGlucose != null && currentGlucose! > 180;
    final bool isOld = noRecentReadingWarning;

    String title = t('patientLooksOkay');
    String subtitle = t('noUrgentIssue');
    IconData icon = Icons.verified_rounded;
    Color color = _successGreen;
    Color bg = const Color(0xffECFFF7);

    if (isLow) {
      title = t('immediateAttention');
      subtitle = t('lowSubtitle');
      icon = Icons.emergency_rounded;
      color = _dangerRed;
      bg = const Color(0xffFFF1F1);
    } else if (isHigh) {
      title = t('highDetected');
      subtitle = t('highSubtitle');
      icon = Icons.trending_up_rounded;
      color = _dangerRed;
      bg = const Color(0xffFFF1F1);
    } else if (isOld) {
      title = t('readingOutdated');
      subtitle = t('oldSubtitle');
      icon = Icons.schedule_rounded;
      color = _warningOrange;
      bg = const Color(0xffFFF7E8);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xff52697C),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsAndLantusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.restaurant_menu_rounded,
            title: t('mealsInsulin'),
          ),
          const SizedBox(height: 12),
          _infoRow(
            label: t('mealsToday'),
            value: mealsTodayStatus,
            icon: Icons.restaurant_menu_rounded,
          ),
          const SizedBox(height: 10),
          _infoRow(
            label: t('lantusReminder'),
            value: lantusTime == t('notSetYet')
                ? t('lantusNotSet')
                : t('scheduledAt', params: {'time': lantusTime}),
            icon: Icons.medication_liquid_rounded,
          ),
          const SizedBox(height: 10),
          _infoRow(
            label: t('lastMealLoggedLabel'),
            value: lastMealLogged,
            icon: Icons.history_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyChartCard() {
    final todayReadings = _todayReadings();

    final spots = todayReadings
        .map((reading) => FlSpot(_timeToX(reading.time), reading.value))
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _mainBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('todaysChart'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t(
              'readingsReadOnly',
              params: {'count': todayReadings.length.toString()},
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: todayReadings.isEmpty
                ? Center(
                    child: Text(
                      t('noReadingsToday'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      backgroundColor: Colors.white.withOpacity(0.12),
                      minX: 0,
                      maxX: 24,
                      minY: _minYForToday(todayReadings),
                      maxY: _maxYForToday(todayReadings),
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
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => Colors.white,
                          tooltipRoundedRadius: 12,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${spot.y.toStringAsFixed(0)} mg/dL',
                                TextStyle(
                                  color: _getGlucoseColor(spot.y),
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: 50,
                            getTitlesWidget: (value, meta) {
                              final rounded = value.round();

                              if (rounded % 100 != 0 && rounded != 50) {
                                return const SizedBox();
                              }

                              return Text(
                                '$rounded',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 6,
                            getTitlesWidget: (value, meta) {
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
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
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
                        drawVerticalLine: true,
                        verticalInterval: 6,
                        horizontalInterval: 50,
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
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.14,
                          preventCurveOverShooting: true,
                          color: const Color(0xffA9D2FF),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 5.4,
                                color: _getGlucoseColor(spot.y),
                                strokeColor: Colors.white,
                                strokeWidth: 2,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.white.withOpacity(0.04),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: _mainBlue, size: 21),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _titleColor,
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _tileColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffD8EBFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _mainBlue, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _titleColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: _subtitleColor,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _whiteCardDecoration() {
    return BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _borderColor, width: 0.5),
    );
  }
}

class GlucoseReading {
  final String? id;
  final double value;
  final DateTime time;

  GlucoseReading({this.id, required this.value, required this.time});

  factory GlucoseReading.fromApiJson(Map<String, dynamic> json) {
    return GlucoseReading(
      id: json['_id']?.toString(),
      value: (json['value'] as num).toDouble(),
      time: DateTime.parse(json['readingTime']),
    );
  }
}
