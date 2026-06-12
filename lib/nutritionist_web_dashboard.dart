import 'dart:convert';
import 'services/appointment_reminder_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'nutritionist_patient_details_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/appointment_reminder_api.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
import 'patient_settings_screen.dart';
import 'providers/app_settings_provider.dart';

class NutritionistWebDashboard extends StatefulWidget {
  final String userId;

  const NutritionistWebDashboard({super.key, required this.userId});

  @override
  State<NutritionistWebDashboard> createState() =>
      _NutritionistWebDashboardState();
}

class _NutritionistWebDashboardState extends State<NutritionistWebDashboard> {
  int selectedIndex = 0;

  final Color primaryBlue = const Color(0xFF0D8BFF);
  final Color deepBlue = const Color(0xFF0A4FA3);

  static const Color _lightPageBg = Color(0xFFEAF6FF);
  static const Color _lightCardBg = Color(0xFFF8FCFF);
  static const Color _lightText = Color(0xFF102A43);
  static const Color _lightSubText = Color(0xFF5F7896);
  static const Color _lightBorder = Color(0xFFBFDFFF);

  static const Color _darkPageBg = Color(0xff071A2F);
  static const Color _darkCardBg = Color(0xff102A46);
  static const Color _darkTileBg = Color(0xff183A5C);
  static const Color _darkTextColor = Colors.white;
  static const Color _darkSubText = Color(0xffAFC7DD);

  bool get _isDark => context.watch<AppSettingsProvider>().darkMode;
  bool get _isArabic => context.watch<AppSettingsProvider>().language == 'ar';

  TextDirection get _pageDirection =>
      _isArabic ? TextDirection.rtl : TextDirection.ltr;

