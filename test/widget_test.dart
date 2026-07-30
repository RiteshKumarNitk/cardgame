// Basic smoke test verifying the app boots, shows the splash content, then
// auto-navigates to Home.
//
// Notes:
// - pumpAndSettle() is avoided throughout: both Splash and Home host a
//   continuously-animating Flame GameWidget, so frames never stop being
//   scheduled and pumpAndSettle would hang.
// - The splash schedules a 2-second delayed navigation, and Home's menu
//   items schedule staggered entrance-animation delays (BounceIn). The
//   test advances virtual time past all of that so those Timers fire and
//   don't leak past the end of the test (which flutter_test treats as a
//   failure).
// - The Home screen calls LevelService which depends on Hive. Since tests
//   do not initialize Hive, we only verify the splash screen and basic
//   navigation — not the full Home page content.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import 'package:puzzle_cards/core/app/puzzle_cards_app.dart';
import 'package:puzzle_cards/core/constants/app_constants.dart';
import 'package:puzzle_cards/features/levels/data/models/level_model.dart';
import 'package:puzzle_cards/features/splash/presentation/pages/splash_page.dart';
import 'package:puzzle_cards/game/ads_cubit.dart';
import 'package:puzzle_cards/game/wallet_cubit.dart';

import 'helpers/fake_ads_service.dart';
import 'helpers/fake_wallet_service.dart';

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;

    // Initialize Hive with a temp directory so the Home page's
    // LevelService (which reads from Hive) doesn't crash.
    hiveDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(hiveDir.path);
    Hive.registerAdapter(LevelModelAdapter());
    await Hive.openBox<LevelModel>(AppConstants.levelsBoxName);
    await Hive.openBox<int>(AppConstants.walletBoxName);
    await Hive.openBox(AppConstants.dailyChallengeBoxName);
    await Hive.openBox(AppConstants.monetizationBoxName);
    await Hive.openBox(AppConstants.settingsBoxName);
  });

  tearDownAll(() {
    // Best-effort cleanup — closing Hive can hang on Windows, and the
    // OS temp cleaner will eventually remove any leftover directories.
    try {
      hiveDir.deleteSync(recursive: true);
    } on FileSystemException {
      // File still locked by Hive — harmless.
    }
  });

  testWidgets('App boots and shows splash content before navigating to Home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      PuzzleCardsApp(
        walletCubit: WalletCubit(FakeWalletService()),
        adsCubit: AdsCubit(FakeAdsService()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Splash screen: logo + app name
    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.text('Puzzle Cards'), findsOneWidget);

    // Advance past splash's 2s delay so the Timer fires cleanly
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 50));

    // Home screen mounts and starts async _loadProgress. Pump to flush
    // microtasks so the async chain (Hive read → generate → setState)
    // can complete and render the hero card with "Continue".
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Splash screen must be gone — confirms navigation fired. (Home also
    // shows the same logo mark in its top bar, so checking for the splash
    // page itself rather than the shared icon is what actually proves we
    // navigated away.)
    expect(find.byType(SplashPage), findsNothing);

    // Home screen: static elements that render regardless of async state
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    expect(find.byIcon(Icons.storefront_rounded), findsAtLeastNWidgets(1));
    expect(find.text('Daily Challenge'), findsOneWidget);
    // Once async loading completes, the Continue button and chapter info
    // appear. The StatChip with coin count also renders.
    expect(find.text('Journey'), findsWidgets);
    expect(find.text('Shop'), findsWidgets);
  });
}
