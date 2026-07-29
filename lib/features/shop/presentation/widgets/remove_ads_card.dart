import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';

/// One-time "Remove Ads" purchase. Shows an "Owned" badge once bought
/// instead of the price button.
class RemoveAdsCard extends StatelessWidget {
  const RemoveAdsCard({
    super.key,
    required this.owned,
    required this.onPurchase,
  });

  final bool owned;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GameCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: AppRadius.mdRadius,
            ),
            child: const Icon(
              Icons.block_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Remove Ads',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'Enjoy uninterrupted play, forever',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (owned)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.14),
                borderRadius: AppRadius.pillRadius,
              ),
              child: Text(
                'Owned',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.success,
                ),
              ),
            )
          else
            GameButton(
              label: r'$2.99',
              variant: GameButtonVariant.premium,
              width: 96,
              height: 44,
              onTap: onPurchase,
            ),
        ],
      ),
    );
  }
}
