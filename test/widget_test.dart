// Basic smoke test verifying the app boots, shows the splash content, then
// auto-navigates to Home.
//
// Notes:
// - pumpAndSettle() is avoided throughout: both Splash and Home host a
//   continuously-animating Flame GameWidget, so frames never stop being
//   scheduled and pumpAndSettle would hang.
// - The splash schedules a 2-second delayed navigation, and Home's menu
//   tiles schedule staggered entrance-animation delays (BounceIn). The
//   test advances virtual time past all of that so those Timers fire and
//   don't leak past the end of the test (which flutter_test treats as a
//   failure).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/app/puzzle_cards_app.dart';
import 'package:puzzle_cards/game/ads_cubit.dart';
import 'package:puzzle_cards/game/wallet_cubit.dart';

import 'helpers/fake_ads_service.dart';
import 'helpers/fake_wallet_service.dart';

void main() {
  setUpAll(() {
    // Prevent GoogleFonts from trying to fetch font files over the
    // network during tests; it falls back to the platform default font.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App boots, shows splash, then navigates to Home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      PuzzleCardsApp(
        walletCubit: WalletCubit(FakeWalletService()),
        adsCubit: AdsCubit(FakeAdsService()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.extension_rounded), findsOneWidget);
    expect(find.text('Puzzle Cards'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Continue Game'), findsOneWidget);
    expect(find.text('Daily Challenge'), findsOneWidget);
  });
}
