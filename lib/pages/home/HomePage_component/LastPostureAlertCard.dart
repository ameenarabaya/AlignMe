import 'package:alignme/pages/home/notification_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LastPostureAlertCard extends StatelessWidget {
  const LastPostureAlertCard({super.key});

  // ===== ICON BASED ON REASON =====
  String _getPostureIconFromReason(String reason) {
    final r = reason.toLowerCase();

    if (r.contains('neck') && r.contains('left')) {
      return 'assets/images/neck_tilt_left.png';
    }
    if (r.contains('neck') && r.contains('right')) {
      return 'assets/images/neck_tilt_right.png';
    }
    if (r.contains('lower back') && r.contains('not touching')) {
      return 'assets/images/lower_back_not_supported.png';
    }
    if (r.contains('upper back') && r.contains('not straight')) {
      return 'assets/images/upper_back_leaning.png';
    }
    if (r.contains('legs')) {
      return 'assets/images/cross_legs.png';
    }

    // ✅ مهم: رجّعي أيقونة افتراضية بدل " " عشان Image.asset ما يكسر
    return 'assets/images/upper_back_leaning.png';
  }

  // ===== TIME AGO FORMAT =====
  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return DateFormat('dd MMM, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox(); // مش مسجل دخول

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Notifications')
          .where('userId', isEqualTo: uid) // ✅ فلترة لليوزر الحالي
          .orderBy('Timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // ✅ لو طلع Index ناقص رح يبين هون
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Firestore error:\n${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(); // ما نعرض loading هون عشان كارد صغير
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;

        final reason = (data['reason'] ?? '').toString();

        final ts = data['Timestamp'];
        if (ts is! Timestamp) return const SizedBox();

        final timestamp = ts.toDate();

        return GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const NotificationPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== ICON =====
                Image.asset(
                  _getPostureIconFromReason(reason),
                  width: 48,
                  height: 48,
                ),

                const SizedBox(width: 16),

                // ===== TEXT =====
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last posture alert',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reason.isEmpty ? 'Posture alert' : reason,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _timeAgo(timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
