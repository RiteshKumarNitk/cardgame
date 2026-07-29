/// Persistence for Daily Challenge streak tracking.
abstract interface class DailyChallengeRepository {
  /// `yyyy-mm-dd` of the last day a challenge was completed, or `null`
  /// if none ever was.
  Future<String?> loadLastCompletedDate();

  Future<int> loadStreak();

  Future<void> save({required String lastCompletedDate, required int streak});
}
