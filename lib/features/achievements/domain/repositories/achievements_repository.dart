/// Storage for the persistent side of achievements: the counters that
/// drive progress and the set of already-unlocked achievement ids.
///
/// An interface (rather than Hive used directly) so tests can supply an
/// in-memory fake — same pattern as [WalletService].
abstract interface class AchievementsRepository {
  Future<Map<String, int>> loadCounters();

  Future<void> saveCounters(Map<String, int> counters);

  Future<Set<String>> loadUnlockedIds();

  Future<void> saveUnlockedIds(Set<String> ids);
}