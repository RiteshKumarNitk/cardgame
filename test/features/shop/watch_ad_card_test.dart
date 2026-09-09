// Focused tests for WatchAdCard's rewarded-ad flow — no Google SDK.
// Covers: preload on mount (not on rebuild), reward callback fires the
// grant exactly once, duplicate-tap protection, unavailable handling, and
// the button state machine (ready → loading/rewarded → ready).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/shop/presentation/widgets/watch_ad_card.dart';

import '../../helpers/fake_rewarded_ad_presenter.dart';

Widget _host({
  required FakeRewardedAdPresenter ads,
  required VoidCallback onReward,
  VoidCallback? onUnavailable,
}) {
  return MaterialApp(
    theme: AppTheme.game,
    home: Scaffold(
      body: Center(
        child: WatchAdCard(
          rewardCoins: 25,
          presenter: ads,
          onRewardEarned: onReward,
          onUnavailable: onUnavailable,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('preloads once on mount, not on rebuild', (tester) async {
    final ads = FakeRewardedAdPresenter();
    await tester.pumpWidget(_host(ads: ads, onReward: () {}));
    await tester.pump();
    expect(ads.preloadCalls, 1);

    await tester.pump(); // rebuild
    expect(ads.preloadCalls, 1);
  });

  testWidgets('reward callback grants exactly once', (tester) async {
    var grants = 0;
    final ads = FakeRewardedAdPresenter(outcome: FakeAdOutcome.reward);
    await tester.pumpWidget(_host(ads: ads, onReward: () => grants++));
    await tester.pump();

    await tester.tap(find.text('Watch Ad'));
    await tester.pump();
    expect(grants, 1);

    // Brief success state shows a check, then returns to the button.
    expect(find.text('Watch Ad'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('Watch Ad'), findsOneWidget);
  });

  testWidgets('a duplicated reward callback still grants only once', (
    tester,
  ) async {
    var grants = 0;
    final ads = FakeRewardedAdPresenter(
      outcome: FakeAdOutcome.reward,
      rewardCallbacksPerWatch: 3, // misbehaving SDK
    );
    await tester.pumpWidget(_host(ads: ads, onReward: () => grants++));
    await tester.pump();

    await tester.tap(find.text('Watch Ad'));
    await tester.pump();

    expect(grants, 1);
    expect(ads.watchCalls, 1);

    await tester.pump(const Duration(milliseconds: 1500)); // flush reset timer
  });

  testWidgets('unavailable returns to ready and notifies the caller', (
    tester,
  ) async {
    var grants = 0;
    var unavailable = 0;
    final ads = FakeRewardedAdPresenter(outcome: FakeAdOutcome.unavailable);
    await tester.pumpWidget(
      _host(
        ads: ads,
        onReward: () => grants++,
        onUnavailable: () => unavailable++,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Watch Ad'));
    await tester.pump();

    expect(grants, 0);
    expect(unavailable, 1);
    expect(find.text('Watch Ad'), findsOneWidget);
  });
}
