// Verifies level image resolution: every level maps to one of the bundled
// real photos (assets/images/collections/level_1.jpg .. level_300.jpg),
// cycling after photo 300, and the Daily Challenge resolves to a
// date-seeded internet photo.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/features/levels/domain/services/chapter_catalog.dart';
import 'package:puzzle_cards/features/puzzle/domain/puzzle_image.dart';

void main() {
  test('levels resolve to bundled real photos', () {
    expect(puzzleImageUrlFor(1), 'assets/images/collections/level_1.jpg');
    expect(puzzleImageUrlFor(2), 'assets/images/collections/level_2.jpg');
    expect(puzzleImageUrlFor(61), 'assets/images/collections/level_61.jpg');
    expect(puzzleImageUrlFor(300), 'assets/images/collections/level_300.jpg');
  });

  test('photos cycle after level 300', () {
    expect(puzzleImageUrlFor(301), 'assets/images/collections/level_1.jpg');
    expect(puzzleImageUrlFor(600), 'assets/images/collections/level_300.jpg');
    expect(puzzleImageUrlFor(601), 'assets/images/collections/level_1.jpg');
  });

  test('every level resolves to an existing photo path', () {
    for (final levelId in [
      1,
      150,
      300,
      ChapterCatalog.totalLevelCount,
    ]) {
      final url = puzzleImageUrlFor(levelId);
      expect(url, startsWith('assets/images/collections/level_'));
      expect(url, endsWith('.jpg'));
      expect(
        url,
        isNot(contains('level_301')),
        reason: 'no photo exists past level_300',
      );
    }
  });

  test('daily challenge uses a date-seeded internet photo', () {
    expect(
      puzzleImageUrlForDaily('2026-08-11'),
      'https://picsum.photos/seed/puzzle-cards-daily-2026-08-11/600/800',
    );
    // Different days resolve to different photos.
    expect(
      puzzleImageUrlForDaily('2026-08-11'),
      isNot(puzzleImageUrlForDaily('2026-08-12')),
    );
  });
}
