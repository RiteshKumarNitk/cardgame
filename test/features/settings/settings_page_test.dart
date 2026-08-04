// Verifies the Settings screen: renders the toggles/about section,
// toggling a switch persists through the repository, and Reset Progress
// requires confirmation before actually resetting level progress.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/levels/domain/entities/level.dart';
import 'package:puzzle_cards/features/levels/domain/repositories/levels_repository.dart';
import 'package:puzzle_cards/features/levels/domain/services/level_service.dart';
import 'package:puzzle_cards/features/settings/domain/entities/app_settings.dart';
import 'package:puzzle_cards/features/settings/domain/repositories/settings_repository.dart';
import 'package:puzzle_cards/features/settings/presentation/pages/settings_page.dart';

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings stored = const AppSettings();

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async {
    stored = settings;
  }
}

class _FakeLevelsRepository implements LevelsRepository {
  List<Level> stored = [
    const Level(
      id: 1,
      title: 'Level 1',
      difficulty: LevelDifficulty.easy,
      stars: 3,
      isCompleted: true,
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

  testWidgets('shows toggles and the about section', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.game,
        home: SettingsPage(
          settingsRepository: _FakeSettingsRepository(),
          levelService: LevelService(_FakeLevelsRepository()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Sound Effects'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(2));
    expect(find.text('v1.0.0'), findsOneWidget);
  });

  testWidgets('toggling sound flips the switch and persists', (tester) async {
    final settingsRepository = _FakeSettingsRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.game,
        home: SettingsPage(
          settingsRepository: settingsRepository,
          levelService: LevelService(_FakeLevelsRepository()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final soundSwitch = find.byType(Switch).first;
    expect(tester.widget<Switch>(soundSwitch).value, isTrue);

    await tester.tap(soundSwitch);
    await tester.pump();

    expect(tester.widget<Switch>(soundSwitch).value, isFalse);
    expect(settingsRepository.stored.soundEnabled, isFalse);
  });

  testWidgets(
    'reset progress requires confirmation, then resets level progress',
    (tester) async {
      final levelsRepository = _FakeLevelsRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.game,
          home: SettingsPage(
            settingsRepository: _FakeSettingsRepository(),
            levelService: LevelService(levelsRepository),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Reset'));
      await tester.pump();

      expect(find.text('Reset all progress?'), findsOneWidget);
      // The confirm dialog's own button shares the row title's label, so
      // target the most recently added (topmost/dialog) match.
      await tester.tap(find.text('Reset Progress').last);
      await tester.pump();
      await tester.pump();

      final resetLevel = levelsRepository.stored.firstWhere((l) => l.id == 1);
      expect(resetLevel.isCompleted, isFalse);
      expect(resetLevel.stars, 0);
    },
  );
}
