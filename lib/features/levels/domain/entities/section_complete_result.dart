import 'chapter.dart';
import 'section.dart';

/// Display data handed from Victory to the Section Complete screen when a
/// section's final level is solved (and it wasn't also the chapter's
/// final level — that case goes to Chapter Complete instead, a bigger
/// celebration that supersedes this one). Persistence (level completion,
/// wallet credit) already happened before this is built.
class SectionCompleteResult {
  const SectionCompleteResult({
    required this.chapter,
    required this.section,
    required this.totalStars,
    required this.nextLevelId,
  });

  final Chapter chapter;
  final Section section;

  /// Stars earned across every level in [section].
  final int totalStars;

  /// The first level of the next section — null only if this was
  /// somehow the last level in the entire catalog (chapter-complete
  /// would have handled that case first in practice).
  final int? nextLevelId;

  /// Bonus coin reward for finishing the section, scaled with its length.
  int get bonusCoins => section.levelCount * 5;

  /// Maximum possible stars for [section] (3 per level).
  int get maxStars => section.levelCount * 3;
}
