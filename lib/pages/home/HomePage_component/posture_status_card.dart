import 'package:flutter/material.dart';

class PostureStatusCard extends StatelessWidget {
  final bool isGood;

  const PostureStatusCard({
    super.key,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final bg = isGood ? colors.secondaryContainer : colors.errorContainer;
    final fg = isGood ? colors.onSecondaryContainer : colors.onErrorContainer;
    final icon = isGood ? Icons.check_circle_rounded : Icons.warning_amber_rounded;
    final text = isGood ? 'Posture: Good' : 'Posture: Bad';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            'auto',
            style: TextStyle(
              color: fg.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
