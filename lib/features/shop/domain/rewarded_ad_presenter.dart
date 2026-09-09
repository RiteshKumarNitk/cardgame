import 'package:flutter/foundation.dart';

import '../../../services/ad_service.dart';

/// Presents a Google rewarded ad and reports the outcome. An interface
/// (rather than calling [AdService] directly from the widget) so the Shop
/// is testable without the Google Mobile Ads SDK.
abstract interface class RewardedAdPresenter {
  /// Whether an ad is preloaded and can be shown immediately.
  bool get isReady;

  /// Requests a preload if none is ready/in-flight. Safe to call again.
  void preload();

  /// Shows a rewarded ad (loading first if needed). Exactly one path runs:
  ///  * [onReward] then [onClosed] — the user earned the reward
  ///  * [onClosed] alone           — dismissed without a reward
  ///  * [onUnavailable]            — no ad could be loaded/shown
  void watch({
    required VoidCallback onReward,
    required VoidCallback onUnavailable,
    required VoidCallback onClosed,
  });
}

/// The real presenter — delegates to the app's single [AdService].
class AdServiceRewardedAdPresenter implements RewardedAdPresenter {
  const AdServiceRewardedAdPresenter();

  @override
  bool get isReady => AdService().isRewardedAdReady;

  @override
  void preload() => AdService().loadRewardedAd();

  @override
  void watch({
    required VoidCallback onReward,
    required VoidCallback onUnavailable,
    required VoidCallback onClosed,
  }) {
    AdService().watchRewardedAd(
      onReward: onReward,
      onUnavailable: onUnavailable,
      onClosed: onClosed,
    );
  }
}
