import '../entities/level.dart';
import '../repositories/levels_repository.dart';
import 'demo_levels_generator.dart';

/// Business rules for level progress: seeding, completion, and the
/// unlock-next-level rule. The repository only knows how to persist a
/// list of levels — every rule about *what* those levels should contain
/// lives here, kept independent of Hive/Bloc/UI so it's trivial to test.
class LevelService {
  LevelService(this._repository);

  final LevelsRepository _repository;

  /// Loads saved progress, seeding the 100 demo levels on first run.
  Future<List<Level>> loadLevels() async {
    final levels = await _repository.loadLevels();
    if (levels.isNotEmpty) return levels;

    final demoLevels = generateDemoLevels();
    await _repository.saveLevels(demoLevels);
    return demoLevels;
  }

  /// Unlocks the level right after [completedLevelId], if it isn't
  /// already. Returns [levels] unchanged if there's nothing to unlock.
  List<Level> unlockNextLevel(List<Level> levels, int completedLevelId) {
    final index = levels.indexWhere((level) => level.id == completedLevelId);
    if (index == -1) return levels;

    final nextIndex = index + 1;
    if (nextIndex >= levels.length || levels[nextIndex].isUnlocked) {
      return levels;
    }

    final updated = List<Level>.of(levels);
    updated[nextIndex] = updated[nextIndex].copyWith(isUnlocked: true);
    return updated;
  }

  /// Marks [levelId] completed, keeps the best stars/time/moves, unlocks
  /// the next level, and persists the result.
  Future<List<Level>> completeLevel(
    List<Level> levels,
    int levelId, {
    required int stars,
    int? timeSeconds,
    int? moves,
  }) async {
    final index = levels.indexWhere((level) => level.id == levelId);
    if (index == -1) return levels;

    final current = levels[index];
    var updated = List<Level>.of(levels);
    updated[index] = current.copyWith(
      isCompleted: true,
      stars: stars > current.stars ? stars : current.stars,
      bestTimeSeconds: _better(
        current.bestTimeSeconds,
        timeSeconds,
        lowerIsBetter: true,
      ),
      bestMoves: _better(current.bestMoves, moves, lowerIsBetter: true),
    );
    updated = unlockNextLevel(updated, levelId);

    await _repository.saveLevels(updated);
    return updated;
  }

  /// Wipes progress back to a fresh set of demo levels (only level 1
  /// unlocked, nothing completed).
  Future<List<Level>> resetProgress() async {
    final demoLevels = generateDemoLevels();
    await _repository.saveLevels(demoLevels);
    return demoLevels;
  }

  int? _better(int? current, int? candidate, {required bool lowerIsBetter}) {
    if (candidate == null) return current;
    if (current == null) return candidate;
    final candidateIsBetter = lowerIsBetter
        ? candidate < current
        : candidate > current;
    return candidateIsBetter ? candidate : current;
  }
}
