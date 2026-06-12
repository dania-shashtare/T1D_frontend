import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_settings_provider.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'notifications': 'Notifications',
      'noNotifications': 'No notifications yet',
      'lantusTaken': 'Lantus marked as taken.',
      'iTookLantus': 'I took Lantus',
      'markAsRead': 'Mark as read',
    },
    'ar': {
      'notifications': 'الإشعارات',
      'noNotifications': 'لا توجد إشعارات بعد',
      'lantusTaken': 'تم تسجيل أخذ جرعة اللانتوس.',
      'iTookLantus': 'أخذت اللانتوس',
      'markAsRead': 'تحديد كمقروء',
    },
  };

  String t(BuildContext context, String key) {
    final lang = context.watch<AppSettingsProvider>().language;
    return _strings[lang]?[key] ?? _strings['en']?[key] ?? key;
  }

  bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  bool isArabic(BuildContext context) {
    return context.watch<AppSettingsProvider>().language == 'ar';
  }

  TextDirection direction(BuildContext context) {
    return isArabic(context) ? TextDirection.rtl : TextDirection.ltr;
  }

  Color pageBg(BuildContext context) {
    return isDark(context) ? const Color(0xff071A2F) : const Color(0xffEAF6FF);
  }

  Color appBarColor(BuildContext context) {
    return isDark(context) ? const Color(0xff102A46) : const Color(0xff42A5F5);
  }

  Color cardColor(BuildContext context, bool isRead) {
    if (isDark(context)) {
      return isRead ? const Color(0xff102A46) : const Color(0xff183A5C);
    }

    return isRead ? Colors.white : const Color(0xffDFF1FF);
  }

  Color borderColor(BuildContext context) {
    return isDark(context)
        ? Colors.white.withOpacity(0.08)
        : const Color(0xffCFE5F8);
  }

  Color titleColor(BuildContext context) {
    return isDark(context) ? Colors.white : const Color(0xff17466E);
  }

  Color bodyColor(BuildContext context) {
    return isDark(context) ? const Color(0xffAFC7DD) : const Color(0xff587A9F);
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  bool _isLantusNotification(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final title = data['title']?.toString().toLowerCase() ?? '';

    return type == 'lantus' ||
        type == 'lantus_reminder_again' ||
        title.contains('lantus');
  }

  Future<void> _markAsRead(DocumentReference ref) async {
    await ref.update({'isRead': true});
  }

  Future<void> _confirmLantusTaken({
    required BuildContext context,
    required DocumentReference notificationRef,
  }) async {
    final todayKey = _todayKey();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('daily_lantus')
        .doc(todayKey)
        .set({
          'taken': true,
          'takenAt': FieldValue.serverTimestamp(),
          'date': todayKey,
        }, SetOptions(merge: true));

    final lantusNotifications = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in lantusNotifications.docs) {
      final data = doc.data();

      if (_isLantusNotification(data)) {
        batch.update(doc.reference, {
          'isRead': true,
          'takenConfirmed': true,
          'takenConfirmedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t(context, 'lantusTaken'))));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: direction(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(t(context, 'notifications')),
          backgroundColor: appBarColor(context),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: pageBg(context),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  t(context, 'noNotifications'),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark(context) ? Colors.white70 : Colors.black54,
                  ),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                final title = data['title']?.toString() ?? '';
                final body = data['body']?.toString() ?? '';
                final isRead = data['isRead'] == true;
                final isLantus = _isLantusNotification(data);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor(context, isRead),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor(context)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.transparent : Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: titleColor(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              body,
                              style: TextStyle(
                                fontSize: 13,
                                color: bodyColor(context),
                              ),
                            ),
                            const SizedBox(height: 10),

                            if (isLantus && !isRead)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await _confirmLantusTaken(
                                    context: context,
                                    notificationRef: doc.reference,
                                  );
                                },
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                ),
                                label: Text(t(context, 'iTookLantus')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff185FA5),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              )
                            else if (!isRead)
                              TextButton(
                                onPressed: () async {
                                  await _markAsRead(doc.reference);
                                },
                                child: Text(t(context, 'markAsRead')),
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
    );
  }
}
