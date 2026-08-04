import '../entities/achievement.dart';

/// The fixed catalog of every achievement in the game plus the pure,
/// testable progress rule that measures them all.
///
/// Counting is data-driven: each achievement targets one persisted counter
/// and unlocks at a goal value. Flags (e.g. "got 3 stars on a level") are
/// just counters with a goal of 1.
abstract final class AchievementCatalog {
  // ── Persisted counter keys ──
  static const String counterPuzzles = 'puzzles_completed';
  static const String counterStars = 'stars_earned';
  static const String counterBestStreak = 'best_streak';
  static const String flagPerfect = 'flag_perfect_3_stars';
  static const String flagSpeedDemon = 'flag_speed_demon';

  static const List<Achievement> achievements = [
    Achievement(
      id: 'first_puzzle',
      title: 'First Steps',
      description: 'Complete your very first puzzle',
      iconKey: 'puzzle',
      rewardCoins: 25,
      counterKey: counterPuzzles,
      goal: 1,
    ),
    Achievement(
      id: 'puzzle_10',
      title: 'Getting Started',
      description: 'Complete 10 puzzles',
      iconKey: 'scoreboard',
      rewardCoins: 50,
      counterKey: counterPuzzles,
      goal: 10,
    ),
    Achievement(
      id: 'puzzle_50',
      title: 'Puzzle Pro',
      description: 'Complete 50 puzzles',
      iconKey: 'trophy',
      rewardCoins: 150,
      counterKey: counterPuzzles,
      goal: 50,
    ),
    Achievement(
      id: 'star_30',
      title: 'Star Collector',
      description: 'Earn 30 stars',
      iconKey: 'star',
      rewardCoins: 75,
      counterKey: counterStars,
      goal: 30,
    ),
    Achievement(
      id: 'star_100',
      title: 'Star Master',
      description: 'Earn 100 stars',
      iconKey: 'star_ring',
      rewardCoins: 200,
      counterKey: counterStars,
      goal: 100,
    ),
    Achievement(
      id: 'perfect_3',
      title: 'Perfectionist',
      description: 'Earn 3 stars on a puzzle',
      iconKey: 'diamond',
      rewardCoins: 50,
      counterKey: flagPerfect,
      goal: 1,
    ),
    Achievement(
      id: 'speed_demon',
      title: 'Speed Demon',
      description: 'Solve a puzzle in under a minute',
      iconKey: 'bolt',
      rewardCoins: 50,
      counterKey: flagSpeedDemon,
      goal: 1,
    ),
    Achievement(
      id: 'streak_3',
      title: 'On a Roll',
      description: 'Reach a 3-day Daily Challenge streak',
      iconKey: 'flame',
      rewardCoins: 75,
      counterKey: counterBestStreak,
      goal: 3,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Unstoppable',
      description: 'Reach a 7-day Daily Challenge streak',
      iconKey: 'shield',
      rewardCoins: 200,
      counterKey: counterBestStreak,
      goal: 7,
    ),
  ];

  /// The live progress of every achievement, given the persisted counters.
  ///
  /// Pure and deterministic so the rule is trivially unit-testable without
  /// any storage or UI.
  static List<AchievementProgress> progressFor(Map<String, int> counters) {
    return [
      for (final achievement in achievements)
        AchievementProgress(
          achievement: achievement,
          current: (counters[achievement.counterKey] ?? 0).clamp(
            0,
            achievement.goal,
          ),
        ),
    ];
  }
}