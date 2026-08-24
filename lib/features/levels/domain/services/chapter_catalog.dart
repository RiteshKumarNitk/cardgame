import '../entities/chapter.dart';
import '../entities/level.dart';
import '../entities/level_config.dart';
import '../entities/section.dart';

/// The single source of truth for chapter/section membership and board
/// size. A level's chapter/section is always *derived* from its id
/// against this catalog — never persisted — so growing the catalog never
/// requires a Hive migration.
///
/// ## Architecture
///
/// The catalog is **procedurally generated** from a list of chapter
/// blueprints. New chapters can be added by appending to
/// [_chapterBlueprints] — no engine changes needed.
///
/// Every section contains exactly **20 levels**. The 20-level arc
/// follows a consistent progression pattern defined by
/// [SectionProgressRole], with the section's theme/mechanic determining
/// *what* the player encounters and the role determining *when*.
///
/// ## Adding New Content
///
/// To add a new chapter:
/// 1. Append a `_ChapterBlueprint` to `_chapterBlueprints`.
/// 2. The catalog automatically generates the chapter, its sections,
///    and all level configs.
/// 3. No changes to the puzzle engine, state management, or UI.
///
/// The catalog has no hard upper bound on total levels. The game
/// supports continuous content expansion.
abstract final class ChapterCatalog {
  static final List<Chapter> chapters = _buildChapters();

  static int get totalLevelCount => chapters.last.endLevelId;

  static Chapter chapterForLevel(int levelId) {
    for (final chapter in chapters) {
      if (chapter.containsLevel(levelId)) return chapter;
    }
    throw ArgumentError.value(
      levelId,
      'levelId',
      'No chapter contains this level',
    );
  }

  static Section sectionForLevel(int levelId) {
    final chapter = chapterForLevel(levelId);
    for (final section in chapter.sections) {
      if (section.containsLevel(levelId)) return section;
    }
    throw ArgumentError.value(
      levelId,
      'levelId',
      'No section contains this level',
    );
  }

  /// Builds a complete [LevelConfig] for the given [levelId].
  ///
  /// This is the primary API for the puzzle engine. It resolves all
  /// puzzle parameters from the level's position in the catalog.
  static LevelConfig levelConfigFor(int levelId) {
    final chapter = chapterForLevel(levelId);
    final section = sectionForLevel(levelId);
    final levelInSection = levelId - section.startLevelId + 1;

    return LevelConfig(
      levelId: levelId,
      chapterId: chapter.id,
      sectionId: section.id,
      sectionIndex: section.index,
      levelInSection: levelInSection,
      difficulty: chapter.difficulty,
      cols: chapter.boardCols,
      rows: chapter.boardCols + 1, // Always portrait
      seed: levelId, // Deterministic from level ID
      progressRole: _progressRoleForPosition(levelInSection),
    );
  }

  /// Maps a 1-20 position within a section to its progression role.
  ///
  /// This is the standard 20-level arc. Sections can override this
  /// by providing custom role mappings in the future.
  static SectionProgressRole _progressRoleForPosition(int position) {
    return switch (position) {
      <= 3 => SectionProgressRole.introduce,
      <= 6 => SectionProgressRole.practice,
      <= 9 => SectionProgressRole.variation,
      10 => SectionProgressRole.miniChallenge,
      <= 13 => SectionProgressRole.combine,
      <= 16 => SectionProgressRole.advanced,
      <= 18 => SectionProgressRole.challenge,
      19 => SectionProgressRole.preFinale,
      20 => SectionProgressRole.finale,
      _ => throw ArgumentError.value(position, 'position', 'Must be 1-20'),
    };
  }

  /// Section level counts. Every section contains exactly 20 levels.
  static const int _sectionLevelCount = 20;

  // ─── Chapter Blueprints ──────────────────────────────────────────

