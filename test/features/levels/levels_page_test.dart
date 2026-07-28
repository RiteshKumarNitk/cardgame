// Verifies the Level Selection grid renders: level 1 unlocked, everything
// else locked, and 0% progress on a fresh (seeded) set of demo levels.
//
// Uses an in-memory fake LevelsLocalDataSource rather than real Hive: real
// disk I/O inside a widget test proved fragile here (async completion
// timing was unreliable, and a later Hive.close() hung indefinitely) —
// an in-memory fake sidesteps that entirely and is the standard approach
// for widget tests anyway. LevelsRepositoryImpl/LevelService wrap it just
// like production code does; only the bottom (Hive) layer is faked.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/levels/data/datasources/levels_local_datasource.dart';
import 'package:puzzle_cards/features/levels/data/models/level_model.dart';
import 'package:puzzle_cards/features/levels/data/repositories/levels_repository_impl.dart';
import 'package:puzzle_cards/features/levels/domain/services/level_service.dart';
import 'package:puzzle_cards/features/levels/presentation/pages/levels_page.dart';

class _FakeLevelsLocalDataSource implements LevelsLocalDataSource {
  final List<LevelModel> _stored = [];

  @override
  Future<List<LevelModel>> loadLevels() async => List.of(_stored);

  @override
  Future<void> saveLevels(List<LevelModel> levels) async {
    _stored
      ..clear()
      ..addAll(levels);
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows level 1 unlocked, later levels locked, 0% progress', (
    tester,
  ) async {
    final levelService = LevelService(
      LevelsRepositoryImpl(_FakeLevelsLocalDataSource()),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.game,
        home: LevelsPage(levelService: levelService),
      ),
    );
    // Avoid pumpAndSettle: the brief Loading state shows an indeterminate
    // CircularProgressIndicator, which animates forever and would make
    // pumpAndSettle hang. A couple of plain pumps are enough to flush the
    // in-memory seed and land on the Loaded state.
    await tester.pump();
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
    expect(find.text('0%'), findsOneWidget);
  });
}
