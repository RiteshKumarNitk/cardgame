// Unit tests for ChapterCatalog: the procedurally-generated chapter/section
// map that every level's difficulty and board size is derived from. Pure
// Dart, no widgets, no Hive.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/features/levels/domain/entities/level.dart';
import 'package:puzzle_cards/features/levels/domain/services/chapter_catalog.dart';

void main() {
  group('hand-authored chapters 1-4', () {
    test('match the exact spec: name, difficulty, board size, level range', () {
      final chapters = ChapterCatalog.chapters;

      expect(chapters[0].name, 'The Beginning');
      expect(chapters[0].difficulty, LevelDifficulty.easy);
      expect(chapters[0].boardCols, 3);
      expect(chapters[0].startLevelId, 1);
      expect(chapters[0].endLevelId, 60);
      expect(chapters[0].sections, hasLength(3));

      expect(chapters[1].name, 'Nature');
      expect(chapters[1].difficulty, LevelDifficulty.medium);
      expect(chapters[1].boardCols, 5);
      expect(chapters[1].startLevelId, 61);
      expect(chapters[1].endLevelId, 100);
      expect(chapters[1].sections, hasLength(2));

      expect(chapters[2].name, 'Cities');
      expect(chapters[2].difficulty, LevelDifficulty.hard);
      expect(chapters[2].boardCols, 7);
      expect(chapters[2].startLevelId, 101);
      expect(chapters[2].endLevelId, 130);
      expect(chapters[2].sections, hasLength(1));

      expect(chapters[3].name, 'Animals');
      expect(chapters[3].difficulty, LevelDifficulty.expert);
      expect(chapters[3].boardCols, 9);
      expect(chapters[3].startLevelId, 131);
      expect(chapters[3].endLevelId, 170);
      expect(chapters[3].sections, hasLength(1));
    });

    test('sections tile the chapter\'s level range with no gaps or overlaps', () {
      for (final chapter in ChapterCatalog.chapters) {
        var expectedNext = chapter.startLevelId;
        for (final section in chapter.sections) {
          expect(section.startLevelId, expectedNext);
          expect(section.chapterId, chapter.id);
          expectedNext = section.endLevelId + 1;
        }
        expect(expectedNext - 1, chapter.endLevelId);
      }
    });
  });

  group('continuation chapters', () {
    test('reach at least 1080 total levels', () {
      expect(ChapterCatalog.totalLevelCount, greaterThanOrEqualTo(1080));
    });

    test('are all Master difficulty with board size at least 12', () {
      for (final chapter in ChapterCatalog.chapters.skip(4)) {
        expect(chapter.difficulty, LevelDifficulty.master);
        expect(chapter.boardCols, greaterThanOrEqualTo(12));
      }
    });

    test('chapters tile levels 1..totalLevelCount with no gaps or overlaps', () {
      var expectedNext = 1;
      for (final chapter in ChapterCatalog.chapters) {
        expect(chapter.startLevelId, expectedNext);
        expectedNext = chapter.endLevelId + 1;
      }
      expect(expectedNext - 1, ChapterCatalog.totalLevelCount);
    });
  });

  group('chapterForLevel / sectionForLevel', () {
    test('resolves boundary levels to the correct chapter', () {
      expect(ChapterCatalog.chapterForLevel(1).name, 'The Beginning');
      expect(ChapterCatalog.chapterForLevel(60).name, 'The Beginning');
      expect(ChapterCatalog.chapterForLevel(61).name, 'Nature');
      expect(ChapterCatalog.chapterForLevel(170).name, 'Animals');
      expect(ChapterCatalog.chapterForLevel(171).difficulty, LevelDifficulty.master);
    });

    test('resolves boundary levels to the correct section', () {
      final section1 = ChapterCatalog.sectionForLevel(1);
      expect(section1.index, 1);
      expect(section1.startLevelId, 1);
      expect(section1.endLevelId, 20);

      final section2 = ChapterCatalog.sectionForLevel(21);
      expect(section2.index, 2);
      expect(section2.chapterId, 1);
    });

    test('throws for a level id outside the catalog', () {
      expect(
        () => ChapterCatalog.chapterForLevel(ChapterCatalog.totalLevelCount + 1),
        throwsArgumentError,
      );
      expect(() => ChapterCatalog.chapterForLevel(0), throwsArgumentError);
    });
  });
}
