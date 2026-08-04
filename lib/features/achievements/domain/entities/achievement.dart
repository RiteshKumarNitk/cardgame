import 'package:equatable/equatable.dart';

/// A single trackable milestone in the achievements catalog.
///
/// Pure domain data: no Flutter types, no storage concerns. Progress
/// towards [goal] is read from a persisted counter named by [counterKey]
/// (see [AchievementCatalog.progressFor]). [iconKey] is a stable string
/// identifier the UI maps to an icon — kept out of the domain layer.
class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.rewardCoins,
    required this.counterKey,
    required this.goal,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;

  /// Coin reward granted the moment the achievement unlocks.
  final int rewardCoins;

  /// Key of the persisted counter this achievement measures.
  final String counterKey;

  /// Value of [counterKey] at which the achievement unlocks.
  final int goal;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    iconKey,
    rewardCoins,
    counterKey,
    goal,
  ];
}

/// An achievement plus the player's live progress on it.
class AchievementProgress extends Equatable {
  const AchievementProgress({
    required this.achievement,
    required this.current,
  });

  final Achievement achievement;

  /// Clamped to [Achievement.goal] so progress bars never overflow.
  final int current;

  bool get isUnlocked => current >= achievement.goal;

  double get fraction => achievement.goal == 0
      ? 0
      : (current / achievement.goal).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [achievement, current];
}
