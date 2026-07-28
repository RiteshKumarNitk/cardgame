import '../../../levels/domain/entities/level.dart';

/// The outcome handed from Puzzle to Victory when a level is solved —
/// just display data, all persistence already happened via
/// `LevelService.completeLevel`.
class VictoryResult {
  const VictoryResult({
    required this.level,
    required this.stars,
    required this.moves,
    required this.timeSeconds,
    required this.nextLevelId,
  });

  final Level level;

  /// 1-3.
  final int stars;
  final int moves;
  final int timeSeconds;

  /// Null if [level] was the last one.
  final int? nextLevelId;
}
