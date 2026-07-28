// Verifies the Puzzle screen shell renders for a valid level: title,
// difficulty badge, and the right number of board slots / tray pieces.
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

  testWidgets('shows level title, difficulty, and a 3x3 board/tray for easy', (
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
    expect(find.text('Pieces'), findsOneWidget);
    // A 3x3 board for easy: 9 empty slots, plus 9 tray piece cards showing
    // indices 1-9 (each index rendered once, in board+tray combined we
    // only assert the tray pieces since board slots carry no text).
    expect(find.text('9'), findsOneWidget);

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
