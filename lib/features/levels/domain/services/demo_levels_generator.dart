import '../entities/level.dart';
import 'chapter_catalog.dart';

/// Generates the full level catalog — every level across every chapter in
/// [ChapterCatalog], each starting fresh (no stars, only level 1 unlocked).
///
/// A level's difficulty is inherited from the chapter that owns it. The
/// catalog grows as new chapters are added to [ChapterCatalog] — no
/// engine changes needed.
List<Level> generateLevelCatalog() {
  return List.generate(ChapterCatalog.totalLevelCount, (index) {
    final id = index + 1;
    final chapter = ChapterCatalog.chapterForLevel(id);
    return Level(
      id: id,
      title: 'Level $id',
      difficulty: chapter.difficulty,
      stars: 0,
      isCompleted: false,
      isUnlocked: id == 1,
    );
  });
}
