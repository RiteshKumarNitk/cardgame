import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/utils/duration_format.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/difficulty_badge.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../../levels/domain/entities/level.dart';

/// Puzzle screen's top bar: back button, level title + difficulty badge,
/// pause button, and a row of timer/moves/hint stats.
class PuzzleTopBar extends StatelessWidget {
  const PuzzleTopBar({
    super.key,
    required this.level,
    required this.elapsedSeconds,
    required this.moves,
    required this.onBack,
    required this.onPause,
  });

  final Level level;
  final int elapsedSeconds;
  final int moves;
  final VoidCallback onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          children: [
            CircleIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    level.title,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DifficultyBadge(difficulty: level.difficulty),
                ],
              ),
            ),
            CircleIconButton(
              icon: Icons.pause_rounded,
              iconColor: AppColors.textSecondary,
              onTap: onPause,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Center(
                child: StatChip(
                  icon: Icons.timer_rounded,
                  value: formatMinutesSeconds(elapsedSeconds),
                  iconColor: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Center(
                child: StatChip(
                  icon: Icons.touch_app_rounded,
                  value: '$moves',
                  iconColor: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Center(
                child: StatChip(
                  icon: Icons.lightbulb_rounded,
                  value: '5',
                  iconColor: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
