import 'package:alignme/pages/home_root.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // ✅ ثابت لكل الأجهزة: UTC+2 = 120 دقيقة
  // إذا بدك تغيّريه: مثلا UTC+3 => 180
  static const int _fixedOffsetMinutes = 120;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
                  IconButton(onPressed: (){
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainShell()),
                    );
                  }, icon: Icon(Icons.arrow_back)),
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

            // ===== Firestore Stream =====
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Notifications')
                    .orderBy('Timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
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
                      final data = docs[index].data() as Map<String, dynamic>;

                      final message = data['reason'] ?? 'Posture alert';

                      final Timestamp? ts =
                      data['Timestamp'] is Timestamp ? data['Timestamp'] : null;

                      return _notifCard(
                        context,
                        message: message,
                        time: ts != null ? _formatTimeFixed(ts) : '--',
                        date: ts != null ? _formatDateFixed(ts) : '--',
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
      }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: colors.onPrimary),
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
  // ✅ Time formatting ثابت على كل الأجهزة
  // مثال: إذا وصل "6:49:30 PM UTC+2" -> يطبع "6:49"
  // =========================

  String _pad2(int n) => n.toString().padLeft(2, '0');

  DateTime _timestampAsUtc(Timestamp ts) {
    // مهم: isUtc:true عشان ما يتأثر بتوقيت الجهاز
    return DateTime.fromMillisecondsSinceEpoch(
      ts.millisecondsSinceEpoch,
      isUtc: true,
    );
  }

  DateTime _applyFixedOffset(DateTime utc) {
    return utc.add(Duration(minutes: _fixedOffsetMinutes));
  }

  String _formatTimeFixed(Timestamp ts) {
    final fixed = _applyFixedOffset(_timestampAsUtc(ts));

    // 12-hour بدون AM/PM: 6:49
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
