/// Domain-neutral event sink that gameplay systems call to report notable
/// moments. Implemented by `AchievementsCubit`; consumed by gameplay
/// cubits so they stay decoupled from the achievements feature.
abstract interface class AchievementEvents {
  /// A level-based puzzle was solved.
  Future<void> onPuzzleCompleted({
    required int stars,
    required int timeSeconds,
  });

  /// Today's Daily Challenge was completed with [streak].
  Future<void> onDailyChallengeCompleted(int streak);
}