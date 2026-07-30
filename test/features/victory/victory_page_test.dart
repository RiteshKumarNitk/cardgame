// Verifies the Victory screen renders level info, stars, stats, and the
// Next Level CTA when given a result — and falls back gracefully with no
// crash when opened without one.
//
// Timer management: VictoryPage has a Future.delayed(400ms) in initState
// and BounceIn widgets have staggered delays (600–2050ms). The tests
// pump step-by-step through all timer deadlines so none leak past the
// widget tree disposal.
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

/// Advances past all staggered BounceIn delays (max ~2050ms) plus the
/// VictoryPage's own Future.delayed(400ms) so no pending Timers remain.
Future<void> _flushTimers(WidgetTester tester) async {
  // Pump frame to trigger initState delays
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500)); // past VictoryPage's 400ms
  await tester.pump(const Duration(milliseconds: 500)); // past BounceIn 600-1100ms
  await tester.pump(const Duration(milliseconds: 500)); // past BounceIn 1600ms
  await tester.pump(const Duration(milliseconds: 600)); // past longest BounceIn 2050ms
}

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
    await _flushTimers(tester);

    expect(find.text('Puzzle Complete!'), findsOneWidget);
    expect(find.textContaining('Level 1'), findsOneWidget);
    expect(find.text('01:15'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('+60'), findsAtLeastNWidgets(1));
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
    await _flushTimers(tester);

    expect(find.text('Next Level'), findsNothing);
    expect(find.text('All Levels Complete!'), findsOneWidget);
  });

  testWidgets('falls back gracefully with no result', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.game, home: const VictoryPage()),
    );
    await _flushTimers(tester);

    expect(find.text('No level result to show.'), findsOneWidget);
  });
}
