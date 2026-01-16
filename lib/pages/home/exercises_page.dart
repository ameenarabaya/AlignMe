import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExercisesPage extends StatelessWidget {
  const ExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Exercises',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: ListView(
          children: const [
            ExerciseCard(
              title: 'Neck exercises',
              imagePath: 'assets/images/neck.png',
              url: 'https://www.youtube.com/watch?v=Q12nIfVCpdU',
            ),
            SizedBox(height: 24),
            ExerciseCard(
              title: 'Back exercises',
              imagePath: 'assets/images/back-ex.png',
              url: 'https://www.youtube.com/watch?v=fDzJbizG0cQ',
            ),
            SizedBox(height: 24),
            ExerciseCard(
              title: 'Full body exercises',
              imagePath: 'assets/images/full-body.png',
              url: 'https://www.youtube.com/watch?v=tnZ96Y2C28Y',
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final String url;

  const ExerciseCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.url,
  });

  Future<void> _openLink() async {
    final uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _openLink,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
