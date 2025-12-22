import 'package:flutter/material.dart';

class HomeHeaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Future<String> usernameFuture;

  const HomeHeaderAppBar({
    super.key,
    required this.usernameFuture,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppBar(
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      titleSpacing: 18,
      title: FutureBuilder<String>(
        future: usernameFuture,
        builder: (context, snapshot) {
          final name = snapshot.data ?? '...';
          return Row(
            children: [
              Text(
                'Hello $name ',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text('👋', style: TextStyle(fontSize: 18)),
            ],
          );
        },
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.person,
              color: colors.onPrimaryContainer,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
