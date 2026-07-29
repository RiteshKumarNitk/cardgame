import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/utils/duration_format.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/difficulty_badge.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../../levels/domain/entities/level.dart';

/// Puzzle screen's top bar: a single compact row — back, difficulty,
/// timer, moves, pause — so the board below gets as much of the screen
/// as possible.
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
    return Row(
      children: [
        CircleIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        const SizedBox(width: AppSpacing.sm),
        DifficultyBadge(difficulty: level.difficulty),
        const Spacer(),
        StatChip(
          icon: Icons.timer_rounded,
          value: formatMinutesSeconds(elapsedSeconds),
          iconColor: AppColors.secondary,
        ),
        const SizedBox(width: AppSpacing.xs),
        StatChip(
          icon: Icons.touch_app_rounded,
          value: '$moves',
          iconColor: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        CircleIconButton(
          icon: Icons.pause_rounded,
          iconColor: AppColors.textSecondary,
          onTap: onPause,
        ),
      ],
    );
  }
}
