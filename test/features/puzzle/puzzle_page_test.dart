// Verifies the Puzzle screen shell renders for a valid level: title,
// difficulty badge, and a fully-populated 3x3 board (every cell holds a
// piece from the start — there's no separate tray).
//
// Uses an in-memory fake LevelsRepository (via LevelService) rather than
// real Hive — same reasoning as the Levels feature tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/levels/domain/entities/level.dart';
import 'package:puzzle_cards/features/levels/domain/repositories/levels_repository.dart';
import 'package:puzzle_cards/features/levels/domain/services/level_service.dart';
import 'package:puzzle_cards/features/puzzle/presentation/pages/puzzle_page.dart';
import 'package:puzzle_cards/features/puzzle/presentation/widgets/puzzle_image_tile.dart';

class _FakeLevelsRepository implements LevelsRepository {
  List<Level> stored = [
    const Level(
      id: 1,
      title: 'Level 1',
      difficulty: LevelDifficulty.easy,
      stars: 0,
      isCompleted: false,
      isUnlocked: true,
    ),
  ];

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

  testWidgets('shows level title, difficulty, and a fully-populated 3x3 board', (
    tester,
  ) async {
    final levelService = LevelService(_FakeLevelsRepository());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.game,
        home: PuzzlePage(levelId: '1', levelService: levelService),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Reassemble this photo'), findsOneWidget);
    // A 3x3 board for easy: every one of the 9 cells always renders a
    // piece (locked or not), but exactly how many start locked depends
    // on the shuffle, so only the total tile count is asserted exactly.
    expect(find.byType(PuzzleImageTile), findsNWidgets(9));
    // At least the not-yet-correct cells should be interactive.
    expect(find.byType(DragTarget<int>), findsWidgets);

    // A loaded puzzle starts a repeating Timer (the elapsed-time clock).
    // Unmount to dispose the cubit (cancelling it) before the test ends —
    // otherwise flutter_test flags it as a leaked pending Timer.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows an error message for an unknown level id', (
    tester,
  ) async {
    final levelService = LevelService(_FakeLevelsRepository());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.game,
        home: PuzzlePage(levelId: '999', levelService: levelService),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Failed to load level'), findsOneWidget);
  });
}
