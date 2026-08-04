// Unit tests for the achievements feature: catalog progress rules,
// event-driven unlocking, and reward payout signals.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/features/achievements/domain/services/achievement_catalog.dart';
import 'package:puzzle_cards/features/achievements/presentation/bloc/achievements_cubit.dart';
import 'package:puzzle_cards/features/achievements/presentation/bloc/achievements_state.dart';

import '../../helpers/fake_achievements_repository.dart';

void main() {
  group('AchievementCatalog.progressFor', () {
    test('starts every achievement at zero progress', () {
      final progress = AchievementCatalog.progressFor({});

      expect(progress, hasLength(AchievementCatalog.achievements.length));
      expect(progress.where((p) => p.isUnlocked), isEmpty);
      expect(progress.first.current, 0);
    });

    test('clamps current progress at the goal', () {
      final progress = AchievementCatalog.progressFor({
        AchievementCatalog.counterPuzzles: 500,
      });
      final first = progress.firstWhere(
        (p) => p.achievement.counterKey == AchievementCatalog.counterPuzzles,
      );
      expect(first.current, first.achievement.goal);
      expect(first.isUnlocked, isTrue);
      expect(first.fraction, 1.0);
    });

    test('flags are single-shot counters', () {
      final progress = AchievementCatalog.progressFor({
        AchievementCatalog.flagPerfect: 1,
      });
      final perfect = progress.firstWhere(
        (p) => p.achievement.id == 'perfect_3',
      );
      expect(perfect.isUnlocked, isTrue);
    });
  });

  group('AchievementsCubit', () {
    test('load() emits the catalog without unlocking anything', () async {
      final cubit = AchievementsCubit(FakeAchievementsRepository());
      await cubit.load();

      final state = cubit.state as AchievementsLoaded;
      expect(state.items, hasLength(AchievementCatalog.achievements.length));
      expect(state.justUnlocked, isEmpty);
      await cubit.close();
    });

    test('puzzle completion counts puzzles and stars', () async {
      final repository = FakeAchievementsRepository();
      final cubit = AchievementsCubit(repository);
      await cubit.load();

      await cubit.onPuzzleCompleted(stars: 2, timeSeconds: 90);

      var state = cubit.state as AchievementsLoaded;
      expect(
        repository.counters[AchievementCatalog.counterPuzzles],
        1,
      );
      expect(repository.counters[AchievementCatalog.counterStars], 2);

      // 1 puzzle done + 2 stars: only "First Steps" unlocks.
      final unlocked = state.items.where((p) => p.isUnlocked).toList();
      expect(unlocked.map((p) => p.achievement.id), ['first_puzzle']);
      expect(
        state.justUnlocked.map((a) => a.id),
        ['first_puzzle'],
      );
      expect(repository.unlockedIds, {'first_puzzle'});

      // A second event must not re-report already-unlocked achievements.
      await cubit.onPuzzleCompleted(stars: 3, timeSeconds: 40);
      state = cubit.state as AchievementsLoaded;
      expect(state.justUnlocked.map((a) => a.id).toSet(), {
        'perfect_3',
        'speed_demon',
      });
      expect(repository.unlockedIds, {
        'first_puzzle',
        'perfect_3',
        'speed_demon',
      });
      await cubit.close();
    });

    test('daily completion records the best streak', () async {
      final repository = FakeAchievementsRepository();
      final cubit = AchievementsCubit(repository);
      await cubit.load();

      await cubit.onDailyChallengeCompleted(2);
      await cubit.onDailyChallengeCompleted(4);

      expect(
        repository.counters[AchievementCatalog.counterBestStreak],
        4,
      );
      final state = cubit.state as AchievementsLoaded;
      expect(state.justUnlocked.map((a) => a.id), ['streak_3']);
      await cubit.close();
    });

    test('three-star perfect run unlocks the perfectionist flag', () async {
      final cubit = AchievementsCubit(FakeAchievementsRepository());
      await cubit.load();

      await cubit.onPuzzleCompleted(stars: 3, timeSeconds: 30);

      final state = cubit.state as AchievementsLoaded;
      expect(
        state.justUnlocked.map((a) => a.id).toSet(),
        {'first_puzzle', 'perfect_3', 'speed_demon'},
      );
      await cubit.close();
    });
  });
}