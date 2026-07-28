import '../entities/level.dart';

/// Generates the 100 demo levels used before any real level-design content
/// exists. Only level 1 starts unlocked — everything else unlocks as prior
/// levels are completed (see [LevelService.unlockNextLevel]).
List<Level> generateDemoLevels({int count = 100}) {
  return List.generate(count, (index) {
    final id = index + 1;
    return Level(
      id: id,
      title: 'Level $id',
      difficulty: _difficultyForId(id, count),
      stars: 0,
      isCompleted: false,
      isUnlocked: id == 1,
    );
  });
}

LevelDifficulty _difficultyForId(int id, int count) {
  final quarter = count / 4;
  if (id <= quarter) return LevelDifficulty.easy;
  if (id <= quarter * 2) return LevelDifficulty.medium;
  if (id <= quarter * 3) return LevelDifficulty.hard;
  return LevelDifficulty.expert;
}
