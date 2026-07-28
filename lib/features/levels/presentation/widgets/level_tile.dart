import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../domain/entities/level.dart';
import 'level_difficulty_style.dart';

/// One tile in the Level Selection grid: level number, stars earned,
/// locked/unlocked state, a highlight for the current level, a completed
/// badge, and a difficulty-colored background.
class LevelTile extends StatelessWidget {
  const LevelTile({
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

    final content = Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdRadius,
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
          color: isCurrent ? AppColors.primary : AppColors.border,
          width: isCurrent ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: unlocked
                ? level.difficulty.color.withValues(alpha: 0.4)
                : AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: unlocked
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${level.id}',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _StarsRow(stars: level.stars),
                    ],
                  )
                : const Icon(
                    Icons.lock_rounded,
                    color: AppColors.textSecondary,
                    size: 28,
                  ),
          ),
          if (level.isCompleted)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
        ],
      ),
    );

    if (!unlocked || onTap == null) {
      return Semantics(label: 'Level ${level.id}, locked', child: content);
    }
    return PressScale(onTap: onTap!, child: content);
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
          color: filled ? AppColors.accent : Colors.white70,
        );
      }),
    );
  }
}
