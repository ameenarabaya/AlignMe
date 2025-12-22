import 'package:flutter/material.dart';

class PostureTipsSection extends StatefulWidget {
  const PostureTipsSection({super.key});

  @override
  State<PostureTipsSection> createState() => _PostureTipsSectionState();
}

class _PostureTipsSectionState extends State<PostureTipsSection> {
  int _selected = 0;
  late final PageController _pageController;

  final List<_Tip> _tips = const [
    _Tip(
      title: 'Back Support',
      body: 'Keep your back straight and supported by the chair. Avoid leaning forward.',
      icon: Icons.chair_alt_rounded,
    ),
    _Tip(
      title: 'Shoulders & Neck',
      body: 'Relax your shoulders, keep your neck neutral, and don’t bend your head down.',
      icon: Icons.accessibility_new_rounded,
    ),
    _Tip(
      title: 'Hips & Feet',
      body: 'Sit deep in the chair. Keep hips aligned and feet flat on the floor.',
      icon: Icons.directions_walk_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // viewportFraction عشان يبين جزء من الكارد اللي بعده (مبينات ورا بعض)
    _pageController = PageController(viewportFraction: 0.88, initialPage: _selected);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    setState(() => _selected = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Posture Tips',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),

        // ===== Cards (Horizontal / landscape) =====
        SizedBox(
          height: 125,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _tips.length,
            onPageChanged: (i) => setState(() => _selected = i),
            itemBuilder: (context, i) {
              final tip = _tips[i];
              final isActive = i == _selected;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  scale: isActive ? 1.0 : 0.97,
                  child: _TipCard(
                    index: i + 1,
                    total: _tips.length,
                    title: tip.title,
                    body: tip.body,
                    icon: tip.icon,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // ===== Small numbers UNDER the cards =====
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // ✅ هون
          children: List.generate(_tips.length, (i) {
            final selected = i == _selected;

            return Padding(
              padding: EdgeInsets.only(right: i == _tips.length - 1 ? 0 : 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _goTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? colors.primary : colors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected ? colors.primary : colors.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: selected ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _Tip {
  final String title;
  final String body;
  final IconData icon;

  const _Tip({
    required this.title,
    required this.body,
    required this.icon,
  });
}

class _TipCard extends StatelessWidget {
  final int index;
  final int total;
  final String title;
  final String body;
  final IconData icon;

  const _TipCard({
    super.key,
    required this.index,
    required this.total,
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.onPrimaryContainer, size: 22),
          ),
          const SizedBox(width: 12),

          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // small indicator "Tip 1/3"
                Text(
                  'Tip $index/$total',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.3,
                    color: colors.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
