import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_screen.dart';
import 'firebase_options.dart';
import 'services/firebase_notification_service.dart';
import 'patient_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseNotificationService.init();

  final prefs = await SharedPreferences.getInstance();
  final savedUserId = prefs.getString('userId');
  final savedRole = prefs.getString('role');

  runApp(MyApp(savedUserId: savedUserId, savedRole: savedRole));
}

class MyApp extends StatelessWidget {
  final String? savedUserId;
  final String? savedRole;

  const MyApp({super.key, required this.savedUserId, required this.savedRole});

  @override
  Widget build(BuildContext context) {
    Widget startScreen = const AuthScreen();

    if (savedUserId != null && savedUserId!.isNotEmpty) {
      if (savedRole == 'patient') {
        startScreen = PatientHomeScreen(userId: savedUserId!);
      }
    }

    return MaterialApp(debugShowCheckedModeBanner: false, home: startScreen);
  }
}
