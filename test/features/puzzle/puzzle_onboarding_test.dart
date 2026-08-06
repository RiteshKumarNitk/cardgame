// The one-time How-to-Play tutorial: appears over the first loaded puzzle,
// is dismissed by "Got it!", and never appears again (persisted flag).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import 'package:puzzle_cards/core/constants/app_constants.dart';
import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/levels/domain/entities/level.dart';
import 'package:puzzle_cards/features/levels/domain/repositories/levels_repository.dart';
import 'package:puzzle_cards/features/levels/domain/services/demo_levels_generator.dart';
import 'package:puzzle_cards/features/levels/domain/services/level_service.dart';
import 'package:puzzle_cards/features/puzzle/presentation/pages/puzzle_page.dart';
import 'package:puzzle_cards/game/onboarding_service.dart';
import 'package:puzzle_cards/game/wallet_cubit.dart';

import '../../helpers/fake_wallet_service.dart';

class _FakeLevelsRepository implements LevelsRepository {
  List<Level> stored = generateLevelCatalog();

  @override
  Future<List<Level>> loadLevels() async => List.of(stored);

  @override
  Future<void> saveLevels(List<Level> levels) async {
    stored = List.of(levels);
  }
}

void main() {
  late Directory hiveDir;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    hiveDir = Directory.systemTemp.createTempSync('hive_onboarding_widget_');
    Hive.init(hiveDir.path);
  });

  setUp(() async {
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

  testWidgets('tutorial shows on first puzzle and is dismissed once', (
    tester,
  ) async {
    final levelService = LevelService(_FakeLevelsRepository());

    await tester.pumpWidget(
      BlocProvider<WalletCubit>(
        create: (_) => WalletCubit(FakeWalletService()),
        child: MaterialApp(
          theme: AppTheme.game,
          home: PuzzlePage(levelId: '1', levelService: levelService),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Tutorial overlay covers the fresh board.
    expect(find.text('How to Play'), findsOneWidget);
    expect(find.text('Drag to swap'), findsOneWidget);

    await tester.tap(find.text('Got it!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Overlay gone, flag persisted.
    expect(find.text('How to Play'), findsNothing);
    expect(OnboardingService().shouldShowTutorial(), isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tutorial does not show once already seen', (tester) async {
    // Fire-and-forget on purpose: Hive.put applies to the in-memory cache
    // synchronously, and awaiting real disk I/O never completes inside a
    // testWidgets (fake-async) zone.
    OnboardingService().markTutorialSeen();
    final levelService = LevelService(_FakeLevelsRepository());

    await tester.pumpWidget(
      BlocProvider<WalletCubit>(
        create: (_) => WalletCubit(FakeWalletService()),
        child: MaterialApp(
          theme: AppTheme.game,
          home: PuzzlePage(levelId: '1', levelService: levelService),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('How to Play'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
