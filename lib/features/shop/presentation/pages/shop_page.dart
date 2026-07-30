import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../services/audio_service.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/ads_cubit.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../domain/coin_pack.dart';
import '../widgets/coin_pack_card.dart';
import '../widgets/remove_ads_card.dart';
import '../widgets/watch_ad_card.dart';

/// Shop screen: watch a (simulated) rewarded ad for free coins, buy coin
/// packs, or remove ads — all backed by the real wallet/ads entitlement,
/// see [CoinPack] and `AdsService` for the "no real store" caveat.
class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: GameBackground(
        showFloatingPieces: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _ShopTopBar(),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Free Coins',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        WatchAdCard(
                          rewardCoins: 25,
                          onRewardEarned: () {
                            context.read<WalletCubit>().addCoins(25);
                            AudioService().playCoinReward();
                            _showEarnedSnackBar(context, 25);
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Coin Packs',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (final pack in coinPacks) ...[                            CoinPackCard(
                            pack: pack,
                            onPurchase: () {
                              context.read<WalletCubit>().addCoins(
                                pack.coins,
                              );
                              AudioService().playCoinReward();
                              _showEarnedSnackBar(context, pack.coins);
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Remove Ads',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        BlocBuilder<AdsCubit, bool>(
                          builder: (context, adsRemoved) => RemoveAdsCard(
                            owned: adsRemoved,
                            onPurchase: () =>
                                context.read<AdsCubit>().purchaseRemoveAds(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEarnedSnackBar(BuildContext context, int coins) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('+$coins coins!'), duration: const Duration(seconds: 2)),
    );
  }
}

class _ShopTopBar extends StatelessWidget {
  const _ShopTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            // Shop is always reached via `goNamed`, which replaces the
            // stack rather than pushing — so there's usually nothing to
            // pop back to; fall back to Home in that case.
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteNames.home);
            }
          },
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'Shop',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textDark),
          ),
        ),
        BlocBuilder<WalletCubit, int>(
          builder: (context, coins) => StatChip(
            icon: Icons.monetization_on_rounded,
            value: formatThousands(coins),
            iconColor: AppColors.accent,
          ),
        ),
      ],
    );
  }
}
