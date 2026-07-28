import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../domain/entities/level.dart';

/// Visual styling for each [LevelDifficulty] tier — kept separate from the
/// domain enum so the domain layer stays UI-agnostic.
extension LevelDifficultyStyle on LevelDifficulty {
  Color get color => switch (this) {
    LevelDifficulty.easy => AppColors.difficultyEasy,
    LevelDifficulty.medium => AppColors.difficultyMedium,
    LevelDifficulty.hard => AppColors.difficultyHard,
    LevelDifficulty.expert => AppColors.difficultyExpert,
  };

  String get label => switch (this) {
    LevelDifficulty.easy => 'Easy',
    LevelDifficulty.medium => 'Medium',
    LevelDifficulty.hard => 'Hard',
    LevelDifficulty.expert => 'Expert',
  };
}
