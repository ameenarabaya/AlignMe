import 'package:flutter/material.dart';

class HomeStatsRow extends StatelessWidget {
  final int good;
  final int bad;

  const HomeStatsRow({
    super.key,
    required this.good,
    required this.bad,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: _StatBox(title: 'Good Posture Per Day', value: good),
          ),
          const SizedBox(width: 26),
          SizedBox(
            width: 160,
            child: _StatBox(title: 'Bad Posture Per Day', value: bad),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final int value;

  const _StatBox({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 46,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.onSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
