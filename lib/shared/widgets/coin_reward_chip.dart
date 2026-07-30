import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_shadows.dart';
import '../../core/design_system/app_spacing.dart';

/// A gold pill showing a coin reward (`+N`) — used wherever the player
/// just earned coins (Victory, Daily Challenge).
class CoinRewardChip extends StatelessWidget {
  const CoinRewardChip({super.key, required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.premiumGradientStart,
            AppColors.premiumGradientEnd,
          ],
        ),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: AppColors.outline, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          ...AppShadows.bevel(AppColors.premiumGradientEnd, depth: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '+$coins',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
