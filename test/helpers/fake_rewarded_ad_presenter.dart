import 'package:flutter/foundation.dart';

import 'package:puzzle_cards/features/shop/domain/rewarded_ad_presenter.dart';

/// Deterministic [RewardedAdPresenter] for widget tests — no Google SDK.
///
/// [outcome] decides what a `watch()` call does:
///  * [FakeAdOutcome.reward]      → onReward() then onClosed()
///  * [FakeAdOutcome.dismissed]   → onClosed() only (no reward)
///  * [FakeAdOutcome.unavailable] → onUnavailable()
class FakeRewardedAdPresenter implements RewardedAdPresenter {
  FakeRewardedAdPresenter({
    this.outcome = FakeAdOutcome.reward,
    this.ready = true,
    this.rewardCallbacksPerWatch = 1,
  });

  FakeAdOutcome outcome;
  bool ready;

  /// Simulate a misbehaving SDK firing `onUserEarnedReward` more than once
  /// for a single ad — the card must still grant only one reward.
  int rewardCallbacksPerWatch;

  int preloadCalls = 0;
  int watchCalls = 0;

  @override
  bool get isReady => ready;

  @override
  void preload() => preloadCalls++;

  @override
  void watch({
    required VoidCallback onReward,
    required VoidCallback onUnavailable,
    required VoidCallback onClosed,
  }) {
    watchCalls++;
    switch (outcome) {
      case FakeAdOutcome.reward:
        for (var i = 0; i < rewardCallbacksPerWatch; i++) {
          onReward();
        }
        onClosed();
      case FakeAdOutcome.dismissed:
        onClosed();
      case FakeAdOutcome.unavailable:
        onUnavailable();
    }
  }
}

enum FakeAdOutcome { reward, dismissed, unavailable }
