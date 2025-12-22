import 'package:alignme/pages/home/notification_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LastPostureAlertCard extends StatelessWidget {
  const LastPostureAlertCard({super.key});

  // ===== ICON BASED ON REASON =====
  String _getPostureIconFromReason(String reason) {
    final r = reason.toLowerCase();

    if (r.contains('neck') && r.contains('left')) {
      print("hello");
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
    return " ";
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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Notifications')
          .orderBy('Timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final doc = snapshot.data!.docs.first;
        final reason = doc['reason'] as String;
        final timestamp = (doc['Timestamp'] as Timestamp).toDate();

        return GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationPage(),
              ),
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
                  height: 48
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
                        reason,
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
