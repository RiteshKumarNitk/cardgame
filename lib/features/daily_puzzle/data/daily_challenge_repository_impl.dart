import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/repositories/daily_challenge_repository.dart';

class HiveDailyChallengeRepository implements DailyChallengeRepository {
  Box get _box => Hive.box(AppConstants.dailyChallengeBoxName);

  @override
  Future<String?> loadLastCompletedDate() async =>
      _box.get(AppConstants.dailyChallengeLastCompletedKey) as String?;

  @override
  Future<int> loadStreak() async =>
      (_box.get(AppConstants.dailyChallengeStreakKey) as int?) ?? 0;

  @override
  Future<void> save({
    required String lastCompletedDate,
    required int streak,
  }) async {
    await _box.put(
      AppConstants.dailyChallengeLastCompletedKey,
      lastCompletedDate,
    );
    await _box.put(AppConstants.dailyChallengeStreakKey, streak);
  }
}
