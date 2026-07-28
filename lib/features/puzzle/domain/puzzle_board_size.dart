import '../../levels/domain/entities/level.dart';

/// Board dimensions (an N×N grid) for each difficulty tier. Higher
/// difficulty means more pieces to place.
int boardSizeFor(LevelDifficulty difficulty) => switch (difficulty) {
  LevelDifficulty.easy => 3,
  LevelDifficulty.medium => 4,
  LevelDifficulty.hard => 5,
  LevelDifficulty.expert => 6,
};
