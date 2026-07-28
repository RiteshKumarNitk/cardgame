import '../features/levels/domain/entities/level.dart';

/// Overall player progress derived from a level list: how much is done,
/// how many stars earned, and which level to play next.
class GameProgress {
  const GameProgress({
    required this.completedCount,
    required this.totalCount,
    required this.totalStars,
    required this.currentLevelId,
  });

  final int completedCount;
  final int totalCount;
  final int totalStars;

  /// The next playable (unlocked, not yet completed) level, or `null` if
  /// every level is complete.
  final int? currentLevelId;

  /// 0.0-1.0.
  double get percentComplete =>
      totalCount == 0 ? 0 : completedCount / totalCount;
}

/// Computes [GameProgress] from a level list. Kept separate from the
/// Levels feature since "overall progress" is a cross-cutting game concept
/// other features (Home's Continue card, a future stats screen) will also
/// need to read.
abstract final class GameProgressManager {
  static GameProgress computeFrom(List<Level> levels) {
    var completed = 0;
    var stars = 0;
    int? currentLevelId;

    for (final level in levels) {
      if (level.isCompleted) completed++;
      stars += level.stars;
      if (currentLevelId == null && level.isUnlocked && !level.isCompleted) {
        currentLevelId = level.id;
      }
    }

    return GameProgress(
      completedCount: completed,
      totalCount: levels.length,
      totalStars: stars,
      currentLevelId: currentLevelId,
    );
  }
}
