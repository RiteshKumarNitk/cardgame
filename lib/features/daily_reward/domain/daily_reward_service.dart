import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';

class DailyRewardService {
  Box get _box => Hive.box(AppConstants.dailyRewardBoxName);

  /// Returns today's date in YYYY-MM-DD format.
  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// True if the user hasn't claimed their reward today.
  bool isRewardAvailable() {
    final lastClaimed = _box.get(AppConstants.dailyRewardLastClaimedKey);
    return lastClaimed != _todayKey();
  }

  /// Marks today's reward as claimed.
  Future<void> claimReward() async {
    await _box.put(AppConstants.dailyRewardLastClaimedKey, _todayKey());
  }
}
