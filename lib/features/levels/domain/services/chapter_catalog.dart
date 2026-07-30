import '../entities/chapter.dart';
import '../entities/level.dart';
import '../entities/section.dart';

/// The single source of truth for chapter/section membership and board
/// size. A level's chapter/section is always *derived* from its id
/// against this catalog — never persisted — so growing the catalog never
/// requires a Hive migration.
///
/// The first 4 chapters are hand-authored (levels 1-170); everything
/// after continues procedurally through [_continuationThemes] until the
/// catalog comfortably exceeds 1000 levels.
abstract final class ChapterCatalog {
  static final List<Chapter> chapters = _buildChapters();

  static int get totalLevelCount => chapters.last.endLevelId;

  static Chapter chapterForLevel(int levelId) {
    for (final chapter in chapters) {
      if (chapter.containsLevel(levelId)) return chapter;
    }
    throw ArgumentError.value(levelId, 'levelId', 'No chapter contains this level');
  }

  static Section sectionForLevel(int levelId) {
    final chapter = chapterForLevel(levelId);
    for (final section in chapter.sections) {
      if (section.containsLevel(levelId)) return section;
    }
    throw ArgumentError.value(levelId, 'levelId', 'No section contains this level');
  }

  static const int _minimumTotalLevels = 1080;

  static const List<String> _continuationThemes = [
    'Ocean Depths',
    'Mountain Peaks',
    'Desert Sands',
    'Winter Wonderland',
    'Space Odyssey',
    'Ancient Ruins',
    'Enchanted Forest',
    'Neon Nights',
    'Candy Kingdom',
    'Sky Islands',
    'Crystal Caves',
    'Legendary Realm',
  ];

  static List<Chapter> _buildChapters() {
    final blueprints = <_ChapterBlueprint>[
      const _ChapterBlueprint(
        name: 'The Beginning',
        difficulty: LevelDifficulty.easy,
        boardCols: 3,
        sectionLevelCounts: [20, 20, 20],
      ),
      const _ChapterBlueprint(
        name: 'Nature',
        difficulty: LevelDifficulty.medium,
        boardCols: 5,
        sectionLevelCounts: [20, 20],
      ),
      const _ChapterBlueprint(
        name: 'Cities',
        difficulty: LevelDifficulty.hard,
        boardCols: 7,
        sectionLevelCounts: [30],
      ),
      const _ChapterBlueprint(
        name: 'Animals',
        difficulty: LevelDifficulty.expert,
        boardCols: 9,
        sectionLevelCounts: [40],
      ),
    ];

    var runningTotal = blueprints.fold<int>(0, (sum, b) => sum + b.totalLevels);
    var continuationIndex = 0;
    while (runningTotal < _minimumTotalLevels) {
      final blueprint = _continuationBlueprint(continuationIndex);
      blueprints.add(blueprint);
      runningTotal += blueprint.totalLevels;
      continuationIndex++;
    }

    return _assignIds(blueprints);
  }

  /// Master-tier chapters: board size grows by one column every two
  /// chapters (12, 12, 13, 13, 14, ...), satisfying "12x12+". Section
  /// count alternates 2/3 for a bit of pacing variety.
  static _ChapterBlueprint _continuationBlueprint(int continuationIndex) {
    final themeCycle = continuationIndex ~/ _continuationThemes.length;
    final baseName = _continuationThemes[continuationIndex % _continuationThemes.length];
    final name = themeCycle == 0 ? baseName : '$baseName ${_cycleSuffix(themeCycle)}';
    final boardCols = 12 + (continuationIndex ~/ 2);
    final sectionCount = continuationIndex.isEven ? 2 : 3;

    return _ChapterBlueprint(
      name: name,
      difficulty: LevelDifficulty.master,
      boardCols: boardCols,
      sectionLevelCounts: List.filled(sectionCount, 30),
    );
  }

  static String _cycleSuffix(int cycle) {
    const numerals = ['II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];
    return cycle - 1 < numerals.length ? numerals[cycle - 1] : '${cycle + 1}';
  }

  static List<Chapter> _assignIds(List<_ChapterBlueprint> blueprints) {
    final chapters = <Chapter>[];
    var nextLevelId = 1;
    var chapterId = 1;
    var sectionId = 1;

    for (final blueprint in blueprints) {
      final chapterStart = nextLevelId;
      final sections = <Section>[];
      var sectionIndex = 1;

      for (final sectionLevels in blueprint.sectionLevelCounts) {
        final sectionStart = nextLevelId;
        final sectionEnd = nextLevelId + sectionLevels - 1;
        sections.add(
          Section(
            id: sectionId,
            chapterId: chapterId,
            index: sectionIndex,
            startLevelId: sectionStart,
            endLevelId: sectionEnd,
          ),
        );
        nextLevelId = sectionEnd + 1;
        sectionId++;
        sectionIndex++;
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

class _ChapterBlueprint {
  const _ChapterBlueprint({
    required this.name,
    required this.difficulty,
    required this.boardCols,
    required this.sectionLevelCounts,
  });

  final String name;
  final LevelDifficulty difficulty;
  final int boardCols;
  final List<int> sectionLevelCounts;

  int get totalLevels => sectionLevelCounts.fold(0, (a, b) => a + b);
}
