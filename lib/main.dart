import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'providers/app_settings_provider.dart';

import 'services/appointment_reminder_service.dart';
import 'firebase_options.dart';
import 'notification_service.dart';
import 'services/firebase_notification_service.dart';
import 'doctor_web_dashboard.dart';
import 'nutritionist_web_dashboard.dart';
import 'auth_screen.dart';
import 'patient_screen.dart';
import 'family_home_screen.dart';
import 'services/family_api.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('BACKGROUND FCM MESSAGE: ${message.messageId}');
  print('BACKGROUND FCM DATA: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.init();
  await AppointmentReminderService.init();
  await FirebaseNotificationService.init();

  final prefs = await SharedPreferences.getInstance();
  final savedUserId = prefs.getString('userId');
  final savedRole = prefs.getString('role');

  final appSettingsProvider = AppSettingsProvider();
  await appSettingsProvider.loadSettings();

  runApp(
    ChangeNotifierProvider<AppSettingsProvider>.value(
      value: appSettingsProvider,
      child: MyApp(savedUserId: savedUserId, savedRole: savedRole),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? savedUserId;
  final String? savedRole;

  const MyApp({super.key, required this.savedUserId, required this.savedRole});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xffEAF6FF),
        primaryColor: const Color(0xff185FA5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff185FA5),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xff071A2F),
        primaryColor: const Color(0xff185FA5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff185FA5),
          brightness: Brightness.dark,
        ),
      ),
      home: StartScreen(savedUserId: savedUserId, savedRole: savedRole),
    );
  }
}

class StartScreen extends StatefulWidget {
  final String? savedUserId;
  final String? savedRole;

  const StartScreen({
    super.key,
    required this.savedUserId,
    required this.savedRole,
  });

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool isLoading = true;
  Widget startScreen = const AuthScreen();

  @override
  void initState() {
    super.initState();
    _decideStartScreen();
  }

  Future<void> _decideStartScreen() async {
    final userId = widget.savedUserId;
    final role = widget.savedRole;

    if (userId == null || userId.isEmpty || role == null || role.isEmpty) {
      setState(() {
        startScreen = const AuthScreen();
        isLoading = false;
      });
      return;
    }

    if (role == 'patient') {
      setState(() {
        startScreen = PatientHomeScreen(userId: userId);
        isLoading = false;
      });
      return;
    }

    if (role == 'doctor') {
      setState(() {
        startScreen = DoctorWebDashboard(doctorId: userId);
        isLoading = false;
      });
      return;
    }

    if (role == 'nutritionist') {
      setState(() {
        startScreen = NutritionistWebDashboard(userId: userId);
        isLoading = false;
      });
      return;
    }

    if (role == 'family') {
      try {
        final familyData = await FamilyApi.getFamilyProfile(userId);

        final parentProfile = familyData['parentProfile'];
        final linkedPatient = parentProfile['linkedPatientId'];

        final linkedPatientId = linkedPatient is Map
            ? linkedPatient['_id'].toString()
            : linkedPatient.toString();

        final linkedPatientName = linkedPatient is Map
            ? '${linkedPatient['firstName'] ?? ''} ${linkedPatient['lastName'] ?? ''}'
                  .trim()
            : 'Patient';

        setState(() {
          startScreen = FamilyHomeScreen(
            familyUserId: userId,
            patientId: linkedPatientId,
            initialPatientName: linkedPatientName,
          );
          isLoading = false;
        });
      } catch (e) {
        print('FAILED TO AUTO LOGIN FAMILY: $e');

        setState(() {
          startScreen = const AuthScreen();
          isLoading = false;
        });
      }

      return;
    }

    setState(() {
      startScreen = const AuthScreen();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return startScreen;
  }
}
