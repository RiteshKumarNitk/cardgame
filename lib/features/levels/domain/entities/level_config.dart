import 'package:equatable/equatable.dart';

import 'level.dart';

/// Describes a level's position within its section's progression arc.
///
/// Each section has exactly 20 levels. The role determines the level's
/// purpose in the player's learning/challenge curve. Different sections
/// can use different mechanics, but the 20-level arc structure is
/// consistent.
enum SectionProgressRole {
  /// Levels 1-3: Introduce/reinforce the section's core mechanic.
  introduce,

  /// Levels 4-6: Gradually increase difficulty within the mechanic.
  practice,

  /// Levels 7-9: Introduce variation or combine with prior mechanics.
  variation,

  /// Level 10: Mini challenge — test mastery of the current mechanics.
  miniChallenge,

  /// Levels 11-13: Combine previous mechanics in new ways.
  combine,

  /// Levels 14-16: Higher difficulty, tighter constraints.
  advanced,

  /// Levels 17-18: Challenge levels — demanding but fair.
  challenge,

  /// Level 19: Pre-finale — sets up the section's conclusion.
  preFinale,

  /// Level 20: Section finale — the culmination of the section's arc.
  finale,
}

/// The complete configuration for a puzzle level, consumed by the puzzle
/// engine. This is the single source of truth for all puzzle parameters.
///
/// The puzzle engine never knows about chapters, sections, or
/// progression. It receives a [LevelConfig] and builds the puzzle.
///
/// The data flow is:
/// ```
/// ChapterCatalog → LevelConfig → Puzzle Engine → Puzzle State → UI
/// ```
///
/// [LevelConfig] is derived from the level's position in the chapter
/// catalog. Two levels with the same [difficulty], [cols], [rows], and
/// [seed] produce identical puzzles regardless of their chapter/section.
class LevelConfig extends Equatable {
  const LevelConfig({
    required this.levelId,
    required this.chapterId,
    required this.sectionId,
    required this.sectionIndex,
    required this.levelInSection,
    required this.difficulty,
    required this.cols,
    required this.rows,
    required this.seed,
    required this.progressRole,
  });

  /// Unique level identifier (1-based, global across all chapters).
  final int levelId;

  /// The chapter this level belongs to (1-based).
  final int chapterId;

  /// The section this level belongs to (1-based, global across chapters).
  final int sectionId;

  /// 1-based position of the section within its chapter.
  final int sectionIndex;

  /// 1-based position of the level within its section (1-20).
  final int levelInSection;

  /// Difficulty tier for this level.
  final LevelDifficulty difficulty;

  /// Number of columns in the puzzle grid.
  final int cols;

  /// Number of rows in the puzzle grid.
  final int rows;

  /// Shuffle seed. Deterministic from level ID — ensures reproducible
  /// puzzles. Incremented on restart for different arrangements.
  final int seed;

  /// The level's role in its section's 20-level progression arc.
  final SectionProgressRole progressRole;

  /// Total number of atomic cells on the board.
  int get pieceCount => cols * rows;

  /// Width/height ratio for the puzzle board (always portrait).
  double get aspectRatio => cols / rows;

  /// Whether this level includes connected groups (Hard+).
  bool get hasGroups =>
      difficulty == LevelDifficulty.hard ||
      difficulty == LevelDifficulty.expert ||
      difficulty == LevelDifficulty.master;

  @override
  List<Object?> get props => [
    levelId,
    chapterId,
    sectionId,
    sectionIndex,
    levelInSection,
    difficulty,
    cols,
    rows,
    seed,
    progressRole,
  ];
}
