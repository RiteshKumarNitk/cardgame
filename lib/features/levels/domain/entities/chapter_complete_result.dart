import 'chapter.dart';

/// Display data handed from Puzzle to the Chapter Complete screen when a
/// chapter's final level is solved — just display data, same pattern as
/// `VictoryResult`. Persistence (level completion, wallet credit) already
/// happened before this is built.
class ChapterCompleteResult {
  const ChapterCompleteResult({
    required this.chapter,
    required this.totalStars,
    required this.nextChapter,
  });

  final Chapter chapter;

  /// Stars earned across every level in [chapter].
  final int totalStars;

  /// Null if [chapter] was the last one in the catalog.
  final Chapter? nextChapter;

  /// Bonus coin reward for finishing the chapter, scaled with its length.
  int get bonusCoins => chapter.levelCount * 10;

  /// Maximum possible stars for [chapter] (3 per level).
  int get maxStars => chapter.levelCount * 3;
}
