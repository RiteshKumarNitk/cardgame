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
  ///
  /// Board size varies by position within the section to create a
  /// natural difficulty ramp: early levels use smaller boards that
  /// grow toward the chapter's full size.
  static LevelConfig levelConfigFor(int levelId) {
    final chapter = chapterForLevel(levelId);
    final section = sectionForLevel(levelId);
    final levelInSection = levelId - section.startLevelId + 1;

    // Board size ramps up within each section: early levels get smaller
    // boards, growing toward the chapter's full size by the section's end.
    // This makes the progression role genuinely meaningful — a "practice"
    // level has fewer pieces than an "advanced" level.
    final cols = _boardColsForPosition(
      chapterBoardCols: chapter.boardCols,
      levelInSection: levelInSection,
    );

    return LevelConfig(
      levelId: levelId,
      chapterId: chapter.id,
      sectionId: section.id,
      sectionIndex: section.index,
      levelInSection: levelInSection,
      difficulty: chapter.difficulty,
      cols: cols,
      rows: cols + 1, // Always portrait
      seed: levelId, // Deterministic from level ID
      progressRole: _progressRoleForPosition(levelInSection),
    );
  }

  /// Returns the effective column count for a level at [levelInSection]
  /// within a chapter whose maximum board is [chapterBoardCols].
  ///
  /// The board grows across the section's 20-level arc:
  /// - Levels 1-5: chapter max minus 1 (gentle intro)
  /// - Levels 6-10: chapter max minus 0 (full board)
  /// - Levels 11-20: chapter max (full board, more complex)
  ///
  /// The minimum is always 3 columns (the smallest board in the game).
  static int _boardColsForPosition({
    required int chapterBoardCols,
    required int levelInSection,
  }) {
    final cols = switch (levelInSection) {
      <= 5 => (chapterBoardCols - 1).clamp(3, chapterBoardCols),
      _ => chapterBoardCols,
    };
    return cols;
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
      sectionCount: 1, // 20 levels — intro to swapping
    ),
    _ChapterBlueprint(
      name: 'Nature',
      difficulty: LevelDifficulty.medium,
      boardCols: 4,
      sectionCount: 1, // 20 levels — larger board, no groups
    ),
    _ChapterBlueprint(
      name: 'Cities',
      difficulty: LevelDifficulty.hard,
      boardCols: 5,
      sectionCount: 1, // 20 levels — groups introduced
    ),
    _ChapterBlueprint(
      name: 'Animals',
      difficulty: LevelDifficulty.expert,
      boardCols: 6,
      sectionCount: 1, // 20 levels — larger groups, displacement
    ),

    // ── Master tier ─────────────────────────────────────────────────
    // Reasonable board sizes for phone screens. 8×9 is the practical
    // maximum — anything larger makes pieces too small to interact with.
    _ChapterBlueprint(
      name: 'Ocean Depths',
      difficulty: LevelDifficulty.master,
      boardCols: 7,
      sectionCount: 1, // 20 levels — complex groups
    ),
    _ChapterBlueprint(
      name: 'Mountain Peaks',
      difficulty: LevelDifficulty.master,
      boardCols: 8,
      sectionCount: 1, // 20 levels — near-max board
    ),
    _ChapterBlueprint(
      name: 'Desert Sands',
      difficulty: LevelDifficulty.master,
      boardCols: 8,
      sectionCount: 1, // 20 levels — final challenge
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
