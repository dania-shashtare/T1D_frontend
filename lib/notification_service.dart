import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings);

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Gaza'));
  }

  static Future<void> scheduleRecheckNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'low_glucose_channel',
          'Low Glucose Alerts',
          channelDescription:
              'Reminder to recheck blood glucose after treatment',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      1001,
      'Time to recheck your glucose',
      '15 minutes passed. Please check your blood sugar now.',
      tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1)),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
