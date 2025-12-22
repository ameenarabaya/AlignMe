import 'package:alignme/pages/home/exercises_page.dart';
import 'package:alignme/pages/home/HomePage_component/home_page.dart';
import 'package:alignme/pages/home/notification_page.dart';
import 'package:alignme/pages/home/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // ✅ Mark all notifications as read
  Future<void> _markAllNotificationsAsRead() async {
    final unread = await FirebaseFirestore.instance
        .collection('Notifications')
        .where('read', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      await doc.reference.update({'read': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            HomePage(),
            NotificationPage(),
            ExercisesPage(),
            Profile(),
          ],
        ),
      ),

      // ===== Bottom Navigation with unread counter =====
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Notifications')
              .where('read', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final notifCount =
            snapshot.hasData ? snapshot.data!.docs.length : 0;

            return _bottomNav(context, notifCount);
          },
        ),
      ),
    );
  }

  // ===== Bottom Nav =====
  Widget _bottomNav(BuildContext context, int notifCount) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(context, index: 0, icon: Icons.home, label: 'Home'),
          _navItem(
            context,
            index: 1,
            icon: Icons.notifications_none,
            label: 'Notification',
            badge: notifCount,
          ),
          _navItem(
            context,
            index: 2,
            icon: Icons.fitness_center,
            label: 'Exercises',
          ),
          _navItem(
            context,
            index: 3,
            icon: Icons.person_outline,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ===== Nav Item =====
  Widget _navItem(
      BuildContext context, {
        required int index,
        required IconData icon,
        required String label,
        int? badge,
      }) {
    final colors = Theme.of(context).colorScheme;
    final selected = _selectedIndex == index;

    final iconColor = selected ? colors.primary : colors.onSurfaceVariant;
    final textColor = selected ? colors.primary : colors.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(18),

      // ✅ هنا التعديل المهم
      onTap: () async {
        setState(() => _selectedIndex = index);

        // إذا فتح تب الإشعارات → خليهم مقروءين
        if (index == 1) {
          await _markAllNotificationsAsRead();
        }
      },

      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: iconColor),
                if (badge != null && badge > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$badge',
                        style: TextStyle(
                          color: colors.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
