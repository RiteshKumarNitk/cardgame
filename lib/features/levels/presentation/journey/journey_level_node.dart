import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_shadows.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../../../shared/widgets/pulsing_glow.dart';
import '../../domain/entities/level.dart';
import '../widgets/level_difficulty_style.dart';

/// Horizontal wave position for a level's node on the path, in `[-1, 1]`
/// (feed straight into an `Alignment`). Purely a function of the level id,
/// so neighboring nodes/segments can compute each other's position without
/// sharing state.
double journeyWavePosition(int levelId) => math.sin(levelId * 0.9);

/// One level's node on the Journey Map: locked (grey, lock icon),
/// completed (green ring, checkmark, stars), or unlocked-not-yet-completed
/// (difficulty-colored, level number). The current level additionally gets
/// a [PulsingGlow] and a larger size to draw the eye.
///
/// Named `LevelNodeCircle` (not `JourneyLevelNode`) to avoid colliding with
/// the `JourneyLevelNode` data item in `journey_item.dart`.
class LevelNodeCircle extends StatelessWidget {
  const LevelNodeCircle({
    super.key,
    required this.level,
    required this.isCurrent,
    this.onTap,
  });

  final Level level;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unlocked = level.isUnlocked;
    final completed = level.isCompleted;
    final diameter = isCurrent ? 76.0 : 64.0;

    final circle = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: unlocked
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  level.difficulty.color,
                  level.difficulty.color.withValues(alpha: 0.7),
                ],
              )
            : null,
        color: unlocked ? null : AppColors.card,
        border: Border.all(
          color: completed
              ? AppColors.success
              : isCurrent
              ? AppColors.primary
              : AppColors.border,
          width: isCurrent ? 3 : 2,
        ),
        boxShadow: unlocked
            ? AppShadows.glow(level.difficulty.color, opacity: 0.35)
            : AppShadows.card,
      ),
      child: Center(
        child: completed
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 30)
            : unlocked
            ? Text(
                '${level.id}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              )
            : const Icon(
                Icons.lock_rounded,
                color: AppColors.textSecondary,
                size: 26,
              ),
      ),
    );

    final glowed = isCurrent
        ? PulsingGlow(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(diameter / 2),
            child: circle,
          )
        : circle;

    final withStars = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        glowed,
        if (completed) ...[
          const SizedBox(height: AppSpacing.xs),
          _StarsRow(stars: level.stars),
        ],
      ],
    );

    if (!unlocked || onTap == null) {
      return Semantics(label: 'Level ${level.id}, locked', child: withStars);
    }
    return PressScale(onTap: onTap!, child: withStars);
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final filled = index < stars;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: 14,
          color: filled ? AppColors.accent : AppColors.textSecondary,
        );
      }),
    );
  }
}
