import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';

/// A simulated rewarded-ad placement: no real ad network is wired up, so
/// "watching" is a short timed placeholder — but the reward it grants
/// (via [onRewardEarned]) is real.
class WatchAdCard extends StatefulWidget {
  const WatchAdCard({
    super.key,
    required this.rewardCoins,
    required this.onRewardEarned,
  });

  final int rewardCoins;
  final VoidCallback onRewardEarned;

  @override
  State<WatchAdCard> createState() => _WatchAdCardState();
}

class _WatchAdCardState extends State<WatchAdCard> {
  bool _watching = false;

  Future<void> _watchAd() async {
    setState(() => _watching = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _watching = false);
    widget.onRewardEarned();
  }

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
              color: AppColors.secondary.withValues(alpha: 0.14),
              borderRadius: AppRadius.mdRadius,
            ),
            child: const Icon(
              Icons.play_circle_fill_rounded,
              color: AppColors.secondary,
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
                  'Free Coins',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'Watch a short ad for +${widget.rewardCoins} coins',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (_watching)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.secondary,
                ),
              ),
            )
          else
            GameButton(
              label: 'Watch Ad',
              icon: Icons.play_arrow_rounded,
              variant: GameButtonVariant.secondary,
              width: 130,
              height: 44,
              onTap: _watchAd,
            ),
        ],
      ),
    );
  }
}
