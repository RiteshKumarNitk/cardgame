// Verifies Home's double-back-to-exit: the first system back shows a hint
// instead of exiting, and a second one within the window attempts to leave
// (SystemNavigator.pop is a no-op test stub, so we assert it doesn't throw).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import 'package:puzzle_cards/core/constants/app_constants.dart';
import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/home/presentation/pages/home_page.dart';
import 'package:puzzle_cards/features/levels/data/models/level_model.dart';
import 'package:puzzle_cards/game/wallet_cubit.dart';

import '../../helpers/fake_wallet_service.dart';

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // HomePage builds its own Hive-backed LevelService / DailyRewardService,
    // so initialize Hive against a throwaway temp dir (same as widget_test).
    hiveDir = Directory.systemTemp.createTempSync('hive_home_test_');
    Hive.init(hiveDir.path);
    Hive.registerAdapter(LevelModelAdapter());
    await Hive.openBox<LevelModel>(AppConstants.levelsBoxName);
    await Hive.openBox<int>(AppConstants.walletBoxName);
    await Hive.openBox(AppConstants.dailyChallengeBoxName);
    await Hive.openBox(AppConstants.dailyRewardBoxName);
    await Hive.openBox(AppConstants.monetizationBoxName);
    await Hive.openBox(AppConstants.settingsBoxName);
    await Hive.openBox(AppConstants.achievementsBoxName);
    // Mark today's reward as claimed so _checkDailyReward skips its 800ms
    // bottom-sheet timer during the test.
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await Hive.box(AppConstants.dailyRewardBoxName)
        .put(AppConstants.dailyRewardLastClaimedKey, todayKey);
  });

  tearDownAll(() {
    try {
      Hive.close();
    } catch (_) {}
    try {
      hiveDir.deleteSync(recursive: true);
    } on FileSystemException {
      // File still locked by Hive - harmless.
    }
  });

  testWidgets('first system back shows a hint, second back attempts exit', (
    tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider<WalletCubit>(
        create: (_) => WalletCubit(FakeWalletService()),
        child: MaterialApp(theme: AppTheme.game, home: const HomePage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // First back: hint, not exit.
    final dynamic widgetsApp = tester.state(find.byType(WidgetsApp));
    await widgetsApp.didPopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Press back again to exit'), findsOneWidget);

    // Second back within the 2s window: system exit (a no-op in tests) —
    // must not crash and must not need the confirmation again.
    await widgetsApp.didPopRoute();
    await tester.pump();
    // Let the first snackbar's 2s duration timer fire before ending.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}