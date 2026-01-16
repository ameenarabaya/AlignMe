import 'package:alignme/pages/home_root.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // ✅ ثابت لكل الأجهزة: UTC+2 = 120 دقيقة
  static const int _fixedOffsetMinutes = 120;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ===== Header =====
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MainShell()),
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    'Notifications',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // ===== If not logged in =====
            if (uid == null)
              const Expanded(
                child: Center(child: Text('Please login again')),
              )
            else
            // ===== Firestore Stream (ONLY this user) =====
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Notifications') // ✅ نفس الاسم عندك (N كبيرة)
                      .where('userId', isEqualTo: uid)
                      .orderBy('Timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    // ✅ أهم إضافة: عرض سبب المشكلة بدل ما يبين "فاضي"
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Firestore error:\n${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No notifications yet'));
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final message = (data['reason'] ?? 'Posture alert').toString();
                        final bool isRead = (data['read'] == true);

                        // ✅ نفس الحقل عندك بالصورة: Timestamp (T كبيرة)
                        final Timestamp? ts =
                        data['Timestamp'] is Timestamp ? data['Timestamp'] as Timestamp : null;

                        return GestureDetector(
                          onTap: () async {
                            // ✅ Mark as read when user taps it
                            if (!isRead) {
                              await FirebaseFirestore.instance
                                  .collection('Notifications')
                                  .doc(doc.id)
                                  .update({'read': true});
                            }
                          },
                          child: _notifCard(
                            context,
                            message: message,
                            time: ts != null ? _formatTimeFixed(ts) : '--',
                            date: ts != null ? _formatDateFixed(ts) : '--',
                            isRead: isRead,
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
    );
  }

  // ===== Notification Card =====
  Widget _notifCard(
      BuildContext context, {
        required String message,
        required String time,
        required String date,
        required bool isRead,
      }) {
    final colors = Theme.of(context).colorScheme;

    final baseColor = colors.primary;
    final bgColor = isRead ? baseColor.withOpacity(0.6) : baseColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            isRead ? Icons.notifications : Icons.notification_important,
            size: 20,
            color: colors.onPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.onPrimary,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  color: colors.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  color: colors.onPrimary.withOpacity(0.8),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // ✅ Time formatting ثابت على كل الأجهزة (UTC + fixed offset)
  // =========================

  String _pad2(int n) => n.toString().padLeft(2, '0');

  DateTime _timestampAsUtc(Timestamp ts) {
    return DateTime.fromMillisecondsSinceEpoch(
      ts.millisecondsSinceEpoch,
      isUtc: true,
    );
  }

  DateTime _applyFixedOffset(DateTime utc) {
    return utc.add(const Duration(minutes: _fixedOffsetMinutes));
  }

  String _formatTimeFixed(Timestamp ts) {
    final fixed = _applyFixedOffset(_timestampAsUtc(ts));

    int h = fixed.hour % 12;
    if (h == 0) h = 12;

    return '$h:${_pad2(fixed.minute)}';
  }

  String _formatDateFixed(Timestamp ts) {
    final fixed = _applyFixedOffset(_timestampAsUtc(ts));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${_pad2(fixed.day)} ${months[fixed.month - 1]} ${fixed.year}';
  }
}
