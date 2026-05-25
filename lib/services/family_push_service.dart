import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'family_api.dart';

class FamilyPushService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initForFamily(String familyUserId) async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(initSettings);

    const normalChannel = AndroidNotificationChannel(
      'family_alert_channel',
      'Family Alerts',
      description: 'Normal alerts for family members',
      importance: Importance.high,
      playSound: true,
    );

    const criticalChannel = AndroidNotificationChannel(
      'critical_family_channel',
      'Critical Family Alerts',
      description: 'Critical alerts for dangerous glucose or missed insulin',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('critical_alarm'),
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(normalChannel);
    await androidPlugin?.createNotificationChannel(criticalChannel);

    final token = await _messaging.getToken();

    if (token != null && token.isNotEmpty) {
      await FamilyApi.saveFcmToken(userId: familyUserId, token: token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await FamilyApi.saveFcmToken(userId: familyUserId, token: newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      final severity = data['severity']?.toString() ?? 'normal';

      final title =
          message.notification?.title ?? data['title']?.toString() ?? 'Alert';

      final body = message.notification?.body ?? data['body']?.toString() ?? '';

      final isCritical = severity == 'critical';

      final androidDetails = AndroidNotificationDetails(
        isCritical ? 'critical_family_channel' : 'family_alert_channel',
        isCritical ? 'Critical Family Alerts' : 'Family Alerts',
        channelDescription: isCritical
            ? 'Critical alerts for dangerous glucose or missed insulin'
            : 'Normal alerts for family members',
        importance: isCritical ? Importance.max : Importance.high,
        priority: isCritical ? Priority.max : Priority.high,
        playSound: true,
        sound: isCritical
            ? const RawResourceAndroidNotificationSound('critical_alarm')
            : null,
        fullScreenIntent: isCritical,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(android: androidDetails),
      );
    });
  }
}
