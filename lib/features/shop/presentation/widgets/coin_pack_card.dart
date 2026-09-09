import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../domain/coin_pack.dart';

/// One coin bundle in the Shop — a clean, uniform row: a coin-icon tile,
/// the coin amount, and a price button. Every card is the same height with
/// the same internal spacing, so the amounts and price buttons line up
/// down the list. No promotional badges — packs are just listed clearly.
///
/// Purchases go through the Shop's existing `PurchaseService` flow via
/// [onPurchase]; this widget is presentation only.
class CoinPackCard extends StatelessWidget {
  const CoinPackCard({super.key, required this.pack, required this.onPurchase});

  final CoinPack pack;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GameCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: AppRadius.smRadius,
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: AppColors.accent,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${formatThousands(pack.coins)} Coins',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(color: AppColors.textDark),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GameButton(
            label: pack.priceLabel,
            variant: GameButtonVariant.secondary,
            width: 96,
            height: 40,
            onTap: onPurchase,
          ),
        ],
      ),
    );
  }
}
