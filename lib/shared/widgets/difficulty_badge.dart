import 'package:flutter/material.dart';

import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../features/levels/domain/entities/level.dart';
import '../../features/levels/presentation/widgets/level_difficulty_style.dart';

/// Small colored pill showing a level's difficulty tier — used on Level
/// Selection tiles and the Puzzle top bar wherever a level's difficulty
/// needs a quick visual read.
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.difficulty});

  final LevelDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: difficulty.color,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        difficulty.label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: Colors.white),
      ),
    );
  }
}
