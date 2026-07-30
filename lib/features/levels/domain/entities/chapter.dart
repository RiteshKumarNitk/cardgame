import 'package:equatable/equatable.dart';

import 'level.dart';
import 'section.dart';

/// A themed run of the game's progression — e.g. "Chapter 1: The
/// Beginning" — made up of one or more [Section]s. Board size (an N×N-ish
/// piece count, see `boardDimensionsForLevel`) is fixed per chapter.
class Chapter extends Equatable {
  const Chapter({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.boardCols,
    required this.startLevelId,
    required this.endLevelId,
    required this.sections,
  });

  final int id;
  final String name;
  final LevelDifficulty difficulty;

  /// Column count of this chapter's (portrait) board — see
  /// `boardDimensionsForLevel`.
  final int boardCols;
  final int startLevelId;
  final int endLevelId;
  final List<Section> sections;

  int get levelCount => endLevelId - startLevelId + 1;

  bool containsLevel(int levelId) =>
      levelId >= startLevelId && levelId <= endLevelId;

  @override
  List<Object?> get props => [
    id,
    name,
    difficulty,
    boardCols,
    startLevelId,
    endLevelId,
    sections,
  ];
}
