// Unit tests for LevelService's business rules: seeding, unlocking the
// next level, completing a level (best-score keeping), and resetting
// progress. Pure Dart — no Flutter widgets, no Hive — backed by an
// in-memory fake LevelsRepository.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/features/levels/domain/entities/level.dart';
import 'package:puzzle_cards/features/levels/domain/repositories/levels_repository.dart';
import 'package:puzzle_cards/features/levels/domain/services/level_service.dart';

class _FakeLevelsRepository implements LevelsRepository {
  List<Level> stored = [];

  @override
  Future<List<Level>> loadLevels() async => List.of(stored);

  @override
  Future<void> saveLevels(List<Level> levels) async {
    stored = List.of(levels);
  }
}

void main() {
  group('loadLevels', () {
    test('seeds 100 demo levels with only level 1 unlocked when empty', () async {
      final repository = _FakeLevelsRepository();
      final service = LevelService(repository);

      final levels = await service.loadLevels();

      expect(levels, hasLength(100));
      expect(levels.first.isUnlocked, isTrue);
      expect(levels.skip(1).every((l) => !l.isUnlocked), isTrue);
      expect(repository.stored, hasLength(100));
    });

    test('returns existing progress without reseeding', () async {
      final existing = [
        const Level(
          id: 1,
          title: 'Level 1',
          difficulty: LevelDifficulty.easy,
          stars: 2,
          isCompleted: true,
          isUnlocked: true,
        ),
      ];
      final repository = _FakeLevelsRepository()..stored = existing;
      final service = LevelService(repository);

      final levels = await service.loadLevels();

      expect(levels, hasLength(1));
      expect(levels.first.stars, 2);
    });
  });

  group('unlockNextLevel', () {
    test('unlocks the level immediately after the given one', () {
      final service = LevelService(_FakeLevelsRepository());
      final levels = [
        const Level(
          id: 1,
          title: 'Level 1',
          difficulty: LevelDifficulty.easy,
          stars: 0,
          isCompleted: false,
          isUnlocked: true,
        ),
        const Level(
          id: 2,
          title: 'Level 2',
          difficulty: LevelDifficulty.easy,
          stars: 0,
          isCompleted: false,
          isUnlocked: false,
        ),
      ];

      final updated = service.unlockNextLevel(levels, 1);

      expect(updated[1].isUnlocked, isTrue);
    });

    test('is a no-op past the last level', () {
      final service = LevelService(_FakeLevelsRepository());
      final levels = [
        const Level(
          id: 1,
          title: 'Level 1',
          difficulty: LevelDifficulty.easy,
          stars: 0,
          isCompleted: false,
          isUnlocked: true,
        ),
      ];

      final updated = service.unlockNextLevel(levels, 1);

      expect(updated, same(levels));
    });
  });

  group('completeLevel', () {
    test('marks completed, keeps best stars/time/moves, unlocks next', () async {
      final repository = _FakeLevelsRepository()
        ..stored = [
          const Level(
            id: 1,
            title: 'Level 1',
            difficulty: LevelDifficulty.easy,
            stars: 1,
            isCompleted: true,
            isUnlocked: true,
            bestTimeSeconds: 60,
            bestMoves: 40,
          ),
          const Level(
            id: 2,
            title: 'Level 2',
            difficulty: LevelDifficulty.easy,
            stars: 0,
            isCompleted: false,
            isUnlocked: false,
          ),
        ];
      final service = LevelService(repository);

      final updated = await service.completeLevel(
        repository.stored,
        1,
        stars: 3,
        timeSeconds: 45,
        moves: 50,
      );

      final level1 = updated.firstWhere((l) => l.id == 1);
      expect(level1.isCompleted, isTrue);
      expect(level1.stars, 3, reason: 'higher star count should win');
      expect(level1.bestTimeSeconds, 45, reason: 'lower time is better');
      expect(level1.bestMoves, 40, reason: 'fewer moves already on record wins');
      expect(updated.firstWhere((l) => l.id == 2).isUnlocked, isTrue);
      expect(repository.stored, updated, reason: 'result should be persisted');
    });
  });

  group('resetProgress', () {
    test('restores a fresh 100-level set with only level 1 unlocked', () async {
      final repository = _FakeLevelsRepository()
        ..stored = [
          const Level(
            id: 1,
            title: 'Level 1',
            difficulty: LevelDifficulty.easy,
            stars: 3,
            isCompleted: true,
            isUnlocked: true,
          ),
        ];
      final service = LevelService(repository);

      final levels = await service.resetProgress();

      expect(levels, hasLength(100));
      expect(levels.first.isCompleted, isFalse);
      expect(levels.first.stars, 0);
      expect(repository.stored.first.isCompleted, isFalse);
    });
  });
}