  /// The master list of all chapters. Append new chapters here to expand
  /// the game. No engine changes required.
  ///
  /// Chapters are defined by:
  /// - [name]: Display name
  /// - [difficulty]: Base difficulty tier
  /// - [boardCols]: Grid column count (rows = cols + 1, always portrait)
  /// - [sectionCount]: Number of 20-level sections
  static const List<_ChapterBlueprint> _chapterBlueprints = [
    // ── Hand-authored chapters ──────────────────────────────────────
    _ChapterBlueprint(
      name: 'The Beginning',
      difficulty: LevelDifficulty.easy,
      boardCols: 3,
      sectionCount: 3, // 60 levels
    ),
    _ChapterBlueprint(
      name: 'Nature',
      difficulty: LevelDifficulty.medium,
      boardCols: 5,
      sectionCount: 2, // 40 levels
    ),
    _ChapterBlueprint(
      name: 'Cities',
      difficulty: LevelDifficulty.hard,
      boardCols: 7,
      sectionCount: 2, // 40 levels
    ),
    _ChapterBlueprint(
      name: 'Animals',
      difficulty: LevelDifficulty.expert,
      boardCols: 9,
      sectionCount: 2, // 40 levels
    ),

    // ── Continuation chapters (Master tier) ─────────────────────────
    // Board size grows gradually. Section count varies for pacing.
    _ChapterBlueprint(
      name: 'Ocean Depths',
      difficulty: LevelDifficulty.master,
      boardCols: 11,
      sectionCount: 2,
    ),
    _ChapterBlueprint(
      name: 'Mountain Peaks',
      difficulty: LevelDifficulty.master,
      boardCols: 12,
      sectionCount: 3,
    ),
    _ChapterBlueprint(
      name: 'Desert Sands',
      difficulty: LevelDifficulty.master,
      boardCols: 13,
      sectionCount: 2,
    ),
    _ChapterBlueprint(
      name: 'Winter Wonderland',
      difficulty: LevelDifficulty.master,
      boardCols: 14,
      sectionCount: 3,
    ),
    _ChapterBlueprint(
      name: 'Space Odyssey',
      difficulty: LevelDifficulty.master,
      boardCols: 15,
      sectionCount: 2,
    ),
    _ChapterBlueprint(
      name: 'Ancient Ruins',
      difficulty: LevelDifficulty.master,
      boardCols: 16,
      sectionCount: 3,
    ),
    _ChapterBlueprint(
      name: 'Enchanted Forest',
      difficulty: LevelDifficulty.master,
      boardCols: 17,
      sectionCount: 2,
    ),
    _ChapterBlueprint(
      name: 'Neon Nights',
      difficulty: LevelDifficulty.master,
      boardCols: 18,
      sectionCount: 3,
    ),
    _ChapterBlueprint(
      name: 'Candy Kingdom',
      difficulty: LevelDifficulty.master,
      boardCols: 19,
      sectionCount: 2,
    ),
    _ChapterBlueprint(
      name: 'Sky Islands',
      difficulty: LevelDifficulty.master,
      boardCols: 20,
      sectionCount: 3,
    ),
    _ChapterBlueprint(
      name: 'Crystal Caves',
      difficulty: LevelDifficulty.master,
      boardCols: 21,
      sectionCount: 2,
    ),
    _ChapterBlueprint(
      name: 'Legendary Realm',
      difficulty: LevelDifficulty.master,
      boardCols: 22,
      sectionCount: 3,
    ),
  ];

  // ─── Build Logic ─────────────────────────────────────────────────

  static List<Chapter> _buildChapters() {
    return _assignIds(_chapterBlueprints);
  }

  static List<Chapter> _assignIds(List<_ChapterBlueprint> blueprints) {
    final chapters = <Chapter>[];
    var nextLevelId = 1;
    var chapterId = 1;
    var sectionId = 1;

    for (final blueprint in blueprints) {
      final chapterStart = nextLevelId;
      final sections = <Section>[];

      for (var s = 0; s < blueprint.sectionCount; s++) {
        final sectionStart = nextLevelId;
        final sectionEnd = nextLevelId + _sectionLevelCount - 1;

        // Determine the progression role for the first level of this
        // section. All levels in the section follow the 20-level arc.
        final progressRole = _progressRoleForPosition(1);

        sections.add(
          Section(
            id: sectionId,
            chapterId: chapterId,
            index: s + 1,
            startLevelId: sectionStart,
            endLevelId: sectionEnd,
            progressRole: progressRole,
          ),
        );
        nextLevelId = sectionEnd + 1;
        sectionId++;
      }

      chapters.add(
        Chapter(
          id: chapterId,
          name: blueprint.name,
          difficulty: blueprint.difficulty,
          boardCols: blueprint.boardCols,
          startLevelId: chapterStart,
          endLevelId: nextLevelId - 1,
          sections: sections,
        ),
      );
      chapterId++;
    }

    return chapters;
  }
}

/// Blueprint for generating a chapter. New chapters are added by
/// appending instances to [ChapterCatalog._chapterBlueprints].
class _ChapterBlueprint {
  const _ChapterBlueprint({
    required this.name,
    required this.difficulty,
    required this.boardCols,
    required this.sectionCount,
  });

  final String name;
  final LevelDifficulty difficulty;
  final int boardCols;

  /// Number of 20-level sections in this chapter.
  final int sectionCount;

  int get totalLevels => sectionCount * 20;
}
