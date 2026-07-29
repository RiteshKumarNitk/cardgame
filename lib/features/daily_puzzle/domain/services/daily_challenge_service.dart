import '../../../levels/domain/entities/level.dart';
import '../entities/daily_challenge.dart';
import '../repositories/daily_challenge_repository.dart';

/// Business rules for the Daily Challenge: what day it is, whether
/// today's has already been played, and how completing it affects the
/// streak. `now` is always passed in rather than read from `DateTime.now()`
/// internally, so the streak logic is a pure, easily-tested function of
/// its inputs.
class DailyChallengeService {
  DailyChallengeService(this._repository);

  final DailyChallengeRepository _repository;

  /// Fixed for every player, every day — the challenge is about the
  /// streak, not variable difficulty.
  static const LevelDifficulty difficulty = LevelDifficulty.medium;

  static String dateKeyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<DailyChallenge> loadToday(DateTime now) async {
    final todayKey = dateKeyFor(now);
    final lastCompleted = await _repository.loadLastCompletedDate();
    final streak = await _repository.loadStreak();
    return DailyChallenge(
      dateKey: todayKey,
      difficulty: difficulty,
      streak: streak,
      alreadyCompletedToday: lastCompleted == todayKey,
    );
  }

  /// Marks today complete, bumping the streak if yesterday was also
  /// completed (otherwise restarting it at 1), and persists the result.
  Future<DailyChallenge> completeToday(DateTime now) async {
    final todayKey = dateKeyFor(now);
    final lastCompleted = await _repository.loadLastCompletedDate();
    if (lastCompleted == todayKey) {
      return loadToday(now);
    }

    final yesterdayKey = dateKeyFor(now.subtract(const Duration(days: 1)));
    final currentStreak = await _repository.loadStreak();
    final newStreak = lastCompleted == yesterdayKey ? currentStreak + 1 : 1;

    await _repository.save(lastCompletedDate: todayKey, streak: newStreak);
    return DailyChallenge(
      dateKey: todayKey,
      difficulty: difficulty,
      streak: newStreak,
      alreadyCompletedToday: true,
    );
  }
}
