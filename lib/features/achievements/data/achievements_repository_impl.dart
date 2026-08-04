import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/repositories/achievements_repository.dart';

/// Hive-backed [AchievementsRepository] — one box holding both the counter
/// map and the unlocked-id list, so the whole feature persists in a single
/// place.
class HiveAchievementsRepository implements AchievementsRepository {
  Box get _box => Hive.box(AppConstants.achievementsBoxName);

  @override
  Future<Map<String, int>> loadCounters() async {
    final raw = _box.get(AppConstants.achievementsCountersKey);
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      );
    }
    return <String, int>{};
  }

  @override
  Future<void> saveCounters(Map<String, int> counters) async {
    await _box.put(AppConstants.achievementsCountersKey, counters);
  }

  @override
  Future<Set<String>> loadUnlockedIds() async {
    final raw = _box.get(AppConstants.achievementsUnlockedKey);
    if (raw is List) return raw.map((e) => e.toString()).toSet();
    return <String>{};
  }

  @override
  Future<void> saveUnlockedIds(Set<String> ids) async {
    await _box.put(AppConstants.achievementsUnlockedKey, ids.toList());
  }
}