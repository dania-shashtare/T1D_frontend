import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppointmentReminderService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static final Map<String, Timer> _timers = {};

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    const channel = AndroidNotificationChannel(
      'appointment_channel',
      'Appointment Reminders',
      description: 'Reminders for doctor and nutritionist appointments',
      importance: Importance.max,
      playSound: true,
    );

    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.requestNotificationsPermission();
  }

  static void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  static void scheduleAppointment({
    required String id,
    required String userId,
    required String day,
    required String time,
    required String title,
    required String body,
    String type = 'appointment',
  }) {
    final appointmentDate = _nextDateForDayAndTime(day: day, time: time);

    if (appointmentDate == null) {
      print('FAILED TO PARSE APPOINTMENT: $day $time');
      return;
    }

    final now = DateTime.now();

    // 1) Reminder before 5 minutes
    final reminderTime = appointmentDate.subtract(const Duration(minutes: 5));
    final reminderDelay = reminderTime.difference(now);

    if (!reminderDelay.isNegative) {
      _timers['$id-reminder']?.cancel();

      print(
        'APPOINTMENT 5 MIN REMINDER SCHEDULED AFTER: ${reminderDelay.inMinutes} min',
      );

      _timers['$id-reminder'] = Timer(reminderDelay, () async {
        final reminderTitle = title.contains('Doctor')
            ? 'Doctor appointment reminder'
            : title.contains('Nutritionist')
            ? 'Nutritionist appointment reminder'
            : 'Appointment reminder';

        final reminderBody = body.replaceAll(
          'is starting now.',
          'starts in 5 minutes.',
        );

        await _saveFirestoreNotification(
          userId: userId,
          title: reminderTitle,
          body: reminderBody,
          type: '${type}_reminder_5_min',
        );

        await _showLocalNotification(
          id: '$id-reminder',
          title: reminderTitle,
          body: reminderBody,
        );
      });
    } else {
      print('5 MIN REMINDER TIME PASSED FOR: $day $time');
    }

    // 2) Notification at appointment time
    final appointmentDelay = appointmentDate.difference(now);

    if (!appointmentDelay.isNegative) {
      _timers['$id-now']?.cancel();

      print(
        'APPOINTMENT NOW NOTIFICATION SCHEDULED AFTER: ${appointmentDelay.inMinutes} min',
      );

      _timers['$id-now'] = Timer(appointmentDelay, () async {
        await _saveFirestoreNotification(
          userId: userId,
          title: title,
          body: body,
          type: '${type}_now',
        );

        await _showLocalNotification(id: '$id-now', title: title, body: body);
      });
    } else {
      print('APPOINTMENT TIME PASSED: $day $time');
    }
  }

  static Future<void> _saveFirestoreNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
          'title': title,
          'body': body,
          'type': type,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  static Future<void> _showLocalNotification({
    required String id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id.hashCode.abs() % 2147483647,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'appointment_channel',
          'Appointment Reminders',
          channelDescription:
              'Reminders for doctor and nutritionist appointments',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );
  }

  static DateTime? _nextDateForDayAndTime({
    required String day,
    required String time,
  }) {
    final now = DateTime.now();

    final targetWeekday = _weekdayNumber(day);
    if (targetWeekday == null) return null;

    final parsedTime = _parseTime(time);
    if (parsedTime == null) return null;

    int daysToAdd = targetWeekday - now.weekday;

    if (daysToAdd < 0) {
      daysToAdd += 7;
    }

    DateTime result = DateTime(
      now.year,
      now.month,
      now.day,
      parsedTime.hour,
      parsedTime.minute,
    ).add(Duration(days: daysToAdd));

    if (!result.isAfter(now)) {
      result = result.add(const Duration(days: 7));
    }

    return result;
  }

  static int? _weekdayNumber(String day) {
    final cleaned = day.trim().toLowerCase();

    switch (cleaned) {
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

  static _ParsedTime? _parseTime(String input) {
    final cleaned = input.trim().toUpperCase();

    final isPm = cleaned.contains('PM');
    final isAm = cleaned.contains('AM');

    final timeOnly = cleaned.replaceAll('AM', '').replaceAll('PM', '').trim();

    final parts = timeOnly.split(':');

    if (parts.length < 2) return null;

    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    if (isPm && hour != 12) {
      hour += 12;
    }

    if (isAm && hour == 12) {
      hour = 0;
    }

    return _ParsedTime(hour, minute);
  }
}

class _ParsedTime {
  final int hour;
  final int minute;

  _ParsedTime(this.hour, this.minute);
}
