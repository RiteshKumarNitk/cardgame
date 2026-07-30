import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../shared/widgets/bounce_in.dart';

/// The interactive widget for each level on the Journey Map.
class LevelNodeCard extends StatelessWidget {
  const LevelNodeCard({
    super.key,
    required this.levelNumber,
    required this.isLocked,
    required this.isCompleted,
    required this.stars,
    required this.onTap,
  });

  final int levelNumber;
  final bool isLocked;
  final bool isCompleted;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Current level is neither locked nor completed
    final isCurrent = !isLocked && !isCompleted;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: BounceIn(
        delay: Duration.zero,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.success
                : isCurrent
                    ? AppColors.premiumGradientStart
                    : AppColors.border,
            border: Border.all(
              color: Colors.white,
              width: isCurrent ? 4 : 2,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.premiumGradientStart.withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 4,
                    )
                  ]
                : [],
          ),
          child: Center(
            child: isLocked
                ? const Icon(Icons.lock_rounded, color: Colors.white, size: 28)
                : Text(
                    '$levelNumber',
                    style: AppTypography.textTheme().titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
          ),
        ),
      ),
    );
  }
}
