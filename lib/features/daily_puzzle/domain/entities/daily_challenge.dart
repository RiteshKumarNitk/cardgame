import 'package:equatable/equatable.dart';

import '../../../levels/domain/entities/level.dart';

/// Today's Daily Challenge status. Unlike a regular [Level], this isn't
/// part of the 100-level progression — it resets every day and tracks
/// its own streak instead of stars/unlock state.
class DailyChallenge extends Equatable {
  const DailyChallenge({
    required this.dateKey,
    required this.difficulty,
    required this.streak,
    required this.alreadyCompletedToday,
  });

  /// `yyyy-mm-dd`.
  final String dateKey;
  final LevelDifficulty difficulty;

  /// Consecutive days completed, including today if [alreadyCompletedToday].
  final int streak;
  final bool alreadyCompletedToday;

  @override
  List<Object?> get props => [
    dateKey,
    difficulty,
    streak,
    alreadyCompletedToday,
  ];
}
