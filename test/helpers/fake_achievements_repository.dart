import 'package:puzzle_cards/features/achievements/domain/repositories/achievements_repository.dart';

/// In-memory [AchievementsRepository] fake shared by tests that render or
/// exercise the achievements feature — avoids touching real Hive.
class FakeAchievementsRepository implements AchievementsRepository {
  Map<String, int> counters = {};
  Set<String> unlockedIds = {};

  @override
  Future<Map<String, int>> loadCounters() async => Map.of(counters);

  @override
  Future<void> saveCounters(Map<String, int> counters) async {
    this.counters = Map.of(counters);
  }

  @override
  Future<Set<String>> loadUnlockedIds() async => Set.of(unlockedIds);

  @override
  Future<void> saveUnlockedIds(Set<String> ids) async {
    unlockedIds = Set.of(ids);
  }
}
