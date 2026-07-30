import '../../levels/domain/entities/level.dart';
import '../../levels/domain/services/chapter_catalog.dart';

/// A puzzle board's shape: [cols] columns by [rows] rows of square
/// pieces. Deliberately portrait (rows > cols) rather than a square N×N
/// grid, to match a portrait reference photo and use more of a phone
/// screen's vertical space.
class BoardDimensions {
  const BoardDimensions({required this.cols, required this.rows});

  final int cols;
  final int rows;

  int get pieceCount => cols * rows;

  /// Width ÷ height — feed this straight into an `AspectRatio`.
  double get aspectRatio => cols / rows;
}

/// Board dimensions for each difficulty tier. Higher difficulty means
/// more pieces to place. Used by Daily Challenge, which has no
/// chapter/level concept of its own (always Medium difficulty). Chaptered
/// levels use [boardDimensionsForLevel] instead, since chapters set board
/// size directly rather than via this fixed per-tier table.
BoardDimensions boardDimensionsFor(LevelDifficulty difficulty) =>
    switch (difficulty) {
      LevelDifficulty.easy => const BoardDimensions(cols: 3, rows: 4),
      LevelDifficulty.medium => const BoardDimensions(cols: 4, rows: 5),
      LevelDifficulty.hard => const BoardDimensions(cols: 5, rows: 6),
      LevelDifficulty.expert => const BoardDimensions(cols: 6, rows: 7),
      LevelDifficulty.master => const BoardDimensions(cols: 8, rows: 9),
    };

/// Board dimensions for a chaptered level, derived from the [boardCols]
/// of the chapter that owns it (see [ChapterCatalog]). Always portrait —
/// see [BoardDimensions].
BoardDimensions boardDimensionsForLevel(int levelId) {
  final cols = ChapterCatalog.chapterForLevel(levelId).boardCols;
  return BoardDimensions(cols: cols, rows: cols + 1);
}
