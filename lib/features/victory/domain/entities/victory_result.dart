import '../../../levels/domain/entities/level.dart';

/// The outcome handed from Puzzle to Victory when a level is solved —
/// just display data. Persistence (level completion, wallet credit)
/// already happened via `LevelService.completeLevel` and
/// `WalletCubit.addCoins` before this is built.
class VictoryResult {
  const VictoryResult({
    required this.level,
    required this.stars,
    required this.moves,
    required this.timeSeconds,
    required this.coinsEarned,
    required this.nextLevelId,
  });

  final Level level;

  /// 1-3.
  final int stars;
  final int moves;
  final int timeSeconds;
  final int coinsEarned;

  /// Experience points earned, scaled with stars.
  int get experienceEarned => stars * 25;

  /// Null if [level] was the last one.
  final int? nextLevelId;
}
