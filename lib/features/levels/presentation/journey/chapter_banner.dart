import 'package:flutter/material.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../domain/entities/chapter.dart';
import '../widgets/level_difficulty_style.dart';

/// Full-width banner marking the start of a [Chapter] on the Journey Map:
/// chapter number, name, and a level-count/difficulty subtitle.
class ChapterBanner extends StatelessWidget {
  const ChapterBanner({super.key, required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: GameCard(
        borderRadius: AppRadius.xlRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            chapter.difficulty.color,
            chapter.difficulty.color.withValues(alpha: 0.75),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          children: [
            Text(
              'CHAPTER ${chapter.id}',
              style: textTheme.labelMedium?.copyWith(
                color: Colors.white70,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              chapter.name,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${chapter.levelCount} levels · ${chapter.difficulty.label}',
              style: textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
