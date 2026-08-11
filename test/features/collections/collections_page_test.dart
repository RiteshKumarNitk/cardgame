// Verifies the Collections Showcase: renders the chapter cards with
// themed artwork + progress, and tapping a card opens the chapter detail
// sheet with a play shortcut.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/collections/presentation/pages/collections_page.dart';
import 'package:puzzle_cards/features/levels/domain/entities/level.dart';
import 'package:puzzle_cards/features/levels/domain/repositories/levels_repository.dart';
import 'package:puzzle_cards/features/levels/domain/services/demo_levels_generator.dart';
import 'package:puzzle_cards/features/levels/domain/services/level_service.dart';

class _FakeLevelsRepository implements LevelsRepository {
  _FakeLevelsRepository() {
    stored = generateLevelCatalog();
    // Progress: level 1 complete (3 stars), level 2 unlocked.
    stored[0] = stored[0].copyWith(
      isCompleted: true,
      isUnlocked: true,
      stars: 3,
    );
    stored[1] = stored[1].copyWith(isUnlocked: true);
  }

  late List<Level> stored;

  @override
  Future<List<Level>> loadLevels() async => List.of(stored);

  @override
  Future<void> saveLevels(List<Level> levels) async {
    stored = List.of(levels);
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders chapter cards with progress', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.game,
        home: CollectionsPage(levelService: LevelService(_FakeLevelsRepository())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Collections'), findsOneWidget);
    // Chapter 1 card: name + piece progress.
    expect(find.text('The Beginning'), findsOneWidget);
    expect(find.text('Chapter 1'), findsOneWidget);
    expect(find.text('1/60'), findsOneWidget);
  });

  testWidgets('tapping a chapter card opens the detail sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.game,
        home: CollectionsPage(levelService: LevelService(_FakeLevelsRepository())),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.text('The Beginning'));
    await tester.pump();
    await tester.tap(find.text('The Beginning'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('1 / 60 pieces'), findsOneWidget);
    // Level 1 is complete and level 2 is unlocked -> keep playing level 2.
    expect(find.text('Keep Playing · Level 2'), findsOneWidget);
    expect(find.text('View Journey Map'), findsOneWidget);
  });
}
