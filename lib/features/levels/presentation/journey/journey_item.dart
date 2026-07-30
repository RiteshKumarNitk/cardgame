import '../../domain/entities/chapter.dart';
import '../../domain/entities/level.dart';
import '../../domain/entities/section.dart';
import '../../domain/services/chapter_catalog.dart';

/// One row in the Journey Map's flattened, scrollable path.
sealed class JourneyItem {
  const JourneyItem();
}

/// Marks the start of a new [Chapter] — rendered as a full-width banner.
class JourneyChapterBanner extends JourneyItem {
  const JourneyChapterBanner(this.chapter);

  final Chapter chapter;
}

/// A single playable level node on the path.
class JourneyLevelNode extends JourneyItem {
  const JourneyLevelNode(this.level);

  final Level level;
}

/// Marks the end of a [Section] — rendered as a milestone divider.
class JourneySectionComplete extends JourneyItem {
  const JourneySectionComplete({required this.chapter, required this.section});

  final Chapter chapter;
  final Section section;
}

/// Flattens the full level catalog into a single ordered list a
/// `ListView.builder` can render directly: a chapter banner before each
/// chapter's first level, one node per level, and a section-complete
/// marker after each section's last level.
///
/// [levels] must be sorted by id starting at 1 with no gaps (exactly what
/// `generateLevelCatalog()`/`LevelService` produce) — each chapter's
/// levels are read directly out of it by index rather than searched for.
List<JourneyItem> buildJourneyItems(List<Level> levels) {
  final items = <JourneyItem>[];
  for (final chapter in ChapterCatalog.chapters) {
    items.add(JourneyChapterBanner(chapter));
    for (final section in chapter.sections) {
      for (var id = section.startLevelId; id <= section.endLevelId; id++) {
        items.add(JourneyLevelNode(levels[id - 1]));
      }
      items.add(JourneySectionComplete(chapter: chapter, section: section));
    }
  }
  return items;
}
