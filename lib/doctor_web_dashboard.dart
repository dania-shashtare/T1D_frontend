import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/doctor_dashboard_api.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/glucose_api.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/doctor_appointment_api.dart';
import 'reports_screen.dart';
import 'chat_page.dart';
import 'services/appointment_reminder_service.dart';
import 'patient_settings_screen.dart';
import 'providers/app_settings_provider.dart';
import 'dart:async';

class DoctorWebDashboard extends StatefulWidget {
  final String doctorId;

  const DoctorWebDashboard({super.key, required this.doctorId});

  @override
  State<DoctorWebDashboard> createState() => _DoctorWebDashboardState();
}

class _DoctorWebDashboardState extends State<DoctorWebDashboard> {
  int selectedIndex = 0;

  static const Color bgColor = Color(0xffEAF6FF);
  static const Color softBlue = Color(0xffDCEEFF);
  static const Color mainBlue = Color(0xff185FA5);
  static const Color textBlue = Color(0xff0C447C);
  static const Color buttonBlue = Color(0xff42A5F5);
  static const Color green = Color(0xff1D9E75);
  static const Color orange = Color(0xffEF9F27);
  static const Color red = Color(0xffE24B4A);

  static const Color darkBg = Color(0xff071A2F);
  static const Color darkCard = Color(0xff102A46);
  static const Color darkTile = Color(0xff183A5C);
  static const Color darkText = Colors.white;
  static const Color darkSubText = Color(0xffAFC7DD);

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'dashboard': 'Dashboard',
      'myPatients': 'My Patients',
      'appointments': 'Appointments',
      'messages': 'Messages',
      'profile': 'Profile',
      'settings': 'Settings',
      'doctorPanel': 'Doctor Panel',
      't1dCareDashboard': 'T1D Care Dashboard',
      'logout': 'Logout',
      'logoutQuestion': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'notifications': 'Notifications',
      'appointmentReminders': 'Appointment reminders',
      'noNotificationsYet': 'No notifications yet',
      'appointmentAlertsHere': 'Appointment alerts will appear here.',
      'markRead': 'Mark read',
      'view': 'View',
      'welcomeBack': 'Welcome back',
      'welcomeSubtitle':
          'Here is your patients overview for today. Review urgent glucose cases and manage appointments easily.',
      'totalPatients': 'Total Patients',
      'activePatients': 'Active patients',
      'highRiskCases': 'High Risk Cases',
      'needReview': 'Need review',
      'noUrgentCases': 'No urgent cases',
      'inRangePatients': 'In Range Patients',
      'stablePatients': 'Stable patients',
      'highRiskPatients': 'High Risk Patients',
      'todayAppointments': 'Today Appointments',
      'noHighRiskPatients': 'No high risk patients right now.',
      'noAppointmentsYet': 'No appointments yet.',
      'doctorDashboard': 'Doctor Dashboard',
      'smallScreenMessage':
          'This dashboard works best on tablet, laptop, or desktop screens for better chart and appointment management.',
      'appointmentReminder': 'Appointment reminder',
      'appointmentNow': 'Appointment now',
      'startsIn5': 'starts in 5 minutes.',
      'startingNow': 'is starting now.',
    },
    'ar': {
      'dashboard': 'لوحة التحكم',
      'myPatients': 'مرضاي',
      'appointments': 'المواعيد',
      'messages': 'الرسائل',
      'profile': 'الملف الشخصي',
      'settings': 'الإعدادات',
      'doctorPanel': 'لوحة الطبيب',
      't1dCareDashboard': 'لوحة متابعة السكري',
      'logout': 'تسجيل الخروج',
      'logoutQuestion': 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
      'cancel': 'إلغاء',
      'notifications': 'الإشعارات',
      'appointmentReminders': 'تذكيرات المواعيد',
      'noNotificationsYet': 'لا توجد إشعارات بعد',
      'appointmentAlertsHere': 'ستظهر تنبيهات المواعيد هنا.',
      'markRead': 'تحديد كمقروء',
      'view': 'عرض',
      'welcomeBack': 'أهلًا بعودتك',
      'welcomeSubtitle':
          'هنا ملخص المرضى لهذا اليوم. راجع الحالات الطارئة ونظّم المواعيد بسهولة.',
      'totalPatients': 'إجمالي المرضى',
      'activePatients': 'مرضى نشطون',
      'highRiskCases': 'حالات عالية الخطورة',
      'needReview': 'تحتاج مراجعة',
      'noUrgentCases': 'لا توجد حالات طارئة',
      'inRangePatients': 'مرضى ضمن المعدل',
      'stablePatients': 'مرضى مستقرون',
      'highRiskPatients': 'مرضى عالي الخطورة',
      'todayAppointments': 'مواعيد اليوم',
      'noHighRiskPatients': 'لا توجد حالات عالية الخطورة حاليًا.',
      'noAppointmentsYet': 'لا توجد مواعيد بعد.',
      'doctorDashboard': 'لوحة الطبيب',
      'smallScreenMessage':
          'هذه اللوحة تعمل بشكل أفضل على التابلت أو اللابتوب أو شاشة الكمبيوتر لإدارة الرسوم والمواعيد بشكل أوضح.',
      'appointmentReminder': 'تذكير موعد',
      'appointmentNow': 'الموعد الآن',
      'startsIn5': 'يبدأ خلال 5 دقائق.',
      'startingNow': 'يبدأ الآن.',
    },
  };

  String t(String key) {
    final lang = context.watch<AppSettingsProvider>().language;
    return _strings[lang]?[key] ?? _strings['en']?[key] ?? key;
  }

  bool get _isArabic => context.watch<AppSettingsProvider>().language == 'ar';
  bool get _isDark => context.watch<AppSettingsProvider>().darkMode;

  TextDirection get _pageDirection =>
      _isArabic ? TextDirection.rtl : TextDirection.ltr;

  Color get _pageBg => _isDark ? darkBg : bgColor;
  Color get _cardColor => _isDark ? darkCard : Colors.white;
  Color get _tileColor => _isDark ? darkTile : const Color(0xffF9FCFF);
  Color get _softTileColor => _isDark ? const Color(0xff173A5E) : softBlue;
  Color get _titleColor => _isDark ? darkText : textBlue;
  Color get _subtitleColor => _isDark ? darkSubText : Colors.black45;
  Color get _borderColor =>
      _isDark ? Colors.white.withOpacity(0.08) : const Color(0xffD7EBFF);

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientSettingsScreen(userId: widget.doctorId),
      ),
    );
  }

  bool isLoadingDoctor = true;

  String doctorName = 'Doctor';
  String doctorSpecialty = 'Doctor';
  String doctorWorkplace = '';
  String doctorExperience = '';
  String doctorAgeGroups = '';
  String doctorTreatsType1 = '';

  bool isLoadingAppointments = true;
  List<dynamic> doctorAppointments = [];

  String appointmentFilter = 'all';
  String selectedAvailableDay = 'Sunday';
  String selectedAvailableStartTime = '10:00 AM';
  String selectedAvailableEndTime = '12:00 PM';
  String selectedAvailableVisitType = 'online';

  bool isLoadingAvailability = true;
  List<dynamic> doctorAvailability = [];
  bool isLoadingPatientStatus = true;

  int totalPatientsCount = 0;
  int highRiskCount = 0;
  int inRangeCount = 0;
  int noDataCount = 0;

  List<dynamic> dashboardPatients = [];
  List<dynamic> highRiskPatients = [];

  String? selectedPatientId;
  String selectedPatientName = 'Select Patient';

  bool isEditingProfile = false;
  bool isSavingProfile = false;

  final editFullNameController = TextEditingController();
  final editWorkplaceController = TextEditingController();
  final editYearsController = TextEditingController();

  String editSpecialty = 'Diabetes Specialist';
  String editTreatsType1 = 'Yes';

  bool editAgeChildren = false;
  bool editAgeAdolescents = false;
  bool editAgeAdults = false;
  bool editAgeAllAges = false;

  bool isLoadingSelectedReadings = false;
  List<Map<String, dynamic>> selectedPatientReadings = [];

  bool isLoadingSelectedPatientDetails = false;
  Map<String, dynamic>? selectedPatientDetails;

  bool isLoadingPatientTrend = false;
  Map<String, dynamic>? selectedPatientTrend;

  bool isLoadingAiSuggestion = false;
  String patientAiSuggestion = '';

  final editCarbRatioController = TextEditingController();
  final editCorrectionFactorController = TextEditingController();
  final editLantusDoseController = TextEditingController();
  final editLantusTimeController = TextEditingController();
  bool isSavingPatientParams = false;

  final editWeightController = TextEditingController();
  final editHeightController = TextEditingController();
  final editAllergyController = TextEditingController();

  bool editHasFoodAllergy = false;
  bool isEditingPatientParams = false;

  DateTimeRange? selectedDateRange;
  DateTimeRange? tempDateRange;

  List<String> get menuTitles => [
    t('dashboard'),
    t('myPatients'),
    t('appointments'),
    t('messages'),
    t('profile'),
  ];

  final List<IconData> menuIcons = [
    Icons.dashboard_rounded,
    Icons.people_alt_rounded,
    Icons.calendar_month_rounded,
    Icons.chat_bubble_outline_rounded,
    Icons.person_outline_rounded,
  ];
  Timer? _appointmentWatcherTimer;

  final List<Map<String, dynamic>> _doctorNotifications = [];
  final Set<String> _shownAppointmentAlerts = {};
  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
    _loadDoctorAppointments();
    _loadPatientStatus();
    _loadDoctorAvailability();
    _scheduleDoctorAppointmentReminders();
    _startDoctorAppointmentWatcher();
  }

  Future<void> _loadDoctorProfile() async {
    try {
      final data = await DoctorDashboardApi.getDoctorProfile(widget.doctorId);

      final profile = data['profile'];

      final List<String> ageGroups = [];

      if (profile['ageChildren'] == true) ageGroups.add('Children');
      if (profile['ageAdolescents'] == true) ageGroups.add('Adolescents');
      if (profile['ageAdults'] == true) ageGroups.add('Adults');
      if (profile['ageAllAges'] == true) ageGroups.add('All Ages');

      setState(() {
        doctorName = profile['fullName'] ?? 'Doctor';
        doctorSpecialty = profile['specialty'] ?? 'Doctor';
        doctorWorkplace = profile['workplace'] ?? '';
        doctorExperience = '${profile['yearsOfExperience'] ?? 0} years';
        doctorAgeGroups = ageGroups.isEmpty
            ? 'Not selected'
            : ageGroups.join(', ');
        doctorTreatsType1 = profile['treatsType1'] ?? 'Not selected';
        isLoadingDoctor = false;
      });
    } catch (e) {
      debugPrint('Failed to load doctor profile: $e');

      setState(() {
        isLoadingDoctor = false;
      });
    }
  }

  Future<void> _scheduleDoctorAppointmentReminders() async {
    try {
      final appointments = await DoctorDashboardApi.getDoctorAppointments(
        widget.doctorId,
      );

      for (final appointment in appointments) {
        final patient = appointment['patientId'];

        final patientName = patient is Map
            ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'
                  .trim()
            : 'a patient';

        AppointmentReminderService.scheduleAppointment(
          id: 'doctor-${appointment['_id']}',
          userId: widget.doctorId,
          day: appointment['day']?.toString() ?? '',
          time: appointment['time']?.toString() ?? '',
          title: 'Patient appointment now',
          body: 'Your appointment with $patientName is starting now.',
          type: 'doctor_appointment',
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule doctor appointment reminders: $e');
    }
  }

  Future<void> _loadDoctorAppointments() async {
    try {
      final data = await DoctorDashboardApi.getDoctorAppointments(
        widget.doctorId,
      );

      setState(() {
        doctorAppointments = data;
        isLoadingAppointments = false;
      });
    } catch (e) {
      debugPrint('Failed to load doctor appointments: $e');

      setState(() {
        isLoadingAppointments = false;
      });
    }
  }

  int get _doctorUnreadNotificationsCount {
    return _doctorNotifications
        .where((notification) => notification['isRead'] != true)
        .length;
  }

  void _startDoctorAppointmentWatcher() {
    _appointmentWatcherTimer?.cancel();

    _appointmentWatcherTimer = Timer.periodic(const Duration(seconds: 20), (
      _,
    ) async {
      if (doctorAppointments.isEmpty) {
        await _loadDoctorAppointments();
      }

      _checkDoctorAppointmentsNow();
    });

    Future.delayed(const Duration(seconds: 2), () {
      _checkDoctorAppointmentsNow();
    });
  }

  void _checkDoctorAppointmentsNow() {
    final now = DateTime.now();

    for (final appointment in doctorAppointments) {
      final id = appointment['_id']?.toString() ?? '';
      if (id.isEmpty) continue;

      final day = appointment['day']?.toString() ?? '';
      final time = appointment['time']?.toString() ?? '';
      final status = appointment['status']?.toString() ?? 'booked';

      if (status != 'booked') continue;

      final appointmentDateTime = _appointmentDateTime(day, time);
      if (appointmentDateTime == null) continue;

      final patient = appointment['patientId'];
      String patientName = 'patient';

      if (patient is Map) {
        patientName =
            '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();

        if (patientName.isEmpty) {
          patientName = patient['email']?.toString() ?? 'patient';
        }
      }

      final diff = appointmentDateTime.difference(now);

      // Reminder before 5 minutes
      final reminderKey = '$id-reminder-5';
      if (!_shownAppointmentAlerts.contains(reminderKey) &&
          diff.inSeconds <= 300 &&
          diff.inSeconds >= 240) {
        _shownAppointmentAlerts.add(reminderKey);

        setState(() {
          _doctorNotifications.insert(0, {
            'id': reminderKey,
            'title': 'Appointment reminder',
            'body': 'Your appointment with $patientName starts in 5 minutes.',
            'time': _formatNotificationTime(DateTime.now()),
            'isRead': false,
            'kind': 'reminder',
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment with $patientName starts in 5 minutes.'),
            action: SnackBarAction(
              label: 'View',
              onPressed: _showDoctorNotificationsPanel,
            ),
          ),
        );
      }

      // Appointment now
      final nowKey = '$id-now';
      if (!_shownAppointmentAlerts.contains(nowKey) &&
          diff.inSeconds <= 0 &&
          diff.inSeconds >= -60) {
        _shownAppointmentAlerts.add(nowKey);

        setState(() {
          _doctorNotifications.insert(0, {
            'id': nowKey,
            'title': 'Appointment now',
            'body': 'You have an appointment with $patientName now.',
            'time': _formatNotificationTime(DateTime.now()),
            'isRead': false,
            'kind': 'now',
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment with $patientName is starting now.'),
            action: SnackBarAction(
              label: 'View',
              onPressed: _showDoctorNotificationsPanel,
            ),
          ),
        );
      }
    }
  }

  DateTime? _appointmentDateTime(String day, String time) {
    final now = DateTime.now();

    final weekday = _weekdayNumber(day);
    if (weekday == null) return null;

    final parsed = _parseTime(time);
    if (parsed == null) return null;

    int daysToAdd = weekday - now.weekday;

    if (daysToAdd < 0) {
      daysToAdd += 7;
    }

    return DateTime(
      now.year,
      now.month,
      now.day,
      parsed['hour']!,
      parsed['minute']!,
    ).add(Duration(days: daysToAdd));
  }

  int? _weekdayNumber(String day) {
    switch (day.trim().toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  Map<String, int>? _parseTime(String time) {
    final cleaned = time.trim().toUpperCase();

    final isPm = cleaned.contains('PM');
    final isAm = cleaned.contains('AM');

    final timeOnly = cleaned.replaceAll('AM', '').replaceAll('PM', '').trim();

    final parts = timeOnly.split(':');
    if (parts.length < 2) return null;

    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    if (isPm && hour != 12) hour += 12;
    if (isAm && hour == 12) hour = 0;

    return {'hour': hour, 'minute': minute};
  }

  String _formatNotificationTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  void _showDoctorNotificationsPanel() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 430,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xffF4FAFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 22, 18, 18),
                    decoration: const BoxDecoration(
                      color: mainBlue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Appointment reminders',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _doctorNotifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: softBlue,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: mainBlue,
                                    size: 38,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  t('noNotificationsYet'),
                                  style: TextStyle(
                                    color: textBlue,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  t('appointmentAlertsHere'),
                                  style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : StatefulBuilder(
                            builder: (context, setModalState) {
                              return ListView.separated(
                                padding: const EdgeInsets.all(18),
                                itemCount: _doctorNotifications.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final notification =
                                      _doctorNotifications[index];

                                  final isRead = notification['isRead'] == true;
                                  final kind =
                                      notification['kind']?.toString() ?? 'now';
                                  final isReminder = kind == 'reminder';

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: isRead
                                            ? const Color(0xffDCEEFF)
                                            : mainBlue.withOpacity(0.45),
                                        width: isRead ? 1 : 1.4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 16,
                                          offset: const Offset(0, 7),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            color: isReminder
                                                ? const Color(0xffFFF3D8)
                                                : const Color(0xffDCEEFF),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                          child: Icon(
                                            isReminder
                                                ? Icons.schedule_rounded
                                                : Icons.calendar_month_rounded,
                                            color: isReminder
                                                ? orange
                                                : mainBlue,
                                            size: 27,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      notification['title']
                                                              ?.toString() ??
                                                          '',
                                                      style: TextStyle(
                                                        color: textBlue,
                                                        fontSize: 16,
                                                        fontWeight: isRead
                                                            ? FontWeight.w600
                                                            : FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  if (!isRead)
                                                    Container(
                                                      width: 9,
                                                      height: 9,
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: red,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                notification['body']
                                                        ?.toString() ??
                                                    '',
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 13.5,
                                                  height: 1.35,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.access_time_rounded,
                                                    size: 16,
                                                    color: Colors.black38,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    notification['time']
                                                            ?.toString() ??
                                                        '',
                                                    style: const TextStyle(
                                                      color: Colors.black45,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  if (!isRead)
                                                    TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          _doctorNotifications[index]['isRead'] =
                                                              true;
                                                        });
                                                        setModalState(() {});
                                                      },
                                                      child: const Text(
                                                        'Mark read',
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
                                },
                              );
                            },
                          ),
                  ),
                ],
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

  Future<void> _loadDoctorAvailability() async {
    try {
      final data = await DoctorAppointmentApi.getAllAvailability(
        widget.doctorId,
      );

      setState(() {
        doctorAvailability = data;
        isLoadingAvailability = false;
      });
    } catch (e) {
      debugPrint('Failed to load doctor availability: $e');

      setState(() {
        isLoadingAvailability = false;
      });
    }
  }

  int _calculateAge(dynamic birthDate) {
    if (birthDate == null) return 0;

    final birth = DateTime.tryParse(birthDate.toString());
    if (birth == null) return 0;

    final today = DateTime.now();
    int age = today.year - birth.year;

    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }

    return age;
  }

  Future<void> _loadPatientStatus() async {
    try {
      final data = await DoctorDashboardApi.getPatientStatus(widget.doctorId);

      setState(() {
        totalPatientsCount = data['totalPatients'] ?? 0;
        highRiskCount = data['highRiskCount'] ?? 0;
        inRangeCount = data['inRangeCount'] ?? 0;
        noDataCount = data['noDataCount'] ?? 0;

        dashboardPatients = data['patients'] ?? [];
        highRiskPatients = data['highRiskPatients'] ?? [];

        isLoadingPatientStatus = false;
      });
    } catch (e) {
      debugPrint('Failed to load patient status: $e');

      setState(() {
        isLoadingPatientStatus = false;
      });
    }
  }

  Future<void> _loadSelectedPatientReadings(
    String patientId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      setState(() {
        isLoadingSelectedReadings = true;
        selectedPatientReadings = [];
      });

      final data = await GlucoseApi.getReadings(patientId, from: from, to: to);

      data.sort((a, b) {
        final aTime =
            DateTime.tryParse(a['readingTime'].toString()) ?? DateTime.now();
        final bTime =
            DateTime.tryParse(b['readingTime'].toString()) ?? DateTime.now();
        return aTime.compareTo(bTime);
      });

      setState(() {
        selectedPatientReadings = data;
        isLoadingSelectedReadings = false;
      });
    } catch (e) {
      debugPrint('Failed to load selected patient readings: $e');

      setState(() {
        isLoadingSelectedReadings = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    tempDateRange = selectedDateRange;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                width: 430,
                constraints: const BoxConstraints(maxHeight: 560),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose Date Range',
                        style: TextStyle(
                          color: textBlue,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Filter glucose readings by a specific period.',
                        style: TextStyle(color: Colors.black45, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _dateQuickOption(
                              title: 'Today',
                              subtitle: 'Show today readings only',
                              icon: Icons.today_rounded,
                              selected: _isSameRange(
                                tempDateRange,
                                DateTimeRange(start: today, end: today),
                              ),
                              onTap: () {
                                setDialogState(() {
                                  tempDateRange = DateTimeRange(
                                    start: today,
                                    end: today,
                                  );
                                });
                              },
                            ),
                            _dateQuickOption(
                              title: 'Last 7 Days',
                              subtitle: 'Recent weekly glucose trend',
                              icon: Icons.calendar_view_week_rounded,
                              selected: _isSameRange(
                                tempDateRange,
                                DateTimeRange(
                                  start: today.subtract(
                                    const Duration(days: 6),
                                  ),
                                  end: today,
                                ),
                              ),
                              onTap: () {
                                setDialogState(() {
                                  tempDateRange = DateTimeRange(
                                    start: today.subtract(
                                      const Duration(days: 6),
                                    ),
                                    end: today,
                                  );
                                });
                              },
                            ),
                            _dateQuickOption(
                              title: 'Last 14 Days',
                              subtitle: 'Good for follow-up comparison',
                              icon: Icons.date_range_rounded,
                              selected: _isSameRange(
                                tempDateRange,
                                DateTimeRange(
                                  start: today.subtract(
                                    const Duration(days: 13),
                                  ),
                                  end: today,
                                ),
                              ),
                              onTap: () {
                                setDialogState(() {
                                  tempDateRange = DateTimeRange(
                                    start: today.subtract(
                                      const Duration(days: 13),
                                    ),
                                    end: today,
                                  );
                                });
                              },
                            ),
                            _dateQuickOption(
                              title: 'Last 30 Days',
                              subtitle: 'Monthly overview',
                              icon: Icons.calendar_month_rounded,
                              selected: _isSameRange(
                                tempDateRange,
                                DateTimeRange(
                                  start: today.subtract(
                                    const Duration(days: 29),
                                  ),
                                  end: today,
                                ),
                              ),
                              onTap: () {
                                setDialogState(() {
                                  tempDateRange = DateTimeRange(
                                    start: today.subtract(
                                      const Duration(days: 29),
                                    ),
                                    end: today,
                                  );
                                });
                              },
                            ),
                            _dateQuickOption(
                              title: 'This Month',
                              subtitle: 'From first day of this month',
                              icon: Icons.event_note_rounded,
                              selected: _isSameRange(
                                tempDateRange,
                                DateTimeRange(
                                  start: DateTime(today.year, today.month, 1),
                                  end: today,
                                ),
                              ),
                              onTap: () {
                                setDialogState(() {
                                  tempDateRange = DateTimeRange(
                                    start: DateTime(today.year, today.month, 1),
                                    end: today,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (tempDateRange == null) {
                            Navigator.pop(context);
                            return;
                          }

                          setState(() {
                            selectedDateRange = tempDateRange;
                          });

                          Navigator.pop(context);

                          if (selectedPatientId != null) {
                            _loadSelectedPatientReadings(
                              selectedPatientId!,
                              from: selectedDateRange?.start,
                              to: selectedDateRange?.end,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Select',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isSameRange(DateTimeRange? a, DateTimeRange b) {
    if (a == null) return false;

    return a.start.year == b.start.year &&
        a.start.month == b.start.month &&
        a.start.day == b.start.day &&
        a.end.year == b.end.year &&
        a.end.month == b.end.month &&
        a.end.day == b.end.day;
  }

  Widget _dateQuickOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffEAF6FF) : const Color(0xffF9FCFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? mainBlue : const Color(0xffD7EBFF),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? mainBlue : softBlue,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : mainBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: mainBlue, size: 22),
          ],
        ),
      ),
    );
  }

  String _dateRangeText() {
    if (selectedDateRange == null) {
      return 'Date Range';
    }

    final start = selectedDateRange!.start;
    final end = selectedDateRange!.end;

    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _pageDirection,
      child: Scaffold(
        backgroundColor: _pageBg,
        drawer: MediaQuery.of(context).size.width < 950
            ? Drawer(
                backgroundColor: mainBlue,
                child: _buildMobileSidebarContent(),
              )
            : null,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 950;
            final isTablet = constraints.maxWidth >= 650;

            if (isDesktop) {
              return Row(
                children: [
                  _buildSidebar(),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTopBar(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(26),
                            child: _buildSelectedPage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            if (isTablet) {
              return Column(
                children: [
                  _buildMobileTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: _buildSelectedPage(),
                    ),
                  ),
                ],
              );
            }

            return _mobileSmallScreenFallback();
          },
        ),
      ),
    );
  }

  Widget _mobileSmallScreenFallback() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: softBlue,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.desktop_windows_rounded,
                color: mainBlue,
                size: 42,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              t('doctorDashboard'),
              style: TextStyle(
                color: textBlue,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t('smallScreenMessage'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTopBar() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: const Icon(Icons.menu_rounded, color: mainBlue),
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              menuTitles[selectedIndex],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textBlue,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined, color: mainBlue),
            tooltip: t('settings'),
          ),
          const CircleAvatar(
            radius: 18,
            backgroundColor: mainBlue,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSidebarContent() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(
            Icons.medical_services_rounded,
            color: Colors.white,
            size: 46,
          ),
          const SizedBox(height: 12),
          Text(
            t('doctorPanel'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuTitles.length,
              itemBuilder: (context, index) {
                final selected = selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() => selectedIndex = index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            menuIcons[index],
                            color: selected ? mainBlue : Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            menuTitles[index],
                            style: TextStyle(
                              color: selected ? mainBlue : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _openSettings,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      t('settings'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _openSettings,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      t('settings'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 270,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: mainBlue,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            t('doctorPanel'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t('t1dCareDashboard'),
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 34),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuTitles.length,
              itemBuilder: (context, index) {
                final selected = selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() => selectedIndex = index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            menuIcons[index],
                            color: selected ? mainBlue : Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            menuTitles[index],
                            style: TextStyle(
                              color: selected ? mainBlue : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t('logout')),
          content: Text(t('logoutQuestion')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor: Colors.white,
              ),
              child: Text(t('logout')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Widget _buildTopBar() {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            menuTitles[selectedIndex],
            style: const TextStyle(
              color: textBlue,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _openSettings,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isDark ? darkTile : bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.settings_outlined, color: mainBlue),
            ),
          ),

          const SizedBox(width: 14),

          // Notifications only
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _showDoctorNotificationsPanel,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: mainBlue,
                  ),
                ),

                if (_doctorUnreadNotificationsCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      decoration: const BoxDecoration(
                        color: red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _doctorUnreadNotificationsCount > 9
                            ? '9+'
                            : _doctorUnreadNotificationsCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Doctor info card
          Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: mainBlue,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        doctorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        doctorSpecialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    editFullNameController.dispose();
    editWorkplaceController.dispose();
    editYearsController.dispose();
    editCarbRatioController.dispose();
    editCorrectionFactorController.dispose();
    editLantusDoseController.dispose();
    editLantusTimeController.dispose();
    editWeightController.dispose();
    editHeightController.dispose();
    editAllergyController.dispose();
    _appointmentWatcherTimer?.cancel();
    super.dispose();
  }

  Widget _buildSelectedPage() {
    switch (selectedIndex) {
      case 0:
        return _dashboardPage();
      case 1:
        return _patientsPage();
      case 2:
        return _appointmentsPage();
      case 3:
        return _messagesPage();
      case 4:
        return _profilePage();
      default:
        return _dashboardPage();
    }
  }

  Widget _dashboardPage() {
    final todayAppointmentsCount = doctorAppointments.length;

    final pendingAppointmentsCount = doctorAppointments.where((a) {
      final status = a['status']?.toString().toLowerCase() ?? '';
      return status == 'booked' || status == 'pending';
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _welcomeCard(),
        const SizedBox(height: 22),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1000;
            final isTablet =
                constraints.maxWidth >= 650 && constraints.maxWidth < 1000;

            final cardWidth = isWide
                ? (constraints.maxWidth - 54) / 4
                : isTablet
                ? (constraints.maxWidth - 18) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _statCard(
                    title: 'Total Patients',
                    value: isLoadingPatientStatus
                        ? '...'
                        : totalPatientsCount.toString(),
                    icon: Icons.people_alt_rounded,
                    color: mainBlue,
                    subtitle: 'Active patients',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _statCard(
                    title: 'Appointments',
                    value: isLoadingAppointments
                        ? '...'
                        : todayAppointmentsCount.toString(),
                    icon: Icons.calendar_month_rounded,
                    color: buttonBlue,
                    subtitle: '$pendingAppointmentsCount pending',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _statCard(
                    title: 'High Risk Cases',
                    value: isLoadingPatientStatus
                        ? '...'
                        : highRiskCount.toString(),
                    icon: Icons.warning_rounded,
                    color: red,
                    subtitle: highRiskCount > 0
                        ? 'Need review'
                        : 'No urgent cases',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _statCard(
                    title: 'In Range Patients',
                    value: isLoadingPatientStatus
                        ? '...'
                        : inRangeCount.toString(),
                    icon: Icons.check_circle_rounded,
                    color: green,
                    subtitle: 'Stable patients',
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 850;

            if (isNarrow) {
              return Column(
                children: [
                  _highRiskPatientsCard(),
                  const SizedBox(height: 20),
                  _todayAppointmentsCard(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _highRiskPatientsCard()),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _todayAppointmentsCard()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _welcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff185FA5), Color(0xff42A5F5)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: mainBlue.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 9),
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
                  'Welcome back, $doctorName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Here is your patients overview for today. Review urgent glucose cases and manage appointments easily.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.monitor_heart_rounded,
              color: Colors.white,
              size: 54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffD7EBFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: textBlue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _highRiskPatientsCard() {
    return _panel(
      title: 'High Risk Patients',
      child: isLoadingPatientStatus
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            )
          : highRiskPatients.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No high risk patients right now.',
                  style: TextStyle(color: Colors.black45, fontSize: 16),
                ),
              ),
            )
          : Column(
              children: highRiskPatients
                  .map((p) => _patientRiskTile(p))
                  .toList(),
            ),
    );
  }

  Widget _patientRiskTile(Map<String, dynamic> patient) {
    final statusColor = _statusColor(patient['status']?.toString() ?? '');

    final glucoseText = patient['lastGlucose'] == null
        ? 'No Data'
        : '${patient['lastGlucose']} mg/dL';

    final ageText = patient['age'] != null
        ? patient['age'].toString()
        : patient['birthDate'] != null
        ? _calculateAge(patient['birthDate']).toString()
        : '-';

    final patientName = patient['name']?.toString() ?? 'Unknown Patient';
    final riskText = patient['risk']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF9FCFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffD7EBFF)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 760;

          final patientInfo = Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: softBlue,
                child: Text(
                  patientName.isEmpty ? '?' : patientName[0].toUpperCase(),
                  style: const TextStyle(
                    color: mainBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Age $ageText • Last reading ${patient['time'] ?? '-'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _badge(glucoseText, statusColor),
              _badge(riskText, statusColor),
              ElevatedButton(
                onPressed: () {
                  final id = patient['patientId']?.toString();

                  if (id == null || id.isEmpty) return;

                  setState(() {
                    selectedPatientId = id;
                    selectedPatientName = patientName;
                    selectedIndex = 1;
                    selectedDateRange = null;
                  });

                  _loadSelectedPatientReadings(id);
                  _loadSelectedPatientDetails(id);
                  _loadSelectedPatientTrend(id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('View'),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [patientInfo, const SizedBox(height: 14), actions],
            );
          }

          return Row(
            children: [
              Expanded(child: patientInfo),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _todayAppointmentsCard() {
    return _panel(
      title: 'Today Appointments',
      child: isLoadingAppointments
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          : doctorAppointments.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No appointments yet.',
                style: TextStyle(color: Colors.black45),
              ),
            )
          : Column(
              children: doctorAppointments
                  .take(4)
                  .map((a) => _realAppointmentTile(a))
                  .toList(),
            ),
    );
  }

  Widget _realAppointmentTile(dynamic appointment) {
    final patient = appointment['patientId'];

    final patientName = patient == null
        ? 'Unknown Patient'
        : '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xffF9FCFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffD7EBFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: softBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.event_available_rounded, color: mainBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName.isEmpty ? 'Unknown Patient' : patientName,
                  style: const TextStyle(
                    color: textBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${appointment['day'] ?? '-'} • ${appointment['time'] ?? '-'} • ${appointment['visitType'] ?? '-'}',
                  style: const TextStyle(color: Colors.black45, fontSize: 13),
                ),
              ],
            ),
          ),
          _badge(appointment['status']?.toString() ?? 'booked', green),
        ],
      ),
    );
  }

  List<dynamic> get _filteredDoctorAppointments {
    if (appointmentFilter == 'all') {
      return doctorAppointments;
    }

    return doctorAppointments.where((appointment) {
      final visitType = appointment['visitType']?.toString().toLowerCase();
      return visitType == appointmentFilter;
    }).toList();
  }

  Future<void> _openMeetingLink(String? link) async {
    if (link == null || link.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No meeting link available')),
      );
      return;
    }

    final uri = Uri.parse(link);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open meeting link')),
      );
    }
  }

  void _viewPatientGlucose(dynamic appointment) {
    final patient = appointment['patientId'];
    if (patient == null) return;

    final patientId = patient['_id']?.toString();
    if (patientId == null || patientId.isEmpty) return;

    final name = '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'
        .trim();

    setState(() {
      selectedPatientId = patientId;
      selectedPatientName = name.isEmpty ? 'Selected Patient' : name;
      selectedIndex = 1; // My Patients
      selectedDateRange = null;
    });

    _loadSelectedPatientReadings(patientId);
    _loadSelectedPatientDetails(patientId);
    _loadSelectedPatientTrend(patientId);
  }

  Future<void> _confirmCancelAppointment(dynamic appointment) async {
    final appointmentId = appointment['_id']?.toString();

    if (appointmentId == null || appointmentId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Cancel Appointment'),
          content: const Text(
            'Are you sure you want to cancel this appointment?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await DoctorAppointmentApi.cancelAppointment(appointmentId);

      await _loadDoctorAppointments();
      await _loadPatientStatus();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _showRescheduleDialog(dynamic appointment) async {
    final appointmentId = appointment['_id']?.toString();

    if (appointmentId == null || appointmentId.isEmpty) return;

    String visitType = appointment['visitType']?.toString() ?? 'online';
    String day = appointment['day']?.toString() ?? 'Sunday';
    final timeController = TextEditingController(
      text: appointment['time']?.toString() ?? '',
    );

    final days = [
      'Saturday',
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text('Reschedule Appointment'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: visitType,
                      decoration: InputDecoration(
                        labelText: 'Visit Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'online',
                          child: Text('Online'),
                        ),
                        DropdownMenuItem(
                          value: 'clinic',
                          child: Text('Clinic'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => visitType = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: day,
                      decoration: InputDecoration(
                        labelText: 'Day',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: days.map((d) {
                        return DropdownMenuItem(value: d, child: Text(d));
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => day = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: timeController,
                      decoration: InputDecoration(
                        labelText: 'Time',
                        hintText: '10:00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newTime = timeController.text.trim();

                    if (newTime.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Time is required')),
                      );
                      return;
                    }

                    try {
                      await DoctorAppointmentApi.updateAppointment(
                        appointmentId: appointmentId,
                        visitType: visitType,
                        day: day,
                        time: newTime,
                      );

                      await _loadDoctorAppointments();
                      await _loadPatientStatus();

                      if (!mounted) return;

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Appointment updated successfully'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceAll('Exception: ', ''),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _patientsPage() {
    if (selectedPatientId != null) {
      return _patientDetailsPage();
    }

    return _panel(
      title: 'My Patients',
      child: isLoadingPatientStatus
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            )
          : dashboardPatients.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No patients found yet.',
                  style: TextStyle(color: Colors.black45, fontSize: 16),
                ),
              ),
            )
          : Column(
              children: dashboardPatients.map((patient) {
                return _patientListCard(patient);
              }).toList(),
            ),
    );
  }

  Widget _patientListCard(dynamic patient) {
    final patientId = patient['patientId']?.toString();
    final name = patient['name']?.toString() ?? 'Unknown Patient';
    final email = patient['email']?.toString() ?? '-';

    final age = patient['age'] != null
        ? patient['age'].toString()
        : patient['birthDate'] != null
        ? _calculateAge(patient['birthDate']).toString()
        : '-';

    final glucoseValue = patient['lastGlucose'];
    final status = patient['status']?.toString() ?? 'No Data';
    final risk = patient['risk']?.toString() ?? 'No Data';

    final statusColor = _statusColor(status);

    String statusText;
    IconData statusIcon;

    if (glucoseValue == null || status == 'No Data') {
      statusText = 'Overall status: No glucose readings available yet';
      statusIcon = Icons.info_outline_rounded;
    } else if (status.toLowerCase().contains('low')) {
      statusText = 'Overall status: Low glucose - hypoglycemia risk';
      statusIcon = Icons.trending_down_rounded;
    } else if (status.toLowerCase().contains('high')) {
      statusText = 'Overall status: High glucose - urgent review needed';
      statusIcon = Icons.trending_up_rounded;
    } else if (risk.toLowerCase().contains('review')) {
      statusText = 'Overall status: Needs review';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusText = 'Overall status: Stable today';
      statusIcon = Icons.check_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF9FCFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffD7EBFF)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 760;

          final patientInfo = Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: softBlue,
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: mainBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Age $age • $email',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final openButton = ElevatedButton.icon(
            onPressed: () {
              if (patientId == null || patientId.isEmpty) return;

              setState(() {
                selectedPatientId = patientId;
                selectedPatientName = name;
                selectedDateRange = null;
                patientAiSuggestion = '';
                selectedPatientTrend = null;
              });

              _loadSelectedPatientReadings(patientId);
              _loadSelectedPatientDetails(patientId);
              _loadSelectedPatientTrend(patientId);
            },
            icon: const Icon(Icons.visibility_rounded, size: 18),
            label: const Text('Open'),
            style: ElevatedButton.styleFrom(
              backgroundColor: mainBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                patientInfo,
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerRight, child: openButton),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: patientInfo),
              const SizedBox(width: 14),
              openButton,
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadSelectedPatientDetails(String patientId) async {
    try {
      setState(() {
        isLoadingSelectedPatientDetails = true;
        selectedPatientDetails = null;
      });

      final data = await DoctorDashboardApi.getPatientDetails(patientId);

      setState(() {
        selectedPatientDetails = data;
        isLoadingSelectedPatientDetails = false;
      });
    } catch (e) {
      debugPrint('Failed to load patient details: $e');

      setState(() {
        isLoadingSelectedPatientDetails = false;
      });
    }
  }

  Future<void> _loadSelectedPatientTrend(String patientId) async {
    try {
      setState(() {
        isLoadingPatientTrend = true;
        selectedPatientTrend = null;
      });

      final data = await DoctorDashboardApi.getPatientTrend(patientId);

      setState(() {
        selectedPatientTrend = data;
        isLoadingPatientTrend = false;
      });
    } catch (e) {
      debugPrint('Failed to load patient trend: $e');

      setState(() {
        isLoadingPatientTrend = false;
      });
    }
  }

  Future<void> _loadPatientAiSuggestion() async {
    if (selectedPatientDetails == null || selectedPatientReadings.isEmpty) {
      setState(() {
        patientAiSuggestion =
            'Not enough patient data to generate an AI suggestion.';
      });
      return;
    }

    final patient = selectedPatientDetails?['patient'] ?? {};
    final medical = selectedPatientDetails?['medical'] ?? {};

    final trend = selectedPatientTrend?['trend']?.toString() ?? 'Unknown';
    final riskScore = _calculatePatientRiskScore();
    final timeInRange = _calculateTimeInRange();

    try {
      setState(() {
        isLoadingAiSuggestion = true;
        patientAiSuggestion = '';
      });

      final suggestion = await DoctorDashboardApi.getPatientAiSuggestion(
        patientName: patient['fullName']?.toString() ?? selectedPatientName,
        age: patient['age'],
        readings: selectedPatientReadings,
        trend: trend,
        riskScore: riskScore,
        timeInRange: timeInRange,
        carbRatio: medical['carbRatio']?.toString() ?? '',
        correctionFactor: medical['correctionFactor']?.toString() ?? '',
        lantusDose: medical['lantusDose'],
        lantusTime: medical['lantusTime']?.toString() ?? '',
        weight: medical['weight'],
        height: medical['height'],
      );

      if (!mounted) return;

      setState(() {
        patientAiSuggestion = suggestion;
        isLoadingAiSuggestion = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingAiSuggestion = false;
        patientAiSuggestion = 'AI suggestion is not available right now.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Widget _aiClinicalSuggestionCard() {
    return _panel(
      title: 'AI Clinical Suggestion',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xffF9FCFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffD7EBFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: mainBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: mainBlue,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'AI reviews the patient readings, trend, risk score, and medical parameters to suggest what may need doctor review.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (isLoadingAiSuggestion)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Text(
                patientAiSuggestion.isEmpty
                    ? 'Click Generate AI Suggestion to analyze this patient.'
                    : patientAiSuggestion,
                style: const TextStyle(
                  color: textBlue,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),

            const SizedBox(height: 18),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: isLoadingAiSuggestion
                    ? null
                    : _loadPatientAiSuggestion,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  isLoadingAiSuggestion
                      ? 'Generating...'
                      : 'Generate AI Suggestion',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patientTrendCard() {
    Color trendColor = mainBlue;
    IconData trendIcon = Icons.trending_flat_rounded;

    final trend = selectedPatientTrend?['trend']?.toString() ?? '';
    final message = selectedPatientTrend?['message']?.toString() ?? '';
    final slope = selectedPatientTrend?['slope']?.toString() ?? '0';
    final readingsCount =
        selectedPatientTrend?['readingsCount']?.toString() ?? '0';

    if (trend.toLowerCase().contains('rising')) {
      trendColor = orange;
      trendIcon = Icons.trending_up_rounded;
    } else if (trend.toLowerCase().contains('dropping')) {
      trendColor = red;
      trendIcon = Icons.trending_down_rounded;
    } else if (trend.toLowerCase().contains('stable')) {
      trendColor = green;
      trendIcon = Icons.trending_flat_rounded;
    }

    return _panel(
      title: 'Glucose Trend Prediction',
      child: isLoadingPatientTrend
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          : selectedPatientTrend == null
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'No trend data available yet.',
                style: TextStyle(color: Colors.black45),
              ),
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xffF9FCFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xffD7EBFF)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: trendColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(trendIcon, color: trendColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trend.isEmpty ? 'Unknown Trend' : trend,
                          style: TextStyle(
                            color: trendColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Based on $readingsCount recent readings • Slope: $slope',
                          style: const TextStyle(
                            color: Colors.black38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _patientDetailsPage() {
    return Column(
      children: [
        _panel(
          title: 'Patient Details - $selectedPatientName',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    selectedPatientId = null;
                    selectedPatientName = 'Select Patient';
                    selectedPatientReadings = [];
                    selectedDateRange = null;
                    selectedPatientDetails = null;
                    selectedPatientTrend = null;
                    patientAiSuggestion = '';
                    isEditingPatientParams = false;
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Patients'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: mainBlue,
                  side: const BorderSide(color: mainBlue),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _panel(
                title: 'Glucose Readings',
                child: Column(
                  children: [
                    InkWell(
                      onTap: _pickDateRange,
                      borderRadius: BorderRadius.circular(16),
                      child: _fakeInput(_dateRangeText(), Icons.date_range),
                    ),

                    const SizedBox(height: 22),

                    isLoadingSelectedReadings
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(30),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : selectedPatientReadings.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No glucose readings found for this patient.',
                                style: TextStyle(
                                  color: Colors.black45,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        : _buildDoctorGlucoseChart(),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _patientTrendCard(),

              const SizedBox(height: 24),

              const SizedBox(height: 24),

              _aiClinicalSuggestionCard(),

              const SizedBox(height: 24),

              _patientReportsPanel(),

              const SizedBox(height: 24),

              _patientMedicalParametersPanel(),
            ],
          ),
        ),
      ],
    );
  }

  void _startEditPatientParams() {
    final medical = selectedPatientDetails?['medical'] ?? {};

    setState(() {
      isEditingPatientParams = true;

      editCarbRatioController.text = medical['carbRatio']?.toString() ?? '';
      editCorrectionFactorController.text =
          medical['correctionFactor']?.toString() ?? '';
      editLantusDoseController.text = medical['lantusDose']?.toString() ?? '';
      editLantusTimeController.text = medical['lantusTime']?.toString() ?? '';
      editWeightController.text = medical['weight']?.toString() ?? '';
      editHeightController.text = medical['height']?.toString() ?? '';
      editHasFoodAllergy = medical['hasFoodAllergy'] == true;
      editAllergyController.text = medical['allergyDetails']?.toString() ?? '';
    });
  }

  Future<void> _saveInlinePatientParams() async {
    if (selectedPatientId == null) return;

    final lantusDose =
        double.tryParse(editLantusDoseController.text.trim()) ?? 0;
    final weight = double.tryParse(editWeightController.text.trim()) ?? 0;
    final height = double.tryParse(editHeightController.text.trim()) ?? 0;

    try {
      setState(() => isSavingPatientParams = true);

      await DoctorDashboardApi.updatePatientMedicalParams(
        patientId: selectedPatientId!,
        carbRatio: editCarbRatioController.text.trim(),
        correctionFactor: editCorrectionFactorController.text.trim(),
        lantusDose: lantusDose,
        lantusTime: editLantusTimeController.text.trim(),
        weight: weight,
        height: height,
        hasFoodAllergy: editHasFoodAllergy,
        allergyDetails: editHasFoodAllergy
            ? editAllergyController.text.trim()
            : '',
      );

      await _loadSelectedPatientDetails(selectedPatientId!);

      if (!mounted) return;

      setState(() {
        isEditingPatientParams = false;
        isSavingPatientParams = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient parameters updated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => isSavingPatientParams = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Widget _patientMedicalParametersPanel() {
    if (isLoadingSelectedPatientDetails) {
      return _panel(
        title: 'Patient Medical Parameters',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final patient = selectedPatientDetails?['patient'] ?? {};
    final medical = selectedPatientDetails?['medical'] ?? {};

    final fullName = patient['fullName']?.toString() ?? '-';
    final age = patient['age'] != null
        ? patient['age'].toString()
        : patient['birthDate'] != null
        ? _calculateAge(patient['birthDate']).toString()
        : '-';

    final carbRatio = medical['carbRatio']?.toString().isNotEmpty == true
        ? medical['carbRatio'].toString()
        : '-';

    final correctionFactor =
        medical['correctionFactor']?.toString().isNotEmpty == true
        ? medical['correctionFactor'].toString()
        : '-';

    final lantusDose = medical['lantusDose'] == null
        ? '-'
        : medical['lantusDose'].toString();

    final lantusTime = medical['lantusTime']?.toString().isNotEmpty == true
        ? medical['lantusTime'].toString()
        : '-';

    final weight = medical['weight'] == null ? '-' : '${medical['weight']} kg';
    final height = medical['height'] == null ? '-' : '${medical['height']} cm';

    final allergies = medical['hasFoodAllergy'] == true
        ? (medical['allergyDetails']?.toString().isNotEmpty == true
              ? medical['allergyDetails'].toString()
              : 'Food allergy exists')
        : 'No food allergies';

    return _panel(
      title: 'Patient Medical Parameters',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isEditingPatientParams) ...[
            Row(
              children: [
                Expanded(child: _profileInfo('Full Name', fullName)),
                const SizedBox(width: 14),
                Expanded(child: _profileInfo('Age', age)),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(child: _profileInfo('Carb Ratio', carbRatio)),
                const SizedBox(width: 14),
                Expanded(
                  child: _profileInfo('Correction Factor', correctionFactor),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(child: _profileInfo('Lantus Dose', lantusDose)),
                const SizedBox(width: 14),
                Expanded(child: _profileInfo('Lantus Time', lantusTime)),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(child: _profileInfo('Weight', weight)),
                const SizedBox(width: 14),
                Expanded(child: _profileInfo('Height', height)),
              ],
            ),
            const SizedBox(height: 14),

            _profileInfo('Allergies', allergies),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _startEditPatientParams,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Parameters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(child: _profileInfo('Full Name', fullName)),
                const SizedBox(width: 14),
                Expanded(child: _profileInfo('Age', age)),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _editParamField(
                    label: 'Carb Ratio',
                    controller: editCarbRatioController,
                    icon: Icons.restaurant_rounded,
                    hint: 'Example: 1:15',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _editParamField(
                    label: 'Correction Factor',
                    controller: editCorrectionFactorController,
                    icon: Icons.calculate_rounded,
                    hint: 'Example: 50',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _editParamField(
                    label: 'Lantus Dose',
                    controller: editLantusDoseController,
                    icon: Icons.medication_rounded,
                    keyboardType: TextInputType.number,
                    hint: 'Example: 10',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _editParamField(
                    label: 'Lantus Time',
                    controller: editLantusTimeController,
                    icon: Icons.access_time_rounded,
                    hint: 'Example: 9:00 PM',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _editParamField(
                    label: 'Weight',
                    controller: editWeightController,
                    icon: Icons.monitor_weight_outlined,
                    keyboardType: TextInputType.number,
                    hint: 'kg',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _editParamField(
                    label: 'Height',
                    controller: editHeightController,
                    icon: Icons.height_rounded,
                    keyboardType: TextInputType.number,
                    hint: 'cm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xffF9FCFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xffD7EBFF)),
              ),
              child: SwitchListTile(
                value: editHasFoodAllergy,
                activeColor: mainBlue,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Has Food Allergy',
                  style: TextStyle(
                    color: textBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    editHasFoodAllergy = value;
                  });
                },
              ),
            ),

            if (editHasFoodAllergy) ...[
              const SizedBox(height: 14),
              _editParamField(
                label: 'Allergy Details',
                controller: editAllergyController,
                icon: Icons.warning_amber_rounded,
                hint: 'Example: peanuts, milk...',
              ),
            ],

            const SizedBox(height: 22),

            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: isSavingPatientParams
                        ? null
                        : () {
                            setState(() {
                              isEditingPatientParams = false;
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: red,
                      side: const BorderSide(color: red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(t('cancel')),
                  ),
                  ElevatedButton.icon(
                    onPressed: isSavingPatientParams
                        ? null
                        : _saveInlinePatientParams,
                    icon: isSavingPatientParams
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(isSavingPatientParams ? 'Saving...' : 'Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _editParamField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: buttonBlue),
        filled: true,
        fillColor: const Color(0xffF9FCFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffD7EBFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffD7EBFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: mainBlue, width: 1.4),
        ),
      ),
    );
  }

  Map<String, double> _calculateTimeInRange() {
    final readings = selectedPatientReadings;

    if (readings.isEmpty) {
      return {'low': 0, 'inRange': 0, 'high': 0};
    }

    final total = readings.length;

    final lowCount = readings.where((r) => r['status'] == 'low').length;
    final highCount = readings.where((r) => r['status'] == 'high').length;
    final inRangeCount = readings.where((r) {
      final status = r['status']?.toString().toLowerCase() ?? '';
      return status == 'normal' || status == 'in range';
    }).length;

    return {
      'low': (lowCount / total) * 100,
      'inRange': (inRangeCount / total) * 100,
      'high': (highCount / total) * 100,
    };
  }

  int _calculatePatientRiskScore() {
    final readings = selectedPatientReadings;

    if (readings.isEmpty) return 0;

    final total = readings.length;

    final lowCount = readings.where((r) => r['status'] == 'low').length;
    final highCount = readings.where((r) => r['status'] == 'high').length;

    final abnormalPercent = ((lowCount + highCount) / total) * 100;

    final values = readings.map((r) => (r['value'] as num).toDouble()).toList();

    final avg = values.reduce((a, b) => a + b) / values.length;

    double score = 0;

    // 40% based on abnormal readings
    score += abnormalPercent * 0.4;

    // 30% based on average glucose
    if (avg > 250 || avg < 70) {
      score += 30;
    } else if (avg > 180 || avg < 80) {
      score += 20;
    } else {
      score += 5;
    }

    // 30% based on repeated dangerous events
    if (lowCount >= 3 || highCount >= 3) {
      score += 30;
    } else if (lowCount >= 2 || highCount >= 2) {
      score += 20;
    } else {
      score += 5;
    }

    return score.clamp(0, 100).round();
  }

  String _riskLevelText(int score) {
    if (score >= 70) return 'High Risk';
    if (score >= 40) return 'Moderate Risk';
    return 'Low Risk';
  }

  Color _riskLevelColor(int score) {
    if (score >= 70) return red;
    if (score >= 40) return orange;
    return green;
  }

  Widget _timeInRangeCard() {
    final tir = _calculateTimeInRange();

    final low = tir['low'] ?? 0;
    final inRange = tir['inRange'] ?? 0;
    final high = tir['high'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffF9FCFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffD7EBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time In Range',
            style: TextStyle(
              color: textBlue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Percentage of readings within low, normal, and high glucose ranges.',
            style: TextStyle(color: Colors.black45, fontSize: 13),
          ),
          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                if (low > 0)
                  Expanded(
                    flex: low.round(),
                    child: Container(height: 18, color: red.withOpacity(0.75)),
                  ),
                if (inRange > 0)
                  Expanded(
                    flex: inRange.round(),
                    child: Container(
                      height: 18,
                      color: green.withOpacity(0.75),
                    ),
                  ),
                if (high > 0)
                  Expanded(
                    flex: high.round(),
                    child: Container(
                      height: 18,
                      color: orange.withOpacity(0.75),
                    ),
                  ),
                if (low == 0 && inRange == 0 && high == 0)
                  Expanded(child: Container(height: 18, color: Colors.black12)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _tirLegend('Low', '${low.toStringAsFixed(0)}%', red),
              _tirLegend('In Range', '${inRange.toStringAsFixed(0)}%', green),
              _tirLegend('High', '${high.toStringAsFixed(0)}%', orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tirLegend(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _patientRiskScoreCard() {
    final score = _calculatePatientRiskScore();
    final level = _riskLevelText(score);
    final color = _riskLevelColor(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffF9FCFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffD7EBFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                '$score',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Patient Risk Score',
                  style: TextStyle(
                    color: textBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  level,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Calculated from abnormal readings, glucose average, and repeated high/low events.',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientReportsPanel() {
    final readings = selectedPatientReadings;

    final lowCount = readings.where((r) => r['status'] == 'low').length;
    final highCount = readings.where((r) => r['status'] == 'high').length;

    final avg = readings.isEmpty
        ? 0
        : readings
                  .map((r) => (r['value'] as num).toDouble())
                  .reduce((a, b) => a + b) /
              readings.length;

    final estimatedA1c = readings.isEmpty
        ? '-'
        : ((avg + 46.7) / 28.7).toStringAsFixed(1);

    return _panel(
      title: 'Patient Reports',
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final isTablet =
                  constraints.maxWidth >= 600 && constraints.maxWidth < 900;

              final cardWidth = isWide
                  ? (constraints.maxWidth - 42) / 4
                  : isTablet
                  ? (constraints.maxWidth - 14) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _reportMiniCard(
                      title: 'Average Glucose',
                      value: readings.isEmpty
                          ? '-'
                          : '${avg.toStringAsFixed(0)} mg/dL',
                      icon: Icons.analytics_rounded,
                      color: mainBlue,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _reportMiniCard(
                      title: 'Estimated A1C',
                      value: estimatedA1c == '-' ? '-' : '$estimatedA1c%',
                      icon: Icons.bar_chart_rounded,
                      color: orange,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _reportMiniCard(
                      title: 'Low Events',
                      value: '$lowCount times',
                      icon: Icons.trending_down_rounded,
                      color: red,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _reportMiniCard(
                      title: 'High Events',
                      value: '$highCount times',
                      icon: Icons.trending_up_rounded,
                      color: orange,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 800;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _timeInRangeCard()),
                    const SizedBox(width: 14),
                    Expanded(child: _patientRiskScoreCard()),
                  ],
                );
              }

              return Column(
                children: [
                  _timeInRangeCard(),
                  const SizedBox(height: 14),
                  _patientRiskScoreCard(),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                if (selectedPatientId == null || selectedPatientId!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a patient first'),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ReportsScreen(userId: selectedPatientId!),
                  ),
                );
              },
              icon: const Icon(Icons.insert_chart_rounded),
              label: const Text('View Full Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: mainBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportMiniCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffF9FCFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffD7EBFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appointmentFilterChip(String label, String value) {
    final selected = appointmentFilter == value;

    return InkWell(
      onTap: () {
        setState(() {
          appointmentFilter = value;
        });
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? mainBlue : const Color(0xffF9FCFF),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? mainBlue : const Color(0xffD7EBFF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : textBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _appointmentManagementCard(dynamic appointment) {
    final patient = appointment['patientId'];

    final patientName = patient == null
        ? 'Unknown Patient'
        : '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();

    final email = patient == null ? '-' : patient['email']?.toString() ?? '-';
    final visitType = appointment['visitType']?.toString() ?? '-';
    final day = appointment['day']?.toString() ?? '-';
    final time = appointment['time']?.toString() ?? '-';
    final status = appointment['status']?.toString() ?? 'booked';
    final meetingLink = appointment['meetingLink']?.toString() ?? '';

    final isOnline = visitType == 'online';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF9FCFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffD7EBFF)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          final patientInfo = Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: softBlue,
                child: Text(
                  patientName.isEmpty ? '?' : patientName[0].toUpperCase(),
                  style: const TextStyle(
                    color: mainBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName.isEmpty ? 'Unknown Patient' : patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final appointmentInfo = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(visitType, isOnline ? buttonBlue : orange),
              _badge('$day • $time', mainBlue),
              _badge(status, green),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isOnline)
                _smallActionButton(
                  label: 'Join Meet',
                  icon: Icons.video_call_rounded,
                  color: green,
                  onTap: () => _openMeetingLink(meetingLink),
                ),
              _smallActionButton(
                label: 'View Glucose',
                icon: Icons.monitor_heart_rounded,
                color: mainBlue,
                onTap: () => _viewPatientGlucose(appointment),
              ),
              _smallActionButton(
                label: 'Reschedule',
                icon: Icons.edit_calendar_rounded,
                color: orange,
                onTap: () => _showRescheduleDialog(appointment),
              ),
              _smallActionButton(
                label: 'Cancel',
                icon: Icons.cancel_rounded,
                color: red,
                onTap: () => _confirmCancelAppointment(appointment),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                patientInfo,
                const SizedBox(height: 14),
                appointmentInfo,
                const SizedBox(height: 14),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: patientInfo),
              Expanded(flex: 2, child: appointmentInfo),
              Expanded(flex: 4, child: actions),
            ],
          );
        },
      ),
    );
  }

  Widget _smallActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.12),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  List<String> _generateSlots(String start, String end) {
    int? toMinutes(String time) {
      final parts = time.trim().split(' ');

      if (parts.length != 2) return null;

      final timePart = parts[0];
      final period = parts[1].toUpperCase();

      final hm = timePart.split(':');
      if (hm.length != 2) return null;

      int? hour = int.tryParse(hm[0]);
      final minute = int.tryParse(hm[1]);

      if (hour == null || minute == null) return null;
      if (period != 'AM' && period != 'PM') return null;

      if (period == 'AM') {
        if (hour == 12) hour = 0;
      } else {
        if (hour != 12) hour += 12;
      }

      return hour * 60 + minute;
    }

    String fromMinutes(int totalMinutes) {
      var hour24 = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;

      final period = hour24 >= 12 ? 'PM' : 'AM';

      var hour12 = hour24 % 12;
      if (hour12 == 0) hour12 = 12;

      final hourText = hour12.toString().padLeft(2, '0');
      final minuteText = minute.toString().padLeft(2, '0');

      return '$hourText:$minuteText $period';
    }

    final startTotal = toMinutes(start);
    final endTotal = toMinutes(end);

    if (startTotal == null || endTotal == null) {
      return [];
    }

    if (startTotal >= endTotal) {
      return [];
    }

    final slots = <String>[];
    var current = startTotal;

    while (current < endTotal) {
      slots.add(fromMinutes(current));
      current += 60;
    }

    return slots;
  }

  Future<void> _addAvailableTimeFromBoxes() async {
    final slots = _generateSlots(
      selectedAvailableStartTime,
      selectedAvailableEndTime,
    );

    if (slots.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid time range')));
      return;
    }

    try {
      await DoctorAppointmentApi.addAvailability(
        doctorId: widget.doctorId,
        visitType: selectedAvailableVisitType,
        day: selectedAvailableDay,
        startTime: selectedAvailableStartTime,
        endTime: selectedAvailableEndTime,
        slots: slots,
      );

      await _loadDoctorAvailability();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Available time added successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Widget _selectBox({
    required String value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xffF9FCFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffD7EBFF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black38,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, color: buttonBlue, size: 21),
                  const SizedBox(width: 10),
                  Text(item, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue == null) return;
            onChanged(newValue);
          },
        ),
      ),
    );
  }

  List<String> _timeOptions() {
    return [
      '08:00 AM',
      '08:30 AM',
      '09:00 AM',
      '09:30 AM',
      '10:00 AM',
      '10:30 AM',
      '11:00 AM',
      '11:30 AM',
      '12:00 PM',
      '12:30 PM',
      '01:00 PM',
      '01:30 PM',
      '02:00 PM',
      '02:30 PM',
      '03:00 PM',
      '03:30 PM',
      '04:00 PM',
      '04:30 PM',
      '05:00 PM',
      '05:30 PM',
      '06:00 PM',
    ];
  }

  String _normalizeTimeForDropdown(String value) {
    final time = value.trim();

    if (_timeOptions().contains(time)) {
      return time;
    }

    if (!time.contains('AM') && !time.contains('PM')) {
      final parts = time.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = parts[1].padLeft(2, '0');

        if (hour != null) {
          if (hour == 0) return '12:$minute AM';
          if (hour < 12) return '${hour.toString().padLeft(2, '0')}:$minute AM';
          if (hour == 12) return '12:$minute PM';

          final hour12 = hour - 12;
          return '${hour12.toString().padLeft(2, '0')}:$minute PM';
        }
      }
    }

    return '10:00 AM';
  }

  Future<void> _confirmDeleteAvailability(dynamic item) async {
    final availabilityId = item['_id']?.toString();

    if (availabilityId == null || availabilityId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete Available Time'),
          content: const Text(
            'Are you sure you want to delete this available time?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await DoctorAppointmentApi.deleteAvailability(availabilityId);
      await _loadDoctorAvailability();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Available time deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _showEditAvailabilityDialog(dynamic item) async {
    final availabilityId = item['_id']?.toString();

    if (availabilityId == null || availabilityId.isEmpty) return;

    final oldSlots = item['slots'] ?? [];

    String day = item['day']?.toString() ?? 'Sunday';
    String visitType = item['visitType']?.toString() ?? 'online';

    String startTime = _normalizeTimeForDropdown(
      item['startTime']?.toString() ??
          (oldSlots.isNotEmpty ? oldSlots.first.toString() : '10:00 AM'),
    );

    String endTime = _normalizeTimeForDropdown(
      item['endTime']?.toString() ?? '11:00 AM',
    );

    final days = [
      'Saturday',
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text('Edit Available Time'),
              content: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: day,
                      decoration: InputDecoration(
                        labelText: 'Day',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: days.map((d) {
                        return DropdownMenuItem(value: d, child: Text(d));
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => day = value);
                      },
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: startTime,
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: _timeOptions().map((time) {
                        return DropdownMenuItem(value: time, child: Text(time));
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => startTime = value);
                      },
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: endTime,
                      decoration: InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: _timeOptions().map((time) {
                        return DropdownMenuItem(value: time, child: Text(time));
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => endTime = value);
                      },
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: visitType,
                      decoration: InputDecoration(
                        labelText: 'Visit Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'online',
                          child: Text('Online'),
                        ),
                        DropdownMenuItem(
                          value: 'clinic',
                          child: Text('Clinic'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => visitType = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final slots = _generateSlots(startTime, endTime);

                    if (slots.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid time range')),
                      );
                      return;
                    }

                    try {
                      await DoctorAppointmentApi.updateAvailability(
                        availabilityId: availabilityId,
                        visitType: visitType,
                        day: day,
                        startTime: startTime,
                        endTime: endTime,
                        slots: slots,
                      );

                      await _loadDoctorAvailability();

                      if (!mounted) return;

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Available time updated successfully'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceAll('Exception: ', ''),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _availableSlotsPanel() {
    return _panel(
      title: 'Available Slots',
      child: isLoadingAvailability
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          : doctorAvailability.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No available slots added yet.',
                style: TextStyle(color: Colors.black45),
              ),
            )
          : Column(
              children: doctorAvailability.map((item) {
                final day = item['day']?.toString() ?? '-';
                final visitType = item['visitType']?.toString() ?? '-';
                final slots = item['slots'] ?? [];

                final startTime = item['startTime']?.toString() ?? '';
                final endTime = item['endTime']?.toString() ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xffF9FCFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xffD7EBFF)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 700;

                      final info = Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: softBlue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.schedule_rounded,
                              color: mainBlue,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  startTime.isNotEmpty && endTime.isNotEmpty
                                      ? '$day • $visitType • $startTime - $endTime'
                                      : '$day • $visitType',
                                  style: const TextStyle(
                                    color: textBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: List.generate(slots.length, (
                                    index,
                                  ) {
                                    return _badge(
                                      slots[index].toString(),
                                      mainBlue,
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      final actions = Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _smallActionButton(
                            label: 'Edit',
                            icon: Icons.edit_calendar_rounded,
                            color: orange,
                            onTap: () => _showEditAvailabilityDialog(item),
                          ),
                          _smallActionButton(
                            label: 'Delete',
                            icon: Icons.delete_rounded,
                            color: red,
                            onTap: () => _confirmDeleteAvailability(item),
                          ),
                        ],
                      );

                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [info, const SizedBox(height: 14), actions],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: info),
                          const SizedBox(width: 14),
                          actions,
                        ],
                      );
                    },
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _appointmentsPage() {
    final filteredAppointments = _filteredDoctorAppointments;

    final days = [
      'Saturday',
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
    ];

    return Column(
      children: [
        _panel(
          title: 'Add Available Time',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 750;

              final fields = [
                _selectBox(
                  value: selectedAvailableDay,
                  icon: Icons.calendar_today_rounded,
                  items: days,
                  onChanged: (value) {
                    setState(() {
                      selectedAvailableDay = value;
                    });
                  },
                ),
                _selectBox(
                  value: selectedAvailableStartTime,
                  icon: Icons.access_time,
                  items: _timeOptions(),
                  onChanged: (value) {
                    setState(() {
                      selectedAvailableStartTime = value;
                    });
                  },
                ),
                _selectBox(
                  value: selectedAvailableEndTime,
                  icon: Icons.access_time_filled,
                  items: _timeOptions(),
                  onChanged: (value) {
                    setState(() {
                      selectedAvailableEndTime = value;
                    });
                  },
                ),
                _selectBox(
                  value: selectedAvailableVisitType,
                  icon: Icons.videocam,
                  items: const ['online', 'clinic'],
                  onChanged: (value) {
                    setState(() {
                      selectedAvailableVisitType = value;
                    });
                  },
                ),
              ];

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...fields.expand(
                      (field) => [field, const SizedBox(height: 12)],
                    ),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _addAvailableTimeFromBoxes,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Slot'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: fields[0]),
                  const SizedBox(width: 14),
                  Expanded(child: fields[1]),
                  const SizedBox(width: 14),
                  Expanded(child: fields[2]),
                  const SizedBox(width: 14),
                  Expanded(child: fields[3]),
                  const SizedBox(width: 14),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _addAvailableTimeFromBoxes,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Slot'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 22),

        _availableSlotsPanel(),

        const SizedBox(height: 22),

        _panel(
          title: 'Booked Appointments',
          child: isLoadingAppointments
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _appointmentFilterChip('All', 'all'),
                        _appointmentFilterChip('Online', 'online'),
                        _appointmentFilterChip('Clinic', 'clinic'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (filteredAppointments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No booked appointments found.',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: filteredAppointments.map((appointment) {
                          return _appointmentManagementCard(appointment);
                        }).toList(),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildDoctorGlucoseChart() {
    if (selectedPatientId == null) {
      return Container(
        height: 340,
        width: double.infinity,
        decoration: BoxDecoration(
          color: mainBlue,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            'Select a patient to view glucose readings',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (isLoadingSelectedReadings) {
      return Container(
        height: 340,
        width: double.infinity,
        decoration: BoxDecoration(
          color: mainBlue,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (selectedPatientReadings.isEmpty) {
      return Container(
        height: 340,
        width: double.infinity,
        decoration: BoxDecoration(
          color: mainBlue,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            'No glucose readings for this patient yet.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final recentReadings = selectedPatientReadings.length > 8
        ? selectedPatientReadings.sublist(selectedPatientReadings.length - 8)
        : selectedPatientReadings;

    final spots = <FlSpot>[];

    for (int i = 0; i < recentReadings.length; i++) {
      final value = double.tryParse(recentReadings[i]['value'].toString()) ?? 0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    final values = spots.map((e) => e.y).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    final minY = (minValue - 30).clamp(0, 600).toDouble();
    final maxY = (maxValue + 30).clamp(120, 650).toDouble();

    return Container(
      height: 380,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 28, 18),
      decoration: BoxDecoration(
        color: mainBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: mainBlue.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          rangeAnnotations: RangeAnnotations(
            horizontalRangeAnnotations: [
              HorizontalRangeAnnotation(
                y1: 70,
                y2: 180,
                color: Colors.green.withOpacity(0.18),
              ),
            ],
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.white.withOpacity(0.12), strokeWidth: 1),
            getDrawingVerticalLine: (_) =>
                FlLine(color: Colors.white.withOpacity(0.08), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index < 0 || index >= recentReadings.length) {
                    return const SizedBox();
                  }

                  final time = DateTime.tryParse(
                    recentReadings[index]['readingTime'].toString(),
                  );

                  if (time == null) return const SizedBox();

                  final hour = time.hour.toString().padLeft(2, '0');
                  final minute = time.minute.toString().padLeft(2, '0');

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '$hour:$minute',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.white,
              tooltipRoundedRadius: 12,
              getTooltipItems: (spotsTouched) {
                return spotsTouched.map((spot) {
                  final index = spot.x.toInt();
                  final reading = recentReadings[index];

                  final time = DateTime.tryParse(
                    reading['readingTime'].toString(),
                  );

                  final timeText = time == null
                      ? ''
                      : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(0)} mg/dL\n$timeText',
                    TextStyle(
                      color: _getGlucoseColor(spot.y),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 4,
              color: Colors.white,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.white.withOpacity(0.12),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: _getGlucoseColor(spot.y),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGlucoseColor(double value) {
    if (value < 70) return red;
    if (value > 180) return red;
    if (value > 140) return orange;
    return green;
  }

  Widget _messagesPage() {
    return _panel(
      title: 'Messages',
      child: isLoadingPatientStatus
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            )
          : dashboardPatients.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No patients found yet.',
                  style: TextStyle(color: Colors.black45, fontSize: 16),
                ),
              ),
            )
          : Column(
              children: dashboardPatients.map((patient) {
                final patientId = patient['patientId']?.toString();
                final name = patient['name']?.toString() ?? 'Unknown Patient';
                final email = patient['email']?.toString() ?? '-';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xffF9FCFF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xffD7EBFF)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: softBlue,
                        child: Text(
                          name.isEmpty ? '?' : name[0].toUpperCase(),
                          style: const TextStyle(
                            color: mainBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: textBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (patientId == null || patientId.isEmpty) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                currentUserId: widget.doctorId,
                                receiverId: patientId,
                                receiverName: name,
                                receiverRole: 'patient',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Open Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  void _startEditProfile() {
    final years = doctorExperience.replaceAll(' years', '').trim();

    setState(() {
      isEditingProfile = true;

      editFullNameController.text = doctorName;
      editWorkplaceController.text = doctorWorkplace;
      editYearsController.text = years;

      editSpecialty = doctorSpecialty.isEmpty
          ? 'Diabetes Specialist'
          : doctorSpecialty;

      editTreatsType1 = doctorTreatsType1.toLowerCase() == 'no' ? 'No' : 'Yes';

      editAgeChildren = doctorAgeGroups.contains('Children');
      editAgeAdolescents = doctorAgeGroups.contains('Adolescents');
      editAgeAdults = doctorAgeGroups.contains('Adults');
      editAgeAllAges = doctorAgeGroups.contains('All Ages');
    });
  }

  Future<void> _saveInlineDoctorProfile() async {
    final fullName = editFullNameController.text.trim();
    final workplace = editWorkplaceController.text.trim();
    final years = int.tryParse(editYearsController.text.trim()) ?? 0;

    if (fullName.isEmpty || workplace.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (!editAgeChildren &&
        !editAgeAdolescents &&
        !editAgeAdults &&
        !editAgeAllAges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one age group')),
      );
      return;
    }

    try {
      setState(() => isSavingProfile = true);

      await DoctorDashboardApi.updateDoctorProfile(
        doctorId: widget.doctorId,
        fullName: fullName,
        specialty: editSpecialty,
        workplace: workplace,
        yearsOfExperience: years,
        treatsType1: editTreatsType1,
        ageChildren: editAgeChildren,
        ageAdolescents: editAgeAdolescents,
        ageAdults: editAgeAdults,
        ageAllAges: editAgeAllAges,
      );

      await _loadDoctorProfile();

      if (!mounted) return;

      setState(() {
        isEditingProfile = false;
        isSavingProfile = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => isSavingProfile = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Widget _responsiveInfoGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final itemWidth = isWide
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: children.map((child) {
            return SizedBox(width: itemWidth, child: child);
          }).toList(),
        );
      },
    );
  }

  Widget _profilePage() {
    return _panel(
      title: 'Doctor Profile',
      child: isLoadingDoctor
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isEditingProfile) ...[
                  _responsiveInfoGrid([
                    _profileInfo('Full Name', doctorName),
                    _profileInfo('Specialty', doctorSpecialty),
                    _profileInfo('Workplace', doctorWorkplace),
                    _profileInfo('Years of Experience', doctorExperience),
                    _profileInfo('Age Groups', doctorAgeGroups),
                    _profileInfo('Treats Type 1', doctorTreatsType1),
                  ]),

                  const SizedBox(height: 22),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _startEditProfile,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  _responsiveInfoGrid([
                    _editTextField(
                      label: 'Full Name',
                      controller: editFullNameController,
                      icon: Icons.person_outline_rounded,
                    ),
                    _specialtyDropdown(),
                    _editTextField(
                      label: 'Workplace',
                      controller: editWorkplaceController,
                      icon: Icons.local_hospital_outlined,
                    ),
                    _editTextField(
                      label: 'Years of Experience',
                      controller: editYearsController,
                      icon: Icons.work_history_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ]),

                  const SizedBox(height: 18),

                  const Text(
                    'Age Groups',
                    style: TextStyle(
                      color: textBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ageEditChip(
                        label: 'Children',
                        value: editAgeChildren,
                        onChanged: (v) {
                          setState(() => editAgeChildren = v);
                        },
                      ),
                      _ageEditChip(
                        label: 'Adolescents',
                        value: editAgeAdolescents,
                        onChanged: (v) {
                          setState(() => editAgeAdolescents = v);
                        },
                      ),
                      _ageEditChip(
                        label: 'Adults',
                        value: editAgeAdults,
                        onChanged: (v) {
                          setState(() => editAgeAdults = v);
                        },
                      ),
                      _ageEditChip(
                        label: 'All Ages',
                        value: editAgeAllAges,
                        onChanged: (v) {
                          setState(() => editAgeAllAges = v);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _treatsType1Dropdown(),

                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton(
                          onPressed: isSavingProfile
                              ? null
                              : () {
                                  setState(() => isEditingProfile = false);
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: red,
                            side: const BorderSide(color: red),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(t('cancel')),
                        ),
                        ElevatedButton.icon(
                          onPressed: isSavingProfile
                              ? null
                              : _saveInlineDoctorProfile,
                          icon: isSavingProfile
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(isSavingProfile ? 'Saving...' : 'Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _editTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: buttonBlue),
        filled: true,
        fillColor: const Color(0xffF9FCFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffD7EBFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffD7EBFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: mainBlue, width: 1.4),
        ),
      ),
    );
  }

  Widget _specialtyDropdown() {
    final specialties = [
      'Endocrinologist',
      'Pediatric Endocrinologist',
      'Internal Medicine',
      'General Physician',
      'Diabetes Specialist',
      'Other',
    ];

    final value = specialties.contains(editSpecialty) ? editSpecialty : 'Other';

    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Specialty',
        prefixIcon: const Icon(Icons.badge_outlined, color: buttonBlue),
        filled: true,
        fillColor: const Color(0xffF9FCFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffD7EBFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffD7EBFF)),
        ),
      ),
      items: specialties.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => editSpecialty = value);
      },
    );
  }

  Widget _treatsType1Dropdown() {
    return DropdownButtonFormField<String>(
      value: editTreatsType1,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Treats Type 1',
        prefixIcon: const Icon(Icons.monitor_heart_outlined, color: buttonBlue),
        filled: true,
        fillColor: const Color(0xffF9FCFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffD7EBFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffD7EBFF)),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Yes', child: Text('Yes')),
        DropdownMenuItem(value: 'No', child: Text('No')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => editTreatsType1 = value);
      },
    );
  }

  Widget _ageEditChip({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: value ? mainBlue : const Color(0xffF9FCFF),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: value ? mainBlue : const Color(0xffD7EBFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 18,
              color: value ? Colors.white : mainBlue,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: value ? Colors.white : textBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xffD7EBFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: textBlue,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();

    if (s.contains('low')) {
      return red;
    }

    if (s.contains('high')) {
      return orange;
    }

    if (s.contains('range') || s.contains('stable') || s.contains('normal')) {
      return green;
    }

    if (s.contains('review')) {
      return orange;
    }

    if (s.contains('urgent')) {
      return red;
    }

    return mainBlue;
  }

  Widget _fakeInput(String label, IconData icon) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xffF9FCFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffD7EBFF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: buttonBlue, size: 21),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.black45)),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black38),
        ],
      ),
    );
  }

  Widget _profileInfo(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF9FCFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffD7EBFF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: buttonBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.black45, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: textBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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