  Color get pageBg => _isDark ? _darkPageBg : _lightPageBg;
  Color get cardBg => _isDark ? _darkCardBg : _lightCardBg;
  Color get darkText => _isDark ? _darkTextColor : _lightText;
  Color get subText => _isDark ? _darkSubText : _lightSubText;
  Color get borderColor =>
      _isDark ? Colors.white.withOpacity(0.08) : _lightBorder;
  Color get tileBg => _isDark ? _darkTileBg : const Color(0xFFEAF6FF);

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'dashboard': 'Dashboard',
      'patients': 'Patients',
      'appointments': 'Appointments',
      'messages': 'Messages',
      'mealPlans': 'Meal Plans',
      'availableSlots': 'Available Slots',
      'profile': 'Profile',
      'settings': 'Settings',
      'nutritionistPanel': 'Nutritionist Panel',
      'loading': 'Loading...',
      'logout': 'Logout',
      'notifications': 'Notifications',
      'appointmentReminders': 'Appointment reminders',
      'noNotificationsYet': 'No notifications yet',
      'appointmentAlertsHere': 'Appointment alerts will appear here.',
      'markRead': 'Mark read',
    },
    'ar': {
      'dashboard': 'لوحة التحكم',
      'patients': 'المرضى',
      'appointments': 'المواعيد',
      'messages': 'الرسائل',
      'mealPlans': 'خطط الوجبات',
      'availableSlots': 'الأوقات المتاحة',
      'profile': 'الملف الشخصي',
      'settings': 'الإعدادات',
      'nutritionistPanel': 'لوحة أخصائي التغذية',
      'loading': 'جاري التحميل...',
      'logout': 'تسجيل الخروج',
      'notifications': 'الإشعارات',
      'appointmentReminders': 'تذكيرات المواعيد',
      'noNotificationsYet': 'لا توجد إشعارات بعد',
      'appointmentAlertsHere': 'ستظهر تنبيهات المواعيد هنا.',
      'markRead': 'تحديد كمقروء',
    },
  };

  String t(String key) {
    final lang = context.read<AppSettingsProvider>().language;
    return _strings[lang]?[key] ?? _strings['en']?[key] ?? key;
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientSettingsScreen(userId: widget.userId),
      ),
    );
  }

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController workplaceController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();

  bool isLoadingDashboard = false;

  List<dynamic> dashboardTodayAppointments = [];
  List<dynamic> dashboardPatientAlerts = [];
  List<dynamic> dashboardRecentActivities = [];
  List<dynamic> dashboardMealPlansReview = [];

  int dashboardActivePatientsCount = 0;
  int dashboardUnreadMessagesCount = 0;
  int dashboardPendingMealPlansCount = 0;

  String? selectedMealPlanPatientId;

  DateTime? mealPlanStartDate;
  DateTime? mealPlanEndDate;

  bool isSavingMealPlan = false;
  bool isLoadingMealPlans = false;

  List<dynamic> assignedMealPlans = [];

  final TextEditingController planTitleController = TextEditingController();
  final TextEditingController clinicalGoalController = TextEditingController();

  final TextEditingController fastingTargetController = TextEditingController(
    text: '80–130',
  );
  final TextEditingController postMealTargetController = TextEditingController(
    text: '< 180',
  );
  final TextEditingController hba1cTargetController = TextEditingController(
    text: '< 7.0',
  );

  final TextEditingController breakfastFoodController = TextEditingController();
  final TextEditingController breakfastCalController = TextEditingController();
  final TextEditingController breakfastCarbsController =
      TextEditingController();
  final TextEditingController breakfastProController = TextEditingController();
  final TextEditingController breakfastFatController = TextEditingController();
  final TextEditingController breakfastNotesController =
      TextEditingController();

  final TextEditingController lunchFoodController = TextEditingController();
  final TextEditingController lunchCalController = TextEditingController();
  final TextEditingController lunchCarbsController = TextEditingController();
  final TextEditingController lunchProController = TextEditingController();
  final TextEditingController lunchFatController = TextEditingController();
  final TextEditingController lunchNotesController = TextEditingController();

  final TextEditingController dinnerFoodController = TextEditingController();
  final TextEditingController dinnerCalController = TextEditingController();
  final TextEditingController dinnerCarbsController = TextEditingController();
  final TextEditingController dinnerProController = TextEditingController();
  final TextEditingController dinnerFatController = TextEditingController();
  final TextEditingController dinnerNotesController = TextEditingController();

  final TextEditingController snackFoodController = TextEditingController();
  final TextEditingController snackCalController = TextEditingController();
  final TextEditingController snackCarbsController = TextEditingController();
  final TextEditingController snackProController = TextEditingController();
  final TextEditingController snackFatController = TextEditingController();
  final TextEditingController snackNotesController = TextEditingController();
  Timer? _appointmentWatcherTimer;

  final List<Map<String, dynamic>> _nutritionistNotifications = [];
  final Set<String> _shownAppointmentAlerts = {};
  bool isUpdatingProfile = false;

  bool isLoadingProfile = true;
  bool isLoadingAppointments = false;
  List<dynamic> appointments = [];

  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';
  String workplace = '';
  String specialty = '';
  String yearsOfExperience = '';
  String selectedAppointmentFilter = 'all';
  bool isLoadingConversations = false;
  bool isLoadingMessages = false;

  List<dynamic> conversations = [];
  List<dynamic> chatMessages = [];

  Map<String, dynamic>? selectedConversationUser;

  final TextEditingController messageController = TextEditingController();
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    return 'http://10.0.2.2:5000';
  }

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : 'Nutritionist';
  }

  String get initials {
    final first = firstName.trim().isNotEmpty
        ? firstName.trim()[0].toUpperCase()
        : '';
    final last = lastName.trim().isNotEmpty
        ? lastName.trim()[0].toUpperCase()
        : '';

    final result = '$first$last';
    return result.isNotEmpty ? result : 'N';
  }

  String? editingMealPlanId;
  bool get isEditingMealPlan => editingMealPlanId != null;

  String getUserName(dynamic user) {
    if (user is Map<String, dynamic>) {
      final firstName = user['firstName']?.toString() ?? '';
      final lastName = user['lastName']?.toString() ?? '';
      final email = user['email']?.toString() ?? '';

      final name = '$firstName $lastName'.trim();

      if (name.isNotEmpty) return name;
      if (email.isNotEmpty) return email;
    }

    return 'Unknown User';
  }

  String getUserInitials(dynamic user) {
    if (user is Map<String, dynamic>) {
      final firstName = user['firstName']?.toString() ?? '';
      final lastName = user['lastName']?.toString() ?? '';

      final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
      final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';

      final result = '$first$last';
      return result.isNotEmpty ? result : 'U';
    }

    return 'U';
  }

  List<String> get menuItems => [
    t('dashboard'),
    t('patients'),
    t('appointments'),
    t('messages'),
    t('mealPlans'),
    t('availableSlots'),
    t('profile'),
  ];
  List<dynamic> get filteredAppointments {
    if (selectedAppointmentFilter == 'all') {
      return appointments;
    }

    return appointments.where((appointment) {
      final visitType =
          appointment['visitType']?.toString().toLowerCase() ?? '';
      return visitType == selectedAppointmentFilter;
    }).toList();
  }

  final List<IconData> menuIcons = [
    Icons.grid_view_rounded,
    Icons.people_alt_rounded,
    Icons.calendar_month_rounded,
    Icons.chat_bubble_outline_rounded,
    Icons.restaurant_menu_rounded,
    Icons.event_available_rounded,
    Icons.person_outline_rounded,
  ];
  String getPatientNameFromUser(dynamic patient) {
    if (patient is Map<String, dynamic>) {
      final firstName = patient['firstName']?.toString() ?? '';
      final lastName = patient['lastName']?.toString() ?? '';
      final email = patient['email']?.toString() ?? '';

      final name = '$firstName $lastName'.trim();

      if (name.isNotEmpty) return name;
      if (email.isNotEmpty) return email;
    }

    return 'Unknown Patient';
  }

  void editMealPlan(dynamic plan) {
    final patient = plan['patientId'];
    final meals = plan['meals'] ?? {};
    final glucoseTargets = plan['glucoseTargets'] ?? {};

    setState(() {
      editingMealPlanId = plan['_id']?.toString();

      if (patient is Map<String, dynamic>) {
        selectedMealPlanPatientId = patient['_id']?.toString();
      } else {
        selectedMealPlanPatientId = patient?.toString();
      }

      planTitleController.text = plan['planTitle']?.toString() ?? '';
      clinicalGoalController.text = plan['clinicalGoal']?.toString() ?? '';

      mealPlanStartDate = DateTime.tryParse(
        plan['startDate']?.toString() ?? '',
      );
      mealPlanEndDate = DateTime.tryParse(plan['endDate']?.toString() ?? '');

      fastingTargetController.text =
          glucoseTargets['fasting']?.toString() ?? '80–130';
      postMealTargetController.text =
          glucoseTargets['postMeal']?.toString() ?? '< 180';
      hba1cTargetController.text =
          glucoseTargets['hba1cTarget']?.toString() ?? '< 7.0';

      _fillMealControllers(
        meals['breakfast'],
        breakfastFoodController,
        breakfastCarbsController,
        breakfastCalController,
        breakfastProController,
        breakfastFatController,
        breakfastNotesController,
      );

      _fillMealControllers(
        meals['lunch'],
        lunchFoodController,
        lunchCarbsController,
        lunchCalController,
        lunchProController,
        lunchFatController,
        lunchNotesController,
      );

      _fillMealControllers(
        meals['dinner'],
        dinnerFoodController,
        dinnerCarbsController,
        dinnerCalController,
        dinnerProController,
        dinnerFatController,
        dinnerNotesController,
      );

      _fillMealControllers(
        meals['snack'],
        snackFoodController,
        snackCarbsController,
        snackCalController,
        snackProController,
        snackFatController,
        snackNotesController,
      );
    });
  }

  void _fillMealControllers(
    dynamic meal,
    TextEditingController food,
    TextEditingController carbs,
    TextEditingController calories,
    TextEditingController protein,
    TextEditingController fat,
    TextEditingController notes,
  ) {
    if (meal is! Map<String, dynamic>) return;

    food.text = meal['foodItems']?.toString() ?? '';
    carbs.text = meal['carbs']?.toString() ?? '';
    calories.text = meal['calories']?.toString() ?? '';
    protein.text = meal['protein']?.toString() ?? '';
    fat.text = meal['fat']?.toString() ?? '';
    notes.text = meal['notes']?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();
    fetchNutritionistProfile();
    fetchNutritionistAppointments();
    fetchConversations();
    fetchNutritionistMealPlans();
    fetchNutritionistDashboard();
    _scheduleNutritionistAppointmentReminders();
    _startNutritionistAppointmentWatcher();
    fetchSavedAvailabilities();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    workplaceController.dispose();
    specialtyController.dispose();
    experienceController.dispose();

    planTitleController.dispose();
    clinicalGoalController.dispose();
    fastingTargetController.dispose();
    postMealTargetController.dispose();
    hba1cTargetController.dispose();

    breakfastFoodController.dispose();
    breakfastCalController.dispose();
    breakfastCarbsController.dispose();
    breakfastProController.dispose();
    breakfastFatController.dispose();
    breakfastNotesController.dispose();

    lunchFoodController.dispose();
    lunchCalController.dispose();
    lunchCarbsController.dispose();
    lunchProController.dispose();
    lunchFatController.dispose();
    lunchNotesController.dispose();

    dinnerFoodController.dispose();
    dinnerCalController.dispose();
    dinnerCarbsController.dispose();
    dinnerProController.dispose();
    dinnerFatController.dispose();
    dinnerNotesController.dispose();

    snackFoodController.dispose();
    snackCalController.dispose();
    snackCarbsController.dispose();
    snackProController.dispose();
    snackFatController.dispose();
    snackNotesController.dispose();
    messageController.dispose();
    _appointmentWatcherTimer?.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('userId');
    await prefs.remove('role');

    _appointmentWatcherTimer?.cancel();
    AppointmentReminderService.cancelAll();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  Future<void> pickMealPlanDate({required bool isStartDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    setState(() {
      if (isStartDate) {
        mealPlanStartDate = picked;
      } else {
        mealPlanEndDate = picked;
      }
    });
  }

  String formatMealPlanDate(DateTime? date) {
    if (date == null) return 'mm/dd/yyyy';

    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> fetchNutritionistMealPlans() async {
    try {
      setState(() {
        isLoadingMealPlans = true;
      });

      final url = Uri.parse(
        '$baseUrl/api/nutritionist-meal-plans/nutritionist/${widget.userId}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          assignedMealPlans = data['plans'] ?? [];
          isLoadingMealPlans = false;
        });
      } else {
        debugPrint('Failed to fetch meal plans: ${response.body}');
        setState(() {
          isLoadingMealPlans = false;
        });
      }
    } catch (e) {
      debugPrint('Meal plans error: $e');
      setState(() {
        isLoadingMealPlans = false;
      });
    }
  }

  double _toDouble(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  Future<void> saveMealPlan() async {
    if (selectedMealPlanPatientId == null ||
        selectedMealPlanPatientId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a patient')));
      return;
    }

    if (planTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter plan title')));
      return;
    }

    if (mealPlanStartDate == null || mealPlanEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    try {
      setState(() {
        isSavingMealPlan = true;
      });

      final url = isEditingMealPlan
          ? Uri.parse('$baseUrl/api/nutritionist-meal-plans/$editingMealPlanId')
          : Uri.parse('$baseUrl/api/nutritionist-meal-plans');

      final body = {
        'nutritionistId': widget.userId,
        'patientId': selectedMealPlanPatientId,
        'planTitle': planTitleController.text.trim(),
        'clinicalGoal': clinicalGoalController.text.trim(),
        'startDate': mealPlanStartDate!.toIso8601String(),
        'endDate': mealPlanEndDate!.toIso8601String(),
        'glucoseTargets': {
          'fasting': fastingTargetController.text.trim(),
          'postMeal': postMealTargetController.text.trim(),
          'hba1cTarget': hba1cTargetController.text.trim(),
        },
        'meals': {
          'breakfast': {
            'foodItems': breakfastFoodController.text.trim(),
            'calories': _toDouble(breakfastCalController),
            'carbs': _toDouble(breakfastCarbsController),
            'protein': _toDouble(breakfastProController),
            'fat': _toDouble(breakfastFatController),
            'notes': breakfastNotesController.text.trim(),
          },
          'lunch': {
            'foodItems': lunchFoodController.text.trim(),
            'calories': _toDouble(lunchCalController),
            'carbs': _toDouble(lunchCarbsController),
            'protein': _toDouble(lunchProController),
            'fat': _toDouble(lunchFatController),
            'notes': lunchNotesController.text.trim(),
          },
          'dinner': {
            'foodItems': dinnerFoodController.text.trim(),
            'calories': _toDouble(dinnerCalController),
            'carbs': _toDouble(dinnerCarbsController),
            'protein': _toDouble(dinnerProController),
            'fat': _toDouble(dinnerFatController),
            'notes': dinnerNotesController.text.trim(),
          },
          'snack': {
            'foodItems': snackFoodController.text.trim(),
            'calories': _toDouble(snackCalController),
            'carbs': _toDouble(snackCarbsController),
            'protein': _toDouble(snackProController),
            'fat': _toDouble(snackFatController),
            'notes': snackNotesController.text.trim(),
          },
        },
        'dailyTotals': {
          'calories': totalCalories,
          'carbs': totalCarbs,
          'protein': totalProtein,
          'fat': totalFat,
        },
      };
      debugPrint('MEAL PLAN BODY: ${jsonEncode(body)}');
      final response = isEditingMealPlan
          ? await http.put(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
          : await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final successMessage = isEditingMealPlan
            ? 'Meal plan updated successfully'
            : 'Meal plan saved successfully';

        clearMealPlanForm();
        await fetchNutritionistMealPlans();

        setState(() {
          isSavingMealPlan = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      } else {
        debugPrint('Save meal plan failed: ${response.body}');

        setState(() {
          isSavingMealPlan = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save meal plan')),
        );
      }
    } catch (e) {
      debugPrint('Save meal plan error: $e');

      setState(() {
        isSavingMealPlan = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error while saving meal plan')),
      );
    }
  }

  double get totalCalories {
    return _toDouble(breakfastCalController) +
        _toDouble(lunchCalController) +
        _toDouble(dinnerCalController) +
        _toDouble(snackCalController);
  }

  double get totalProtein {
    return _toDouble(breakfastProController) +
        _toDouble(lunchProController) +
        _toDouble(dinnerProController) +
        _toDouble(snackProController);
  }

  double get totalFat {
    return _toDouble(breakfastFatController) +
        _toDouble(lunchFatController) +
        _toDouble(dinnerFatController) +
        _toDouble(snackFatController);
  }

  double get totalCarbs {
    return _toDouble(breakfastCarbsController) +
        _toDouble(lunchCarbsController) +
        _toDouble(dinnerCarbsController) +
        _toDouble(snackCarbsController);
  }

  List<Map<String, String>> get dashboardActivities {
    final activities = <Map<String, String>>[];

    for (final appointment in appointments.take(3)) {
      activities.add({
        'title':
            '${_getPatientName(appointment)} booked ${appointment['visitType'] ?? 'visit'} appointment',
        'time': appointment['createdAt'] != null
            ? _timeAgo(appointment['createdAt'].toString())
            : '',
      });
    }

    for (final plan in assignedMealPlans.take(3)) {
      final patientName = getPatientNameFromUser(plan['patientId']);
      final planTitle = plan['planTitle']?.toString() ?? 'Meal Plan';

      activities.add({
        'title': '$patientName assigned: $planTitle',
        'time': plan['createdAt'] != null
            ? _timeAgo(plan['createdAt'].toString())
            : '',
      });
    }

    for (final conversation in conversations.take(2)) {
      final user = conversation['user'];
      final name = getUserName(user);

      activities.add({
        'title': '$name sent a message',
        'time': conversation['createdAt'] != null
            ? _timeAgo(conversation['createdAt'].toString())
            : '',
      });
    }

    return activities.take(5).toList();
  }

  String _timeAgo(String dateText) {
    final date = DateTime.tryParse(dateText);
    if (date == null) return '';

    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  void clearMealPlanForm() {
    selectedMealPlanPatientId = null;
    mealPlanStartDate = null;
    mealPlanEndDate = null;
    editingMealPlanId = null;

    planTitleController.clear();
    clinicalGoalController.clear();

    fastingTargetController.text = '80–130';
    postMealTargetController.text = '< 180';
    hba1cTargetController.text = '< 7.0';

    breakfastFoodController.clear();
    breakfastCalController.clear();
    breakfastCarbsController.clear();
    breakfastProController.clear();
    breakfastFatController.clear();
    breakfastNotesController.clear();

    lunchFoodController.clear();
    lunchCalController.clear();
    lunchCarbsController.clear();
    lunchProController.clear();
    lunchFatController.clear();
    lunchNotesController.clear();

    dinnerFoodController.clear();
    dinnerCalController.clear();
    dinnerCarbsController.clear();
    dinnerProController.clear();
    dinnerFatController.clear();
    dinnerNotesController.clear();

    snackFoodController.clear();
    snackCalController.clear();
    snackCarbsController.clear();
    snackProController.clear();
    snackFatController.clear();
    snackNotesController.clear();
  }

  Future<void> fetchNutritionistProfile() async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/nutritionist/profile/${widget.userId}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final user = data['user'] ?? {};
        final profile = data['profile'] ?? {};

        setState(() {
          firstName = user['firstName'] ?? '';
          lastName = user['lastName'] ?? '';
          email = user['email'] ?? '';

          phone = profile['phone']?.toString() ?? '';
          workplace = profile['workplace']?.toString() ?? '';
          specialty = profile['specialty']?.toString() ?? '';
          yearsOfExperience = profile['yearsOfExperience']?.toString() ?? '';

          isLoadingProfile = false;
        });
      } else {
        debugPrint('Failed to fetch profile: ${response.body}');
        setState(() {
          isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching nutritionist profile: $e');
      setState(() {
        isLoadingProfile = false;
      });
    }
  }

  int get _nutritionistUnreadNotificationsCount {
    return _nutritionistNotifications
        .where((notification) => notification['isRead'] != true)
        .length;
  }

  void _startNutritionistAppointmentWatcher() {
    _appointmentWatcherTimer?.cancel();

    _appointmentWatcherTimer = Timer.periodic(const Duration(seconds: 20), (
      _,
    ) async {
      if (appointments.isEmpty) {
        await fetchNutritionistAppointments();
      }

      _checkNutritionistAppointmentsNow();
    });

    Future.delayed(const Duration(seconds: 2), () {
      _checkNutritionistAppointmentsNow();
    });
  }

  void _checkNutritionistAppointmentsNow() {
    final now = DateTime.now();

    for (final appointment in appointments) {
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
          _nutritionistNotifications.insert(0, {
            'id': reminderKey,
            'title': 'Appointment reminder',
            'body':
                'Your nutrition appointment with $patientName starts in 5 minutes.',
            'time': _formatNotificationTime(DateTime.now()),
            'isRead': false,
            'kind': 'reminder',
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nutrition appointment with $patientName starts in 5 minutes.',
            ),
            action: SnackBarAction(
              label: 'View',
              onPressed: _showNutritionistNotificationsPanel,
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
          _nutritionistNotifications.insert(0, {
            'id': nowKey,
            'title': 'Appointment now',
            'body': 'You have a nutrition appointment with $patientName now.',
            'time': _formatNotificationTime(DateTime.now()),
            'isRead': false,
            'kind': 'now',
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nutrition appointment with $patientName is starting now.',
            ),
            action: SnackBarAction(
              label: 'View',
              onPressed: _showNutritionistNotificationsPanel,
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

  void _showNutritionistNotificationsPanel() {
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
                    decoration: BoxDecoration(
                      color: deepBlue,
                      borderRadius: const BorderRadius.only(
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('notifications'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                t('appointmentReminders'),
                                style: const TextStyle(
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
                    child: _nutritionistNotifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: pageBg,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Icon(
                                    Icons.notifications_none_rounded,
                                    color: deepBlue,
                                    size: 38,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No notifications yet',
                                  style: TextStyle(
                                    color: darkText,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  t('appointmentAlertsHere'),
                                  style: const TextStyle(
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
                                itemCount: _nutritionistNotifications.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final notification =
                                      _nutritionistNotifications[index];

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
                                            : deepBlue.withOpacity(0.45),
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
                                                ? Colors.orange
                                                : deepBlue,
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
                                                        color: darkText,
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
                                                            color: Colors.red,
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
                                                          _nutritionistNotifications[index]['isRead'] =
                                                              true;
                                                        });

                                                        setModalState(() {});
                                                      },
                                                      child: Text(
                                                        t('markRead'),
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

  Future<void> fetchConversations() async {
    try {
      setState(() {
        isLoadingConversations = true;
      });

      final url = Uri.parse(
        '$baseUrl/api/messages/conversations/${widget.userId}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          conversations = data['conversations'] ?? [];
          isLoadingConversations = false;
        });
      } else {
        debugPrint('Failed to fetch conversations: ${response.body}');
        setState(() {
          isLoadingConversations = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      setState(() {
        isLoadingConversations = false;
      });
    }
  }

  Future<void> fetchChatMessages(String otherUserId) async {
    try {
      setState(() {
        isLoadingMessages = true;
      });

      final url = Uri.parse(
        '$baseUrl/api/messages/${widget.userId}/$otherUserId',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          chatMessages = data;
          isLoadingMessages = false;
        });

        await markConversationAsRead(otherUserId);
      } else {
        debugPrint('Failed to fetch messages: ${response.body}');
        setState(() {
          isLoadingMessages = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      setState(() {
        isLoadingMessages = false;
      });
    }
  }

  Future<void> markConversationAsRead(String otherUserId) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/messages/read/${widget.userId}/$otherUserId',
      );

      final response = await http.put(url);

      if (response.statusCode == 200) {
        await fetchNutritionistDashboard();
      } else {
        debugPrint('Failed to mark messages as read: ${response.body}');
      }
    } catch (e) {
      debugPrint('Mark messages as read error: $e');
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty || selectedConversationUser == null) return;

    final receiverId = selectedConversationUser!['_id'].toString();

    try {
      final url = Uri.parse('$baseUrl/api/messages');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': widget.userId,
          'receiverId': receiverId,
          'message': text,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        messageController.clear();

        await fetchChatMessages(receiverId);
        await fetchConversations();
      } else {
        debugPrint('Failed to send message: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> _openMeetingLink(String meetingLink) async {
    if (meetingLink.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No meeting link available')),
      );
      return;
    }

    final uri = Uri.parse(meetingLink.trim());

    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot open meeting link')));
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _scheduleNutritionistAppointmentReminders() async {
    try {
      final appointments =
          await AppointmentReminderApi.getNutritionistAppointments(
            widget.userId,
          );

      for (final appointment in appointments) {
        final patient = appointment['patientId'];

        final patientName = patient is Map
            ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'
                  .trim()
            : 'a patient';

        AppointmentReminderService.scheduleAppointment(
          id: 'nutritionist-${appointment['_id']}',
          userId: widget.userId,
          day: appointment['day']?.toString() ?? '',
          time: appointment['time']?.toString() ?? '',
          title: 'Patient appointment now',
          body: 'Your appointment with $patientName is starting now.',
          type: 'nutritionist_appointment',
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule nutritionist appointment reminders: $e');
    }
  }

  Future<void> fetchNutritionistAppointments() async {
    try {
      setState(() {
        isLoadingAppointments = true;
      });

      final url = Uri.parse(
        '$baseUrl/api/nutritionist-appointments/nutritionist/${widget.userId}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          appointments = data['appointments'] ?? [];
          isLoadingAppointments = false;
        });
      } else {
        debugPrint('Failed to fetch appointments: ${response.body}');
        setState(() {
          appointments = [];
          isLoadingAppointments = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching nutritionist appointments: $e');
      setState(() {
        appointments = [];
        isLoadingAppointments = false;
      });
    }
  }

  List<dynamic> savedAvailabilities = [];
  bool isLoadingAvailabilities = false;
  String? editingAvailabilityId;
  String activeSlotDay = 'Sunday';

  Set<String> selectedSlotDays = {'Sunday'};

  Map<String, Set<String>> selectedSlotsByDay = {'Sunday': <String>{}};

  String selectedVisitType = 'online';
  int get unreadMessagesCount {
    return conversations.where((conversation) {
      final unread = conversation['unreadCount'];
      if (unread is int) return unread > 0;
      if (unread is num) return unread > 0;
      return false;
    }).length;
  }

  int get pendingMealPlansCount {
    return assignedMealPlans.where((plan) {
      final status = plan['status']?.toString().toLowerCase() ?? '';
      return status == 'review';
    }).length;
  }

  final List<String> weekDays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  final List<String> morningSlots = [
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
  ];

  final List<String> eveningSlots = [
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
  ];

  bool isSavingSlots = false;

  int get totalSelectedSlotsCount {
    int total = 0;

    for (final slots in selectedSlotsByDay.values) {
      total += slots.length;
    }

    return total;
  }

  String _getPatientName(dynamic appointment) {
    final patient = appointment['patientId'];

    if (patient is Map<String, dynamic>) {
      final first = patient['firstName']?.toString() ?? '';
      final last = patient['lastName']?.toString() ?? '';
      final name = '$first $last'.trim();

      if (name.isNotEmpty) return name;
      return patient['email']?.toString() ?? 'Unknown Patient';
    }

    return 'Unknown Patient';
  }

  String _todayName() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  List<dynamic> get bookedAppointments {
    return appointments.where((appointment) {
      final status = appointment['status']?.toString().toLowerCase() ?? '';
      return status == 'booked';
    }).toList();
  }

  List<dynamic> get bookedPatients {
    final Map<String, dynamic> uniquePatients = {};

    for (final appointment in appointments) {
      final patient = appointment['patientId'];

      if (patient is Map<String, dynamic>) {
        final patientId = patient['_id']?.toString();

        if (patientId != null && patientId.isNotEmpty) {
          uniquePatients[patientId] = patient;
        }
      }
    }

    return uniquePatients.values.toList();
  }

  List<dynamic> get todayAppointments {
    final today = _todayName().toLowerCase();

    return bookedAppointments.where((appointment) {
      final day = appointment['day']?.toString().toLowerCase() ?? '';
      return day == today;
    }).toList();
  }

  int get activePatientsCount {
    final ids = <String>{};

    for (final appointment in bookedAppointments) {
      final patient = appointment['patientId'];

      if (patient is Map<String, dynamic>) {
        final id = patient['_id']?.toString();
        if (id != null && id.isNotEmpty) ids.add(id);
      } else if (patient != null) {
        ids.add(patient.toString());
      }
    }

    return ids.length;
  }

  void openEditProfileDialog() {
    firstNameController.text = firstName;
    lastNameController.text = lastName;
    phoneController.text = phone;
    workplaceController.text = workplace;
    specialtyController.text = specialty;
    experienceController.text = yearsOfExperience;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF8FCFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(color: darkText, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildEditTextField('First Name', firstNameController),
                  const SizedBox(height: 12),
                  _buildEditTextField('Last Name', lastNameController),
                  const SizedBox(height: 12),
                  _buildEditTextField('Phone', phoneController),
                  const SizedBox(height: 12),
                  _buildEditTextField('Workplace', workplaceController),
                  const SizedBox(height: 12),
                  _buildEditTextField('Specialty', specialtyController),
                  const SizedBox(height: 12),
                  _buildEditTextField(
                    'Years of Experience',
                    experienceController,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUpdatingProfile
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              child: Text('Cancel', style: TextStyle(color: subText)),
            ),
            ElevatedButton(
              onPressed: isUpdatingProfile ? null : updateNutritionistProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: deepBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isUpdatingProfile
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailableSlotsPage() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Available Slots',
              style: TextStyle(
                color: darkText,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose the days and times that patients can book.',
              style: TextStyle(
                color: subText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 26),

            Row(
              children: [
                _buildVisitTypeButton(
                  'Online',
                  'online',
                  Icons.videocam_rounded,
                ),
                const SizedBox(width: 12),
                _buildVisitTypeButton(
                  'Clinic',
                  'clinic',
                  Icons.local_hospital_rounded,
                ),
              ],
            ),

            const SizedBox(height: 28),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Week Days',
                style: TextStyle(
                  color: deepBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: weekDays.map((day) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _buildDayCard(day),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Morning',
                    style: TextStyle(
                      color: deepBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.wb_sunny_outlined, color: primaryBlue, size: 18),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _buildSlotsGrid(morningSlots),

            const SizedBox(height: 28),

            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Evening',
                    style: TextStyle(
                      color: deepBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.nightlight_round, color: primaryBlue, size: 18),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _buildSlotsGrid(eveningSlots),

            const SizedBox(height: 26),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFDFF1FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: deepBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalSelectedSlotsCount slots',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Saved Slots',
                    style: TextStyle(
                      color: deepBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: deepBlue,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$activeSlotDay - ${(selectedSlotsByDay[activeSlotDay] ?? {}).length} times',
                          style: TextStyle(
                            color: deepBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),
            const SizedBox(height: 18),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Saved Schedules',
                style: TextStyle(
                  color: darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 12),

            _buildSavedAvailabilitiesList(),

            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: isSavingSlots ? null : saveAvailableSlots,
                icon: Icon(Icons.save_rounded, color: deepBlue),
                label: Text(
                  isSavingSlots ? 'Saving...' : 'Save Schedule',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: borderColor),
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

  Widget _buildVisitTypeButton(String text, String value, IconData icon) {
    final selected = selectedVisitType == value;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          selectedVisitType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? deepBlue : const Color(0xFFEAF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? deepBlue : borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : deepBlue, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : darkText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(String day) {
    final bool isSelected = selectedSlotDays.contains(day);
    final bool isActive = activeSlotDay == day;

    final dayNumber =
        {
          'Sunday': '17',
          'Monday': '18',
          'Tuesday': '19',
          'Wednesday': '20',
          'Thursday': '21',
          'Friday': '22',
          'Saturday': '23',
        }[day] ??
        '';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          activeSlotDay = day;
          selectedSlotDays.add(day);
          selectedSlotsByDay.putIfAbsent(day, () => <String>{});
        });
      },
      onLongPress: () {
        setState(() {
          if (selectedSlotDays.length == 1 && selectedSlotDays.contains(day)) {
            selectedSlotsByDay[day]?.clear();
            return;
          }

          selectedSlotDays.remove(day);
          selectedSlotsByDay.remove(day);

          if (activeSlotDay == day && selectedSlotDays.isNotEmpty) {
            activeSlotDay = selectedSlotDays.first;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive
              ? deepBlue
              : isSelected
              ? const Color(0xFFDFF1FF)
              : const Color(0xFFF2FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? deepBlue
                : isSelected
                ? primaryBlue
                : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                left: 8,
                top: 0,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 17,
                  color: isActive ? Colors.white : primaryBlue,
                ),
              ),
            Center(
              child: Column(
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      color: isActive ? Colors.white70 : subText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayNumber,
                    style: TextStyle(
                      color: isActive ? Colors.white : deepBlue,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
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

  Widget _buildSlotsGrid(List<String> slots) {
    final currentDaySlots = selectedSlotsByDay[activeSlotDay] ?? <String>{};

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 4,
      ),
      itemBuilder: (context, index) {
        final slot = slots[index];
        final selected = currentDaySlots.contains(slot);

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              selectedSlotDays.add(activeSlotDay);
              selectedSlotsByDay.putIfAbsent(activeSlotDay, () => <String>{});

              if (selected) {
                selectedSlotsByDay[activeSlotDay]!.remove(slot);
              } else {
                selectedSlotsByDay[activeSlotDay]!.add(slot);
              }
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? deepBlue : const Color(0xFFF2FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? deepBlue : borderColor),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    slot,
                    style: TextStyle(
                      color: selected ? Colors.white : deepBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected)
                  const Positioned(
                    left: 8,
                    top: 6,
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> fetchSavedAvailabilities() async {
    try {
      setState(() {
        isLoadingAvailabilities = true;
      });

      final url = Uri.parse(
        '$baseUrl/api/nutritionist-availabilities/nutritionist/${widget.userId}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          savedAvailabilities = data['availabilities'] ?? [];
          isLoadingAvailabilities = false;
        });
      } else {
        debugPrint('Failed to fetch availabilities: ${response.body}');
        setState(() {
          isLoadingAvailabilities = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch availabilities error: $e');
      setState(() {
        isLoadingAvailabilities = false;
      });
    }
  }

  void editAvailability(dynamic availability) {
    final id = availability['_id']?.toString();
    final day = availability['day']?.toString() ?? 'Sunday';
    final visitType = availability['visitType']?.toString() ?? 'online';
    final slots = availability['slots'];

    setState(() {
      editingAvailabilityId = id;
      activeSlotDay = day;
      selectedVisitType = visitType;

      selectedSlotDays = {day};

      selectedSlotsByDay = {
        day: slots is List
            ? slots.map((e) => e.toString()).toSet()
            : <String>{},
      };
    });
  }

  Future<void> deleteAvailability(String availabilityId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF8FCFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Delete Schedule',
            style: TextStyle(color: darkText, fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Are you sure you want to delete this saved schedule?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: subText)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: deepBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final url = Uri.parse(
        '$baseUrl/api/nutritionist-availabilities/$availabilityId',
      );

      final response = await http.delete(url);

      if (response.statusCode == 200) {
        await fetchSavedAvailabilities();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule deleted successfully')),
        );
      } else {
        debugPrint('Delete availability failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete schedule')),
        );
      }
    } catch (e) {
      debugPrint('Delete availability error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error while deleting schedule')),
      );
    }
  }

  Future<void> saveAvailableSlots() async {
    final schedules = selectedSlotDays
        .map((day) {
          final slots = (selectedSlotsByDay[day] ?? <String>{}).toList()
            ..sort();

          return {'day': day, 'visitType': selectedVisitType, 'slots': slots};
        })
        .where((item) {
          final slots = item['slots'] as List<String>;
          return slots.isNotEmpty;
        })
        .toList();

    if (schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one slot')),
      );
      return;
    }

    try {
      setState(() {
        isSavingSlots = true;
      });

      final url = Uri.parse('$baseUrl/api/nutritionist-availabilities/bulk');

      final body = {'nutritionistId': widget.userId, 'schedules': schedules};

      debugPrint('SLOTS BODY: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      setState(() {
        isSavingSlots = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        editingAvailabilityId = null;

        await fetchSavedAvailabilities();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule saved successfully')),
        );
      } else {
        debugPrint('Save slots failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save schedule')),
        );
      }
    } catch (e) {
      setState(() {
        isSavingSlots = false;
      });

      debugPrint('Save slots error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error while saving schedule')),
      );
    }
  }

  Widget _buildEditTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFEAF6FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryBlue, width: 1.4),
        ),
      ),
    );
  }

  Future<void> fetchNutritionistDashboard() async {
    try {
      setState(() {
        isLoadingDashboard = true;
      });

      final url = Uri.parse(
        '$baseUrl/api/nutritionist-dashboard/${widget.userId}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          dashboardTodayAppointments = data['todayAppointments'] ?? [];
          dashboardPatientAlerts = data['patientAlerts'] ?? [];
          dashboardRecentActivities = data['recentActivities'] ?? [];
          dashboardMealPlansReview = data['mealPlansReview'] ?? [];

          dashboardActivePatientsCount = data['activePatientsCount'] ?? 0;
          dashboardUnreadMessagesCount = data['unreadMessagesCount'] ?? 0;
          dashboardPendingMealPlansCount = data['pendingMealPlansCount'] ?? 0;

          isLoadingDashboard = false;
        });
      } else {
        debugPrint('Failed dashboard: ${response.body}');
        setState(() {
          isLoadingDashboard = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard error: $e');
      setState(() {
        isLoadingDashboard = false;
      });
    }
  }

  Future<void> updateNutritionistProfile() async {
    try {
      setState(() {
        isUpdatingProfile = true;
      });

      final url = Uri.parse(
        '$baseUrl/api/nutritionist/profile/${widget.userId}',
      );

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'workplace': workplaceController.text.trim(),
          'specialty': specialtyController.text.trim(),
          'yearsOfExperience':
              int.tryParse(experienceController.text.trim()) ?? 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final user = data['user'] ?? {};
        final profile = data['profile'] ?? {};

        setState(() {
          firstName = user['firstName'] ?? '';
          lastName = user['lastName'] ?? '';

          phone = profile['phone']?.toString() ?? '';
          workplace = profile['workplace']?.toString() ?? '';
          specialty = profile['specialty']?.toString() ?? '';
          yearsOfExperience = profile['yearsOfExperience']?.toString() ?? '';

          isUpdatingProfile = false;
        });

        if (mounted) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } else {
        setState(() {
          isUpdatingProfile = false;
        });

        debugPrint('Failed to update profile: ${response.body}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      setState(() {
        isUpdatingProfile = false;
      });

      debugPrint('Error updating profile: $e');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error updating profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppSettingsProvider>();

    return Directionality(
      textDirection: _pageDirection,
      child: Scaffold(
        backgroundColor: pageBg,
        body: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: Container(
                color: pageBg,
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1500),
                      child: Column(
                        children: [
                          _buildTopBar(),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                20,
                                24,
                                24,
                              ),
                              child: _buildSelectedPage(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 230,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF073B7A), Color(0xFF0A5FC7), Color(0xFF1689F5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(3, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 26),
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: isLoadingProfile
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      initials,
                      style: const TextStyle(
                        color: Color(0xFF0A4FA3),
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            t('nutritionistPanel'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              isLoadingProfile ? t('loading') : fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 26),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: menuItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                    if (index == 0) {
                      fetchNutritionistDashboard();
                    }
                    if (index == 2) {
                      fetchNutritionistAppointments();
                    }

                    if (index == 3) {
                      fetchConversations();
                    }

                    if (index == 4) {
                      fetchNutritionistAppointments();
                      fetchNutritionistMealPlans();
                    }
                    if (index == 5) {
                      fetchSavedAvailabilities();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          menuIcons[index],
                          size: 22,
                          color: isSelected ? primaryBlue : Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            menuItems[index],
                            style: TextStyle(
                              color: isSelected ? primaryBlue : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openSettings,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t('settings'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t('logout'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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

  Widget _buildSavedAvailabilitiesList() {
    if (isLoadingAvailabilities) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }

    if (savedAvailabilities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          'No saved schedules yet.',
          style: TextStyle(color: subText, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Column(
      children: savedAvailabilities.map((availability) {
        final id = availability['_id']?.toString() ?? '';
        final day = availability['day']?.toString() ?? '-';
        final visitType = availability['visitType']?.toString() ?? '-';
        final slots = availability['slots'];

        final slotList = slots is List
            ? slots.map((e) => e.toString()).toList()
            : <String>[];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: deepBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$day • ${visitType.toUpperCase()}',
                      style: TextStyle(
                        color: darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      slotList.isEmpty ? 'No times' : slotList.join('  •  '),
                      style: TextStyle(
                        color: subText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              TextButton.icon(
                onPressed: id.isEmpty ? null : () => deleteAvailability(id),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFD32F2F),
                  size: 18,
                ),
                label: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Text(
            menuItems[selectedIndex],
            style: TextStyle(
              color: darkText,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _openSettings,
            icon: Icon(Icons.settings_outlined, color: deepBlue),
            tooltip: t('settings'),
          ),
          const SizedBox(width: 12),
          _buildNotificationButton(),
          const SizedBox(width: 16),
          _buildProfileChip(),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _showNutritionistNotificationsPanel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF0D8BFF),
            ),
          ),

          if (_nutritionistUnreadNotificationsCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(5),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _nutritionistUnreadNotificationsCount > 9
                      ? '9+'
                      : _nutritionistUnreadNotificationsCount.toString(),
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
    );
  }

  Widget _buildProfileChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFDFF1FF),
            child: isLoadingProfile
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF0A4FA3),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLoadingProfile ? 'Loading...' : fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF102A43),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                specialty.isNotEmpty ? specialty : 'Type 1 Diabetes Nutrition',
                style: const TextStyle(color: Color(0xFF5F7896), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPage() {
    switch (selectedIndex) {
      case 0:
        return _buildDashboardPage();
      case 1:
        return _buildPatientsPage();
      case 2:
        return _buildAppointmentsPage();
      case 3:
        return _buildMessagesPage();
      case 4:
        return _buildMealPlansPage();
      case 5:
        return _buildAvailableSlotsPage();
      case 6:
        return _buildProfilePage();
      default:
        return _buildDashboardPage();
    }
  }

  Widget _buildDashboardPage() {
    if (isLoadingDashboard) {
      return Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final cardWidth = (totalWidth - 36) / 4;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStatCard(
                    width: cardWidth < 240 ? 240 : cardWidth,
                    title: 'Today Appointments',
                    value: dashboardTodayAppointments.length.toString(),
                    icon: Icons.calendar_today_outlined,
                    iconColor: const Color(0xFF0D8BFF),
                    bgColor: const Color(0xFFDFF1FF),
                  ),
                  _buildStatCard(
                    width: cardWidth < 240 ? 240 : cardWidth,
                    title: 'Active Patients',
                    value: dashboardActivePatientsCount.toString(),
                    icon: Icons.people_alt_outlined,
                    iconColor: const Color(0xFF0288D1),
                    bgColor: const Color(0xFFD9F2FF),
                  ),
                  _buildStatCard(
                    width: cardWidth < 240 ? 240 : cardWidth,
                    title: 'Unread Messages',
                    value: dashboardUnreadMessagesCount.toString(),
                    icon: Icons.chat_bubble_outline_rounded,
                    iconColor: const Color(0xFF0A5FC7),
                    bgColor: const Color(0xFFE3F2FD),
                  ),
                  _buildStatCard(
                    width: cardWidth < 240 ? 240 : cardWidth,
                    title: 'Plans Need Review',
                    value: dashboardPendingMealPlansCount.toString(),
                    icon: Icons.restaurant_menu_rounded,
                    iconColor: const Color(0xFF039BE5),
                    bgColor: const Color(0xFFD8F7FF),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 22),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: _buildSectionCard(
                  title: 'Today Appointments',
                  child: dashboardTodayAppointments.isEmpty
                      ? _buildEmptyDashboardText('No appointments for today.')
                      : _buildDashboardAppointmentsTable(),
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                flex: 4,
                child: _buildSectionCard(
                  title: 'Important Alerts',
                  child: dashboardPatientAlerts.isEmpty
                      ? _buildEmptyDashboardText('No alerts for now.')
                      : Column(
                          children: dashboardPatientAlerts.map((alert) {
                            final type = alert['type']?.toString() ?? '';
                            final name =
                                alert['name']?.toString() ?? 'Unknown Patient';
                            final message = alert['message']?.toString() ?? '';

                            return _buildAlertTile(
                              name: name,
                              message: message,
                              icon: _dashboardAlertIcon(type),
                              color: _dashboardAlertColor(type),
                              bg: _dashboardAlertBg(type),
                            );
                          }).toList(),
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSectionCard(
                  title: 'Recent Patient Activity',
                  child: dashboardRecentActivities.isEmpty
                      ? _buildEmptyDashboardText('No recent activity.')
                      : Column(
                          children: dashboardRecentActivities.map((activity) {
                            return _buildActivityRow(
                              title: activity['title']?.toString() ?? '',
                              time: activity['time']?.toString() ?? '',
                            );
                          }).toList(),
                        ),
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: _buildSectionCard(
                  title: 'Meal Plans Review',
                  child: dashboardMealPlansReview.isEmpty
                      ? _buildEmptyDashboardText('No meal plans yet.')
                      : Column(
                          children: dashboardMealPlansReview.map((plan) {
                            return _buildMealPlanReviewRow(
                              patient:
                                  plan['patient']?.toString() ??
                                  'Unknown Patient',
                              goal: plan['goal']?.toString() ?? 'Meal Plan',
                            );
                          }).toList(),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDashboardText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: subText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  IconData _dashboardAlertIcon(String type) {
    switch (type) {
      case 'high_glucose':
        return Icons.warning_rounded;
      case 'low_glucose':
        return Icons.bloodtype_rounded;
      case 'meal_plan_review':
        return Icons.restaurant_menu_rounded;
      case 'appointment_today':
        return Icons.calendar_today_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _dashboardAlertColor(String type) {
    switch (type) {
      case 'high_glucose':
        return const Color(0xFF0A4FA3);
      case 'low_glucose':
        return const Color(0xFF039BE5);
      case 'meal_plan_review':
        return const Color(0xFF0A5FC7);
      case 'appointment_today':
        return primaryBlue;
      default:
        return deepBlue;
    }
  }

  Color _dashboardAlertBg(String type) {
    switch (type) {
      case 'high_glucose':
        return const Color(0xFFDFF1FF);
      case 'low_glucose':
        return const Color(0xFFD8F7FF);
      case 'meal_plan_review':
        return const Color(0xFFE3F2FD);
      case 'appointment_today':
        return const Color(0xFFD9F2FF);
      default:
        return const Color(0xFFEAF6FF);
    }
  }

  Widget _buildDashboardAppointmentsTable() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFDFF1FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _tableCell('Patient', 2, isHeader: true),
              _tableCell('Time', 1.2, isHeader: true),
              _tableCell('Type', 1.2, isHeader: true),
              _tableCell('Status', 1.2, isHeader: true),
            ],
          ),
        ),
        ...dashboardTodayAppointments.map((appointment) {
          final patientName = _getPatientName(appointment);
          final time = appointment['time']?.toString() ?? '-';
          final visitType = appointment['visitType']?.toString() ?? '-';
          final status = appointment['status']?.toString() ?? '-';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                _tableCell(patientName, 2),
                _tableCell(time, 1.2),
                _tableCell(visitType, 1.2),
                Expanded(flex: 12, child: _buildStatusChip(status)),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPatientsPage() {
    return Column(
      children: [
        const SizedBox(height: 20),

        Expanded(
          child: isLoadingAppointments
              ? Center(child: CircularProgressIndicator(color: primaryBlue))
              : bookedPatients.isEmpty
              ? Center(
                  child: Text(
                    'No booked patients found.',
                    style: TextStyle(
                      color: subText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : GridView.builder(
                  itemCount: bookedPatients.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 370,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.75,
                  ),
                  itemBuilder: (context, index) {
                    final patient = bookedPatients[index];

                    final firstName = patient['firstName']?.toString() ?? '';
                    final lastName = patient['lastName']?.toString() ?? '';
                    final email = patient['email']?.toString() ?? '';

                    String patientName = '$firstName $lastName'.trim();

                    if (patientName.isEmpty) {
                      patientName = email.isNotEmpty
                          ? email
                          : 'Unknown Patient';
                    }

                    final patientId = patient['_id']?.toString() ?? '';

                    return _buildPatientCard(
                      name: patientName,
                      status: 'Booked',
                      onViewDetails: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NutritionistPatientDetailsPage(
                                  patientId: patientId,
                                  patientName: patientName,
                                  nutritionistId: widget.userId,
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsPage() {
    return SingleChildScrollView(
      child: _buildSectionCard(
        title: 'Appointments',
        action: ElevatedButton.icon(
          onPressed: fetchNutritionistAppointments,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
          style: ElevatedButton.styleFrom(
            backgroundColor: deepBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildAppointmentFilterButton('All', 'all'),
                const SizedBox(width: 8),
                _buildAppointmentFilterButton('Online', 'online'),
                const SizedBox(width: 8),
                _buildAppointmentFilterButton('Clinic', 'clinic'),
              ],
            ),
            const SizedBox(height: 18),

            if (isLoadingAppointments)
              Padding(
                padding: const EdgeInsets.all(30),
                child: CircularProgressIndicator(color: primaryBlue),
              )
            else if (filteredAppointments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(30),
                child: Text(
                  'No appointments found.',
                  style: TextStyle(
                    color: subText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              _buildAppointmentsDbTable(filteredAppointments),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsDbTable(List<dynamic> list) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFDFF1FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _tableCell('Patient', 2, isHeader: true),
              _tableCell('Day', 1.2, isHeader: true),
              _tableCell('Time', 1.2, isHeader: true),
              _tableCell('Type', 1.2, isHeader: true),
              _tableCell('Status', 1.2, isHeader: true),
              _tableCell('Action', 1, isHeader: true),
            ],
          ),
        ),
        ...list.map((appointment) {
          return _buildAppointmentDbRow(appointment);
        }).toList(),
      ],
    );
  }

  void _showMeetingLinkDialog(String meetingLink) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF8FCFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Online Meeting',
            style: TextStyle(color: darkText, fontWeight: FontWeight.w800),
          ),
          content: SelectableText(
            meetingLink,
            style: TextStyle(color: deepBlue, fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close', style: TextStyle(color: subText)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentDbRow(dynamic appointment) {
    final patientName = _getPatientName(appointment);
    final day = appointment['day']?.toString() ?? '-';
    final time = appointment['time']?.toString() ?? '-';
    final visitType = appointment['visitType']?.toString() ?? '-';
    final status = appointment['status']?.toString() ?? '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          _tableCell(patientName, 2),
          _tableCell(day, 1.2),
          _tableCell(time, 1.2),
          _tableCell(visitType, 1.2),
          Expanded(flex: 12, child: _buildStatusChip(status)),
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerLeft,
              child: visitType.toLowerCase() == 'online'
                  ? TextButton.icon(
                      onPressed: () {
                        final meetingLink =
                            appointment['meetingLink']?.toString() ?? '';
                        _openMeetingLink(meetingLink);
                      },
                      icon: Icon(
                        Icons.video_call_rounded,
                        color: deepBlue,
                        size: 18,
                      ),
                      label: Text(
                        'Meeting',
                        style: TextStyle(
                          color: deepBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFF1FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Clinic Visit',
                        style: TextStyle(
                          color: subText,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentFilterButton(String text, String value) {
    final bool isSelected = selectedAppointmentFilter == value;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          selectedAppointmentFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? deepBlue : const Color(0xFFF2FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? deepBlue : borderColor),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : darkText,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesPage() {
    return Row(
      children: [
        Container(
          width: 350,
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSimpleSearchBox('Search messages...'),
              ),

              Expanded(
                child: isLoadingConversations
                    ? Center(
                        child: CircularProgressIndicator(color: primaryBlue),
                      )
                    : conversations.isEmpty
                    ? Center(
                        child: Text(
                          'No conversations yet.',
                          style: TextStyle(
                            color: subText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          final user = conversation['user'];
                          final lastMessage =
                              conversation['lastMessage']?.toString() ?? '';

                          final isSelected =
                              selectedConversationUser != null &&
                              selectedConversationUser!['_id'].toString() ==
                                  user['_id'].toString();

                          return _buildConversationUser(
                            user: user,
                            lastMessage: lastMessage,
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                selectedConversationUser =
                                    Map<String, dynamic>.from(user);
                              });

                              fetchChatMessages(user['_id'].toString());
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 18),

        Expanded(
          child: Container(
            decoration: _cardDecoration(),
            child: selectedConversationUser == null
                ? Center(
                    child: Text(
                      'Select a conversation to start messaging.',
                      style: TextStyle(
                        color: subText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: borderColor),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFDFF1FF),
                              child: Text(
                                getUserInitials(selectedConversationUser),
                                style: const TextStyle(
                                  color: Color(0xFF0A4FA3),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              getUserName(selectedConversationUser),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: isLoadingMessages
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: primaryBlue,
                                ),
                              )
                            : chatMessages.isEmpty
                            ? Center(
                                child: Text(
                                  'No messages yet.',
                                  style: TextStyle(
                                    color: subText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: chatMessages.length,
                                itemBuilder: (context, index) {
                                  final msg = chatMessages[index];
                                  final senderId =
                                      msg['senderId']?.toString() ?? '';
                                  final text = msg['message']?.toString() ?? '';

                                  final isMe = senderId == widget.userId;

                                  return _buildChatBubble(
                                    message: text,
                                    isMe: isMe,
                                  );
                                },
                              ),
                      ),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: borderColor)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                decoration: InputDecoration(
                                  hintText: 'Write your reply...',
                                  filled: true,
                                  fillColor: const Color(0xFFEAF6FF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                onSubmitted: (_) => sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: sendMessage,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: deepBlue,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversationUser({
    required dynamic user,
    required String lastMessage,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDFF1FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: selected ? Border.all(color: borderColor) : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFDFF1FF),
              child: Text(
                getUserInitials(user),
                style: const TextStyle(
                  color: Color(0xFF0A4FA3),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getUserName(user),
                    style: TextStyle(
                      color: darkText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: subText, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealPlansPage() {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create meal plan',
                    style: TextStyle(
                      color: darkText,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(child: _buildPatientDropdownField()),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildLabeledField(
                          label: 'Plan title',
                          hint: 'e.g. Low-carb dinner',
                          controller: planTitleController,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _buildLabeledField(
                    label: 'Clinical goal',
                    hint: 'e.g. Reduce post-meal spikes, target HbA1c',
                    controller: clinicalGoalController,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Start date',
                          date: mealPlanStartDate,
                          onTap: () => pickMealPlanDate(isStartDate: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          label: 'End date',
                          date: mealPlanEndDate,
                          onTap: () => pickMealPlanDate(isStartDate: false),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),
                  Divider(color: borderColor),
                  const SizedBox(height: 16),

                  _buildSmallSectionTitle('GLUCOSE TARGETS (MG/DL)'),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildLabeledField(
                          label: 'Fasting',
                          hint: '80–130',
                          controller: fastingTargetController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLabeledField(
                          label: 'Post-meal (2h)',
                          hint: '< 180',
                          controller: postMealTargetController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLabeledField(
                          label: 'HbA1c target (%)',
                          hint: '< 7.0',
                          controller: hba1cTargetController,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),
                  Divider(color: borderColor),
                  const SizedBox(height: 16),

                  _buildSmallSectionTitle('MEAL BREAKDOWN'),

                  const SizedBox(height: 14),

                  _buildDetailedMealBlock(
                    mealName: 'Breakfast',
                    time: '7:00–9:00 AM',
                    foodController: breakfastFoodController,
                    calController: breakfastCalController,
                    carbsController: breakfastCarbsController,
                    proController: breakfastProController,
                    fatController: breakfastFatController,
                    notesController: breakfastNotesController,
                  ),
                  const SizedBox(height: 16),

                  _buildDetailedMealBlock(
                    mealName: 'Lunch',
                    time: '12:00–1:30 PM',
                    foodController: lunchFoodController,
                    calController: lunchCalController,
                    carbsController: lunchCarbsController,
                    proController: lunchProController,
                    fatController: lunchFatController,
                    notesController: lunchNotesController,
                  ),
                  const SizedBox(height: 16),

                  _buildDetailedMealBlock(
                    mealName: 'Dinner',
                    time: '6:00–8:00 PM',
                    foodController: dinnerFoodController,
                    calController: dinnerCalController,
                    carbsController: dinnerCarbsController,
                    proController: dinnerProController,
                    fatController: dinnerFatController,
                    notesController: dinnerNotesController,
                  ),
                  const SizedBox(height: 16),

                  _buildDetailedMealBlock(
                    mealName: 'Snack',
                    time: '3:00–4:00 PM',
                    foodController: snackFoodController,
                    calController: snackCalController,
                    carbsController: snackCarbsController,
                    proController: snackProController,
                    fatController: snackFatController,
                    notesController: snackNotesController,
                  ),

                  const SizedBox(height: 22),
                  Divider(color: borderColor),
                  const SizedBox(height: 16),

                  _buildSmallSectionTitle('DAILY TOTALS'),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTotalBox(
                          value: totalCalories.toStringAsFixed(0),
                          label: 'kcal',
                          color: const Color(0xFFE3F2FD),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTotalBox(
                          value: '${totalCarbs.toStringAsFixed(0)}g',
                          label: 'Carbs',
                          color: const Color(0xFFBBDEFB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTotalBox(
                          value: '${totalProtein.toStringAsFixed(0)}g',
                          label: 'Protein',
                          color: const Color(0xFF90CAF9),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTotalBox(
                          value: '${totalFat.toStringAsFixed(0)}g',
                          label: 'Fat',
                          color: const Color(0xFF42A5F5),
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: isSavingMealPlan ? null : saveMealPlan,
                      icon: Icon(
                        isEditingMealPlan
                            ? Icons.edit_rounded
                            : Icons.save_rounded,
                        color: deepBlue,
                        size: 20,
                      ),
                      label: Text(
                        isSavingMealPlan
                            ? 'Saving...'
                            : isEditingMealPlan
                            ? 'Update plan'
                            : 'Save plan',
                        style: TextStyle(
                          color: darkText,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 24),

          Expanded(
            flex: 4,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: _cardDecoration(),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPlanStatBox(
                          value: assignedMealPlans
                              .where(
                                (plan) =>
                                    (plan['status']?.toString() ?? 'active') ==
                                    'active',
                              )
                              .length
                              .toString(),
                          label: 'Active plans',
                          color: const Color(0xFFE3F2FD),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPlanStatBox(
                          value: assignedMealPlans
                              .where(
                                (plan) =>
                                    (plan['status']?.toString() ?? '') ==
                                    'review',
                              )
                              .length
                              .toString(),
                          label: 'Reviews due',
                          color: const Color(0xFFBBDEFB),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Assigned plans',
                            style: TextStyle(
                              color: darkText,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: fetchNutritionistMealPlans,
                            icon: Icon(Icons.refresh_rounded, color: deepBlue),
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      if (isLoadingMealPlans)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: primaryBlue,
                            ),
                          ),
                        )
                      else if (assignedMealPlans.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No assigned plans yet.',
                              style: TextStyle(
                                color: subText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        ...assignedMealPlans.map((plan) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildAssignedPlanFromDb(plan),
                          );
                        }).toList(),
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

  Widget _buildPatientDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Patient',
          style: TextStyle(
            color: deepBlue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedMealPlanPatientId,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryBlue, width: 1.3),
            ),
          ),
          hint: const Text('Select patient'),
          items: bookedPatients.map<DropdownMenuItem<String>>((patient) {
            final patientId = patient['_id']?.toString() ?? '';
            final patientName = getPatientNameFromUser(patient);

            return DropdownMenuItem<String>(
              value: patientId,
              child: Text(patientName, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedMealPlanPatientId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: deepBlue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatMealPlanDate(date),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_rounded, color: darkText, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledField({
    required String label,
    required String hint,
    TextEditingController? controller,
    IconData? suffixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: deepBlue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 16),
            suffixIcon: suffixIcon == null
                ? null
                : Icon(suffixIcon, color: darkText, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryBlue, width: 1.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: deepBlue,
        fontSize: 14,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildDetailedMealBlock({
    required String mealName,
    required String time,
    required TextEditingController foodController,
    required TextEditingController calController,
    required TextEditingController carbsController,
    required TextEditingController proController,
    required TextEditingController fatController,
    required TextEditingController notesController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              mealName,
              style: TextStyle(
                color: darkText,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: TextStyle(
                color: primaryBlue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildSimpleMealInput('Food items', foodController),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSimpleMealInput(
                'Cal',
                calController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSimpleMealInput(
                'Carbs',
                carbsController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSimpleMealInput(
                'Pro',
                proController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSimpleMealInput(
                'Fat',
                fatController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        _buildSimpleMealInput('Clinical notes', notesController),
      ],
    );
  }

  Widget _buildSimpleMealInput(
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF333333), fontSize: 16),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFD8D8D8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFD8D8D8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: primaryBlue),
        ),
      ),
    );
  }

  Widget _buildTotalBox({
    required String value,
    required String label,
    required Color color,
    Color textColor = const Color(0xFF0A4FA3),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: textColor.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanStatBox({
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: darkText,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: deepBlue,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedPlanFromDb(dynamic plan) {
    final patient = plan['patientId'];
    final patientName = getPatientNameFromUser(patient);
    final planTitle = plan['planTitle']?.toString() ?? 'Meal Plan';
    final rawStatus = plan['status']?.toString() ?? 'active';
    final endDate = DateTime.tryParse(plan['endDate']?.toString() ?? '');

    String status = rawStatus;

    if (endDate != null && DateTime.now().isAfter(endDate)) {
      status = 'done';
    }
    final initials = patientName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    String statusText = 'On track';
    Color statusColor = const Color(0xFF9CCC65);

    if (status == 'review') {
      statusText = 'Review';
      statusColor = const Color(0xFFFFC56D);
    } else if (status == 'done') {
      statusText = 'Done';
      statusColor = const Color(0xFFDFF1FF);
    }

    return _buildAssignedPlanDetailedCard(
      initials: initials.isNotEmpty ? initials : 'P',
      patientName: patientName,
      planName: planTitle,
      status: statusText,
      dayText: _planDayText(plan),
      progress: _planProgress(plan),
      color: const Color(0xFFE3F2FD),
      statusColor: statusColor,
      onEdit: () => editMealPlan(plan),
    );
  }

  String _planDayText(dynamic plan) {
    final start = DateTime.tryParse(plan['startDate']?.toString() ?? '');
    final end = DateTime.tryParse(plan['endDate']?.toString() ?? '');
    final now = DateTime.now();

    if (start == null || end == null) {
      return 'Active plan';
    }

    final totalDays = end.difference(start).inDays.abs() + 1;
    final currentDay = now.difference(start).inDays + 1;

    if (currentDay <= 0) {
      return 'Starts soon';
    }

    if (currentDay > totalDays) {
      return 'Completed period';
    }

    return 'Day $currentDay of $totalDays';
  }

  double _planProgress(dynamic plan) {
    final start = DateTime.tryParse(plan['startDate']?.toString() ?? '');
    final end = DateTime.tryParse(plan['endDate']?.toString() ?? '');
    final now = DateTime.now();

    if (start == null || end == null) {
      return 0.0;
    }

    final totalDays = end.difference(start).inDays.abs() + 1;
    final currentDay = now.difference(start).inDays + 1;

    return (currentDay / totalDays).clamp(0.0, 1.0);
  }

  Widget _buildAssignedPlanDetailedCard({
    required String initials,
    required String patientName,
    required String planName,
    required String status,
    required String dayText,
    required double progress,
    required Color color,
    required Color statusColor,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: deepBlue,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: TextStyle(
                        color: darkText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      planName,
                      style: TextStyle(
                        color: deepBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == 'Review'
                        ? const Color(0xFF7A5200)
                        : darkText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                dayText,
                style: TextStyle(
                  color: deepBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'Edit',
                  style: TextStyle(
                    color: deepBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.65),
              valueColor: AlwaysStoppedAnimation<Color>(deepBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanInput(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: subText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFEAF6FF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryBlue, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildMealRow(String mealName) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            mealName,
            style: TextStyle(
              color: darkText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        Expanded(flex: 3, child: _buildMealPlanInput('Food items')),

        const SizedBox(width: 12),

        Expanded(child: _buildMealPlanInput('Carbs')),

        const SizedBox(width: 12),

        Expanded(flex: 3, child: _buildMealPlanInput('Notes')),
      ],
    );
  }

  Widget _buildAssignedMealPlanCard({
    required String patientName,
    required String planTitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF0D8BFF),
            size: 28,
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: TextStyle(
                    color: darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  planTitle,
                  style: TextStyle(
                    color: darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          TextButton(
            onPressed: () {
              debugPrint('Edit plan');
            },
            child: Text(
              'Edit',
              style: TextStyle(
                color: deepBlue,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsPage() {
    return SingleChildScrollView(
      child: _buildSectionCard(
        title: 'Nutrition Reports',
        child: Column(
          children: [
            _buildReportItem(
              title: 'Weekly Nutrition Report',
              desc: 'Meals logged, carbs average, glucose-food relation.',
            ),
            _buildReportItem(
              title: 'Monthly Glucose-Food Report',
              desc: 'Shows frequent highs and lows after meals.',
            ),
            _buildReportItem(
              title: 'Patient Adherence Report',
              desc: 'Tracks how much the patient follows the meal plan.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    if (isLoadingProfile) {
      return Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    return SingleChildScrollView(
      child: _buildSectionCard(
        title: 'Nutritionist Profile',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            Row(
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
                      fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty.isNotEmpty
                          ? specialty
                          : 'Type 1 Diabetes Nutrition Specialist',
                      style: const TextStyle(color: Color(0xFF5F7896)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileInfo(
                        'Email',
                        email.isNotEmpty ? email : '-',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProfileInfo(
                        'Phone',
                        phone.isNotEmpty ? phone : '-',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildProfileInfo(
                        'Workplace',
                        workplace.isNotEmpty ? workplace : '-',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProfileInfo(
                        'Experience',
                        yearsOfExperience.isNotEmpty
                            ? '$yearsOfExperience years'
                            : '-',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildProfileInfo(
                        'Specialty',
                        specialty.isNotEmpty ? specialty : '-',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: openEditProfileDialog,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: deepBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
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
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(title, style: TextStyle(color: subText, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildAppointmentsTable() {
    return _buildAppointmentsList(
      todayAppointments,
      emptyMessage: 'No appointments for today.',
    );
  }

  Widget _buildAppointmentsList(
    List<dynamic> list, {
    String emptyMessage = 'No appointments found.',
  }) {
    if (isLoadingAppointments) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Text(
          emptyMessage,
          style: TextStyle(
            color: subText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildTableHeader(),
        ...list
            .map((appointment) => _buildAppointmentRow(appointment))
            .toList(),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF1FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _tableCell('Patient', 2, isHeader: true),
          _tableCell('Day', 1.1, isHeader: true),
          _tableCell('Time', 1.1, isHeader: true),
          _tableCell('Type', 1.2, isHeader: true),
          _tableCell('Status', 1.2, isHeader: true),
          _tableCell('Action', 1, isHeader: true),
        ],
      ),
    );
  }

  Widget _buildAppointmentRow(dynamic appointment) {
    final patientName = _getPatientName(appointment);
    final day = appointment['day']?.toString() ?? '-';
    final time = appointment['time']?.toString() ?? '-';
    final visitType = appointment['visitType']?.toString() ?? '-';
    final status = appointment['status']?.toString() ?? '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          _tableCell(patientName, 2),
          _tableCell(day, 1.1),
          _tableCell(time, 1.1),
          _tableCell(visitType, 1.2),
          Expanded(flex: 12, child: _buildStatusChip(status)),
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  debugPrint('Appointment id: ${appointment['_id']}');
                },
                child: Text(
                  'View',
                  style: TextStyle(
                    color: deepBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableCell(String text, double flex, {bool isHeader = false}) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isHeader ? darkText : const Color(0xFF405A76),
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    Color bg;
    final value = status.toLowerCase();

    if (value == 'booked' || value == 'confirmed') {
      color = const Color(0xFF0D8BFF);
      bg = const Color(0xFFDFF1FF);
    } else if (value == 'completed') {
      color = const Color(0xFF0A5FC7);
      bg = const Color(0xFFD9F2FF);
    } else if (value == 'cancelled') {
      color = const Color(0xFF073B7A);
      bg = const Color(0xFFE3F2FD);
    } else {
      color = const Color(0xFF405A76);
      bg = const Color(0xFFEAF6FF);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildAlertTile({
    required String name,
    required String message,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: darkText,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(message, style: TextStyle(color: subText, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow({required String title, required String time}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: darkText,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Text(time, style: TextStyle(color: subText, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMealPlanReviewRow({
    required String patient,
    required String goal,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: Color(0xFF0D8BFF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$patient\n$goal',
              style: TextStyle(
                color: darkText,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'Review',
              style: TextStyle(color: deepBlue, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSearchBox(String hint) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF5D9BD3)),
          const SizedBox(width: 8),
          Text(
            hint,
            style: const TextStyle(color: Color(0xFF5D9BD3), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallFilter(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: darkText,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPatientCard({
    required String name,
    required String status,
    required VoidCallback onViewDetails,
  }) {
    Color statusColor;
    Color statusBg;

    if (status == 'Booked') {
      statusColor = const Color(0xFF0D8BFF);
      statusBg = const Color(0xFFDFF1FF);
    } else if (status == 'Stable') {
      statusColor = const Color(0xFF0D8BFF);
      statusBg = const Color(0xFFDFF1FF);
    } else if (status == 'Low Alert') {
      statusColor = const Color(0xFF039BE5);
      statusBg = const Color(0xFFD8F7FF);
    } else {
      statusColor = const Color(0xFF073B7A);
      statusBg = const Color(0xFFE3F2FD);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFDFF1FF),
                child: Icon(Icons.person, color: Color(0xFF0D8BFF), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const Spacer(),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewDetails,
                child: Text(
                  'View Details',
                  style: TextStyle(
                    color: deepBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              '$label:',
              style: TextStyle(color: subText, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: darkText, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageUser(String name, String lastMessage, bool selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFDFF1FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: selected ? Border.all(color: borderColor) : null,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFDFF1FF),
            child: Icon(Icons.person, color: Color(0xFF0D8BFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subText, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble({required String message, required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 430),
        decoration: BoxDecoration(
          color: isMe ? primaryBlue : const Color(0xFFEAF6FF),
          borderRadius: BorderRadius.circular(16),
          border: isMe ? null : Border.all(color: borderColor),
        ),
        child: Text(
          message,
          style: TextStyle(color: isMe ? Colors.white : darkText, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildMealInfoCard() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 330,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFDFF1FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attached Meal Data',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text('Meal: Lunch'),
            Text('Carbs: 75g'),
            Text('Before glucose: 190 mg/dL'),
            Text('After glucose: 240 mg/dL'),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFEAF6FF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryBlue, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildMealPlanRow(String mealName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              mealName,
              style: TextStyle(color: darkText, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: _buildInputField('Food items')),
          const SizedBox(width: 10),
          SizedBox(width: 120, child: _buildInputField('Carbs')),
          const SizedBox(width: 10),
          Expanded(child: _buildInputField('Notes')),
        ],
      ),
    );
  }

  Widget _buildAssignedPlan(String patient, String plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF0D8BFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$patient\n$plan',
              style: TextStyle(
                color: darkText,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'Edit',
              style: TextStyle(color: deepBlue, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem({required String title, required String desc}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF1FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Color(0xFF0D8BFF),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: darkText,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: subText, fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: deepBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Export PDF'),
          ),
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
