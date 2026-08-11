import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../services/audio_service.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/purchase_service.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/ads_cubit.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/coin_flight_animation.dart';
import '../../../../shared/widgets/confetti_burst.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../domain/coin_pack.dart';
import '../widgets/coin_pack_card.dart';
import '../widgets/remove_ads_card.dart';
import '../widgets/watch_ad_card.dart';

/// Shop screen: watch a (simulated) rewarded ad for free coins, buy coin
/// packs, or remove ads.
///
/// Coin packs and Remove Ads go through [PurchaseService]. When RevenueCat
/// is configured (production), purchases are real store transactions; when
/// it isn't (dev/web/tests), the page degrades to the old local simulation
/// so the game stays fully playable without credentials.
class ShopPage extends StatefulWidget {
  const ShopPage({super.key, PurchaseService? purchaseService})
    : _purchaseService = purchaseService;

  /// Defaults to the real RevenueCat-backed service; tests inject fakes.
  final PurchaseService? _purchaseService;

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  /// Landmark for the coin flight animation's target: the wallet chip.
  final GlobalKey _walletKey = GlobalKey();

  /// One landmark per pack card, so coins burst from the card the player
  /// actually tapped.
  final Map<String, GlobalKey> _packKeys = {
    for (final pack in coinPacks) pack.id: GlobalKey(),
  };

  PurchaseService get _service =>
      widget._purchaseService ?? RevenueCatPurchaseService();

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
                _ShopTopBar(walletKey: _walletKey),
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
                        for (final pack in coinPacks) ...[
                            CoinPackCard(
                              key: _packKeys[pack.id],
                              pack: pack,
                              onPurchase: () => _buyCoinPack(context, pack),
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
                            onPurchase: () => _buyRemoveAds(context),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Cosmetics',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GameCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: InkWell(
                            onTap: () =>
                                context.goNamed(RouteNames.cosmetics),
                            borderRadius: AppRadius.mdRadius,
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: AppRadius.mdRadius,
                                  ),
                                  child: const Icon(
                                    Icons.palette_rounded,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Cosmetics',
                                        style: textTheme.titleMedium?.copyWith(
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      Text(
                                        'Frames, piece styles & avatars',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
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

  /// Buys a coin pack. With RevenueCat configured this is a real store
  /// transaction; coins are granted exactly once, right after success.
  /// Without it (dev/web/tests) the purchase is simulated locally.
  Future<void> _buyCoinPack(BuildContext context, CoinPack pack) async {
    if (await _service.isAvailable) {
      final result = await _service.purchaseCoinPack(pack);
      if (!context.mounted) return;
      switch (result.outcome) {
        case PurchaseOutcome.success:
          break; // grant below
        case PurchaseOutcome.cancelled:
          return; // user backed out — no message needed
        case PurchaseOutcome.unavailable:
        case PurchaseOutcome.failed:
          _showMessage(context, 'Could not complete purchase — try again');
          return;
      }
    } else {
      // Dev/web fallback: no store configured, simulate like before.
      AnalyticsService().logEvent(
        AnalyticsService.coinPackPurchased,
        parameters: {
          'pack_id': pack.id,
          'coins': pack.coins,
          'price': pack.priceLabel,
          'method': 'simulated',
        },
      );
    }

    if (!mounted) return;
    context.read<WalletCubit>().addCoins(pack.coins);

    // Celebration: coins burst from the tapped pack and fly into the
    // wallet chip, then a confirmation dialog pops over the landing.
    CoinFlightOverlay.show(
      context: context,
      startKey: _packKeys[pack.id],
      endKey: _walletKey,
      count: 24,
    );
    _showPurchaseDialog(context, pack);
  }

  /// Buys the Remove Ads entitlement, then mirrors it into local state so
  /// every ad placement respects it. Dev/web falls back to local grant.
  Future<void> _buyRemoveAds(BuildContext context) async {
    if (await _service.isAvailable) {
      final result = await _service.purchaseRemoveAds();
      if (!context.mounted) return;
      switch (result.outcome) {
        case PurchaseOutcome.success:
          break; // grant below
        case PurchaseOutcome.cancelled:
          return;
        case PurchaseOutcome.unavailable:
        case PurchaseOutcome.failed:
          _showMessage(context, 'Could not complete purchase — try again');
          return;
      }
    }

    if (!context.mounted) return;
    context.read<AdsCubit>().purchaseRemoveAds();
    AudioService().playCoinReward();
    _showMessage(context, 'Remove Ads activated!');
  }

  void _showEarnedSnackBar(BuildContext context, int coins) {
    _showMessage(context, '+$coins coins!');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// Confirmation dialog after a successful coin pack purchase: a burst
  /// of confetti behind a game-styled card with the granted amount.
  void _showPurchaseDialog(BuildContext context, CoinPack pack) {
    final textTheme = Theme.of(context).textTheme;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: AppRadius.xlRadius,
          child: SizedBox(
            width: 330,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: IgnorePointer(child: ConfettiBurst()),
                ),
                BounceIn(
                  child: GameCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.5),
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.monetization_on_rounded,
                            color: AppColors.accent,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Purchase Complete!',
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '+${formatThousands(pack.coins)} Coins',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Added to your wallet — thanks for supporting\nPuzzle Cards!',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        GameButton(
                          label: 'Awesome!',
                          icon: Icons.celebration_rounded,
                          width: double.infinity,
                          onTap: () => Navigator.of(dialogContext).pop(),
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
}

class _ShopTopBar extends StatelessWidget {
  const _ShopTopBar({required this.walletKey});

  /// Landmark for coin-flight animations to fly coins into the chip.
  final GlobalKey walletKey;

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
            key: walletKey,
            icon: Icons.monetization_on_rounded,
            value: formatThousands(coins),
            iconColor: AppColors.accent,
          ),
        ),
      ],
    );
  }
}
