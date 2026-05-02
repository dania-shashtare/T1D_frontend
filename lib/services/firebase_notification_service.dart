import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await _requestPermission();
    await _initLocalNotifications();
    await _setupForegroundListener();
  }

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _localNotifications.initialize(settings);
  }

  static Future<void> _setupForegroundListener() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;

      if (notification != null) {
        const androidDetails = AndroidNotificationDetails(
          'patient_notifications',
          'Patient Notifications',
          channelDescription: 'Notifications for patient reminders and alerts',
          importance: Importance.max,
          priority: Priority.high,
        );

        const details = NotificationDetails(android: androidDetails);

        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          details,
          payload: jsonEncode(message.data),
        );
      }
    });
  }

  static Future<void> saveUserToken(String userId) async {
    final token = await _messaging.getToken();

    if (token == null) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  static Future<void> saveNotificationToFirestore({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
          'title': title,
          'body': body,
          'type': type,
          'data': data ?? {},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}
