import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int lantusNotificationId = 3001;

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == 'lantus_taken') {
          await _notificationsPlugin.cancel(lantusNotificationId);
        }
      },
    );
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Gaza'));
  }

  static Future<void> confirmLantusTakenToday(String userId) async {
    final now = DateTime.now();

    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lantusTakenDate', today);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('daily_lantus')
        .doc(today)
        .set({
          'taken': true,
          'takenAt': FieldValue.serverTimestamp(),
          'date': today,
        }, SetOptions(merge: true));
  }

  static Future<void> scheduleLantusNotification({
    required String userId,
    required int hour,
    required int minute,
  }) async {
    print('ENTERED scheduleLantusNotification');

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'lantus_channel',
          'Lantus Reminders',
          channelDescription: 'Daily reminder to take Lantus insulin',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          actions: const [
            AndroidNotificationAction(
              'lantus_taken',
              'I took Lantus',
              showsUserInterface: false,
            ),
          ],
        );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    final now = tz.TZDateTime.now(tz.local);

    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledTime.isAfter(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final delay = scheduledTime.difference(now);

    print('NOW: $now');
    print('SCHEDULED TIME: $scheduledTime');
    print('DIFFERENCE: ${delay.inMinutes} minutes');

    Timer(delay, () async {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': 'Lantus Reminder',
            'body': 'It is time to take your Lantus insulin.',
            'type': 'lantus',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

      await _notificationsPlugin.show(
        lantusNotificationId,
        'Lantus Reminder',
        'It is time to take your Lantus insulin.',
        details,
      );

      Timer.periodic(const Duration(minutes: 5), (timer) async {
        final snapshot = await docRef.get();

        if (!snapshot.exists) {
          timer.cancel();
          return;
        }

        final data = snapshot.data();
        final isRead = data?['isRead'] == true;

        if (isRead) {
          timer.cancel();
          print('LANTUS REMINDER STOPPED: notification was read');
          return;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add({
              'title': 'Lantus Reminder Again',
              'body': 'You still need to take your Lantus insulin.',
              'type': 'lantus_reminder_again',
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });

        await _notificationsPlugin.show(
          3002,
          'Lantus Reminder Again',
          'You still need to take your Lantus insulin.',
          details,
        );

        print('LANTUS REMINDER SENT AGAIN');
      });
    });
  }

  static Future<void> showLowGlucoseNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'low_glucose_channel',
      'Low Glucose Alerts',
      channelDescription: 'Reminder to recheck blood glucose after treatment',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      1001,
      'Time to recheck your glucose',
      '15 minutes passed. Please check your blood sugar now.',
      details,
    );
  }

  static Future<void> showHighGlucoseNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_glucose_channel',
          'High Glucose Alerts',
          channelDescription: 'Reminder to recheck high blood glucose',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      2001,
      'High glucose follow-up',
      '1 minute passed. Please recheck your glucose.',
      details,
    );
  }
}
