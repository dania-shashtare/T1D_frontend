import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

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

    // 1) سجل إن المريض أخذ اللانتوس اليوم
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

    // 2) خلي كل إشعارات اللانتوس القديمة مقروءة
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
    ).showSnackBar(const SnackBar(content: Text('Lantus marked as taken.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xff42A5F5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xffEAF6FF),
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
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(fontSize: 16, color: Colors.black54),
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
                  color: isRead ? Colors.white : const Color(0xffDFF1FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xffCFE5F8)),
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff17466E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            body,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xff587A9F),
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
                              label: const Text('I took Lantus'),
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
                              child: const Text('Mark as read'),
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
    );
  }
}
