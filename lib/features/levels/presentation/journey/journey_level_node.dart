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

/// One level's node on the Journey Map — "Warm Tactile Serenity":
///  * locked   — soft sand disc + lock icon
///  * completed — soft-sage fill + white check + honey stars below
///  * unlocked  — difficulty-tinted disc + level number
///  * current   — larger ivory disc with a pulsing sage ring
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
    final diameter = isCurrent ? 76.0 : 62.0;
    final tint = level.difficulty.color;

    final Color fill;
    final Color borderColor;
    final double borderWidth;
    if (isCurrent) {
      fill = AppColors.background;
      borderColor = AppColors.primary;
      borderWidth = 2.5;
    } else if (completed) {
      fill = AppColors.primaryContainer;
      borderColor = Colors.white.withValues(alpha: 0.5);
      borderWidth = 1.5;
    } else if (unlocked) {
      fill = tint.withValues(alpha: 0.16);
      borderColor = tint;
      borderWidth = 1.5;
    } else {
      fill = AppColors.cardWellHigh;
      borderColor = AppColors.border;
      borderWidth = 1.5;
    }

    final circle = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: isCurrent ? null : AppShadows.pill,
      ),
      child: Center(
        child: completed
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 30)
            : unlocked
            ? Text(
                '${level.id}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isCurrent ? AppColors.primary : tint,
                  fontWeight: FontWeight.w800,
                ),
              )
            : Icon(
                Icons.lock_rounded,
                color: AppColors.textMeta,
                size: 24,
              ),
      ),
    );

    final glowed = isCurrent
        ? PulsingGlow(
            color: AppColors.primary,
            minOpacity: 0.16,
            maxOpacity: 0.5,
            blurRadius: 22,
            borderRadius: BorderRadius.circular(diameter / 2),
            child: circle,
          )
        : circle;

    final withStars = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        glowed,
        if (completed) ...[
          const SizedBox(height: AppSpacing.xxs),
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
          size: 12,
          color: filled ? AppColors.honey : AppColors.textMeta,
        );
      }),
    );
  }
}
