import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../domain/coin_pack.dart';

/// One coin bundle in the Shop. Tapping the price "purchases" it — there's
/// no real store integration, so it just credits the wallet directly (see
/// [CoinPack]'s doc comment).
class CoinPackCard extends StatelessWidget {
  const CoinPackCard({super.key, required this.pack, required this.onPurchase});

  final CoinPack pack;
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
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: AppRadius.mdRadius,
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: AppColors.accent,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '${formatThousands(pack.coins)} Coins',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (pack.bestValue) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      'BEST VALUE',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GameButton(
            label: pack.priceLabel,
            variant: GameButtonVariant.secondary,
            width: 96,
            height: 44,
            onTap: onPurchase,
          ),
        ],
      ),
    );
  }
}
