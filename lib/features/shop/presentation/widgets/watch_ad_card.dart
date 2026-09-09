import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../domain/rewarded_ad_presenter.dart';

/// "Free Coins" — watch a **real** Google rewarded ad for coins.
///
/// Flow: tap → button shows a loading state → the rewarded ad is shown
/// (loaded first if it wasn't preloaded) → on a valid `onUserEarnedReward`
/// the reward is granted via [onRewardEarned] → brief success state →
/// back to ready. Coins are awarded **only** on the reward callback, never
/// on tap / start / dismiss / failure. Repeated taps while busy are
/// ignored, so a reward can't be granted twice.
class WatchAdCard extends StatefulWidget {
  const WatchAdCard({
    super.key,
    required this.rewardCoins,
    required this.onRewardEarned,
    this.onUnavailable,
    this.presenter,
  });

  final int rewardCoins;

  /// Called exactly once per completed ad, from the reward callback.
  final VoidCallback onRewardEarned;

  /// Called when no ad could be loaded/shown, so the caller can surface a
  /// concise message. The button returns to its ready state either way.
  final VoidCallback? onUnavailable;

  /// Injectable for tests; defaults to the real [AdService]-backed one.
  final RewardedAdPresenter? presenter;

  @override
  State<WatchAdCard> createState() => _WatchAdCardState();
}

enum _AdBtn { ready, loading, rewarded }

class _WatchAdCardState extends State<WatchAdCard> {
  late final RewardedAdPresenter _presenter;
  _AdBtn _state = _AdBtn.ready;

  /// Guards against a second reward within one watch (belt-and-braces on
  /// top of the tap guard).
  bool _rewardedThisRun = false;

  @override
  void initState() {
    super.initState();
    _presenter = widget.presenter ?? const AdServiceRewardedAdPresenter();
    // Preload once so the first tap can show immediately. NOT in build()
    // — a Shop rebuild must not kick another request.
    _presenter.preload();
  }

  void _watch() {
    if (_state != _AdBtn.ready) return; // ignore rapid / repeat taps
    setState(() {
      _state = _AdBtn.loading;
      _rewardedThisRun = false;
    });
    _presenter.watch(
      onReward: _onReward,
      onUnavailable: _onUnavailable,
      onClosed: _onClosed,
    );
  }

  void _onReward() {
    if (!mounted || _rewardedThisRun) return;
    _rewardedThisRun = true;
    widget.onRewardEarned();
    setState(() => _state = _AdBtn.rewarded);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _state == _AdBtn.rewarded) {
        setState(() => _state = _AdBtn.ready);
      }
    });
  }

  void _onClosed() {
    if (!mounted) return;
    // If the reward already landed we're in the brief "rewarded" state —
    // let its timer reset us. Otherwise the user dismissed early: ready.
    if (_state != _AdBtn.rewarded) setState(() => _state = _AdBtn.ready);
  }

  void _onUnavailable() {
    if (!mounted) return;
    setState(() => _state = _AdBtn.ready);
    widget.onUnavailable?.call();
  }

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
              color: AppColors.primaryContainer.withValues(alpha: 0.14),
              borderRadius: AppRadius.smRadius,
            ),
            child: const Icon(
              Icons.play_circle_fill_rounded,
              color: AppColors.primaryContainer,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Free Coins',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'Watch a short ad for +${widget.rewardCoins} coins',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _button(textTheme),
        ],
      ),
    );
  }

  Widget _button(TextTheme textTheme) {
    switch (_state) {
      case _AdBtn.loading:
        return const SizedBox(
          width: 96,
          height: 40,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryContainer,
              ),
            ),
          ),
        );
      case _AdBtn.rewarded:
        return Container(
          width: 96,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.14),
            borderRadius: AppRadius.pillRadius,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 20,
          ),
        );
      case _AdBtn.ready:
        return GameButton(
          label: 'Watch Ad',
          variant: GameButtonVariant.secondary,
          width: 96,
          height: 40,
          onTap: _watch,
        );
    }
  }
}
