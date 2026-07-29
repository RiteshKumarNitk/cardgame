// Verifies the Victory screen renders level info, stars, stats, and the
// Next Level CTA when given a result — and falls back gracefully with no
// crash when opened without one.
//
// Note: ConfettiBurst plays a one-shot (non-repeating) animation, so
// unlike the continuously-animating Flame backgrounds, a normal pump is
// enough here — no pumpAndSettle-hangs-forever concern.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/levels/domain/entities/level.dart';
import 'package:puzzle_cards/features/victory/domain/entities/victory_result.dart';
import 'package:puzzle_cards/features/victory/presentation/pages/victory_page.dart';

const _level = Level(
  id: 1,
  title: 'Level 1',
  difficulty: LevelDifficulty.easy,
  stars: 0,
  isCompleted: false,
  isUnlocked: true,
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows level info, time, moves, and a Next Level button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.game,
        home: const VictoryPage(
          result: VictoryResult(
            level: _level,
            stars: 3,
            moves: 12,
            timeSeconds: 75,
            coinsEarned: 60,
            nextLevelId: 2,
          ),
        ),
      ),
    );
    // _VictoryContent stacks several staggered BounceIn reveals (up to
    // 600ms of delay); advance past all of them so their Future.delayed
    // Timers fire before the test ends (otherwise: leaked pending Timer).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Level Complete!'), findsOneWidget);
    expect(find.textContaining('Level 1'), findsOneWidget);
    expect(find.text('01:15'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('+60'), findsOneWidget);
    expect(find.text('Next Level'), findsOneWidget);
  });

  testWidgets('shows a completion message instead of Next Level when there is no next level', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.game,
        home: const VictoryPage(
          result: VictoryResult(
            level: _level,
            stars: 1,
            moves: 30,
            timeSeconds: 10,
            coinsEarned: 20,
            nextLevelId: null,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Next Level'), findsNothing);
    expect(find.text('You\'ve completed every level!'), findsOneWidget);
  });

  testWidgets('falls back gracefully with no result', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.game, home: const VictoryPage()),
    );
    await tester.pump();

    expect(find.text('No level result to show.'), findsOneWidget);
  });
}
