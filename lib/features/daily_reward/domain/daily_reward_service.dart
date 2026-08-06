import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../services/analytics_service.dart';

class DailyRewardService {
  Box get _box => Hive.box(AppConstants.dailyRewardBoxName);
  
  static const _streakKey = 'streak_count';

  /// Returns a date in YYYY-MM-DD format.
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _todayKey() => _formatDate(DateTime.now());
  
  String _yesterdayKey() => _formatDate(DateTime.now().subtract(const Duration(days: 1)));

  /// True if the user hasn't claimed their reward today.
  bool isRewardAvailable() {
    final lastClaimed = _box.get(AppConstants.dailyRewardLastClaimedKey);
    return lastClaimed != _todayKey();
  }
  
  /// Returns the current streak count (1-7).
  /// If the streak is broken (didn't claim yesterday or today), it conceptually resets to 1,
  /// but we don't save the reset until they actually claim. 
  /// So this returns what the next claim *will* be.
  int getNextStreakDay() {
    if (!isRewardAvailable()) {
      return _box.get(_streakKey, defaultValue: 1) as int; // return current day they are on
    }

    final lastClaimed = _box.get(AppConstants.dailyRewardLastClaimedKey);
    if (lastClaimed == null) return 1;

    if (lastClaimed == _yesterdayKey()) {
      final currentStreak = _box.get(_streakKey, defaultValue: 0) as int;
      return currentStreak >= 7 ? 1 : currentStreak + 1;
    } else {
      return 1; // Streak broken
    }
  }
  
  /// Returns the coin reward for a given streak day (1-7).
  int getRewardForDay(int day) {
    switch (day) {
      case 1: return 20;
      case 2: return 30;
      case 3: return 50;
      case 4: return 70;
      case 5: return 100;
      case 6: return 150;
      case 7: return 300;
      default: return 20;
    }
  }

  /// Marks today's reward as claimed, advances the streak, and returns the streak day reached.
  Future<int> claimReward() async {
    if (!isRewardAvailable()) {
      return _box.get(_streakKey, defaultValue: 1) as int;
    }

    final nextDay = getNextStreakDay();

    await _box.put(_streakKey, nextDay);
    await _box.put(AppConstants.dailyRewardLastClaimedKey, _todayKey());
    
    AnalyticsService().logEvent(
      AnalyticsService.dailyRewardClaimed, 
      parameters: {'streak': nextDay},
    );
    
    return nextDay;
  }
}
