// Verifies the Photo Puzzles manifest: parsing valid entries, rejecting
// malformed ones, de-duplicating ids, and (via dart:io) that the real
// bundled manifest.json stays well-formed and loadable.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/features/photos/domain/photo_catalog.dart';
import 'package:puzzle_cards/features/photos/domain/photo_puzzle.dart';

void main() {
  group('PhotoCatalog.parse', () {
    test('parses local asset and internet url entries', () {
      final photos = PhotoCatalog.parse('''
        {
          "photos": [
            {"id": "beach", "title": "Beach", "image": "assets/images/photos/beach.jpg"},
            {"id": "sunset", "title": "Sunset", "url": "https://example.com/sunset.jpg"}
          ]
        }
      ''');

      expect(photos, hasLength(2));
      final beach = photos[0];
      expect(beach.id, 'beach');
      expect(beach.isLocal, isTrue);
      expect(beach.image, 'assets/images/photos/beach.jpg');

      final sunset = photos[1];
      expect(sunset.isLocal, isFalse);
      expect(sunset.image, 'https://example.com/sunset.jpg');
    });

    test('skips entries without id, title, or any image source', () {
      final photos = PhotoCatalog.parse('''
        {
          "photos": [
            {"id": "no_title", "url": "https://example.com/x.jpg"},
            {"title": "no_id", "url": "https://example.com/x.jpg"},
            {"id": "no_image", "title": "No Image"},
            {"id": "good", "title": "Good", "url": "https://example.com/good.jpg"}
          ]
        }
      ''');

      expect(photos, hasLength(1));
      expect(photos.single.id, 'good');
    });

    test('de-duplicates entries sharing an id', () {
      final photos = PhotoCatalog.parse('''
        {
          "photos": [
            {"id": "same", "title": "A", "url": "https://example.com/a.jpg"},
            {"id": "same", "title": "B", "url": "https://example.com/b.jpg"}
          ]
        }
      ''');

      expect(photos, hasLength(1));
      expect(photos.single.title, 'A');
    });

    test('degrades to an empty list on malformed json', () {
      expect(PhotoCatalog.parse('not json'), isEmpty);
      expect(PhotoCatalog.parse('{"photos": "oops"}'), isEmpty);
      expect(PhotoCatalog.parse('{"other": []}'), isEmpty);
    });
  });

  test('the bundled manifest.json is well-formed and loadable', () {
    // Read via dart:io — no asset bundle needed in a plain test.
    final raw = File(
      'assets/images/photos/manifest.json',
    ).readAsStringSync();

    final photos = PhotoCatalog.parse(raw);
    expect(photos, isNotEmpty, reason: 'manifest should ship with photos');
    for (final PhotoPuzzle photo in photos) {
      expect(photo.id, isNotEmpty);
      expect(photo.title, isNotEmpty);
      expect(photo.image, isNotEmpty);
    }
  });
}
