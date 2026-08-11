import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'photo_puzzle.dart';

/// Loads the playable photo puzzles from `assets/images/photos/
/// manifest.json` — a plain-JSON list the developer edits to add their own
/// images (bundled assets or internet URLs) without touching code. See
/// the README in that folder.
abstract final class PhotoCatalog {
  static const String manifestPath = 'assets/images/photos/manifest.json';

  /// Reads and parses the manifest. Any read/parse failure degrades to an
  /// empty list (the page shows its how-to-add empty state) instead of
  /// crashing the app.
  static Future<List<PhotoPuzzle>> load() async {
    try {
      final raw = await rootBundle.loadString(manifestPath);
      return parse(raw);
    } catch (_) {
      return const [];
    }
  }

  /// Pure parse of a manifest string — testable without assets.
  static List<PhotoPuzzle> parse(String rawJson) {
    try {
      final data = jsonDecode(rawJson);
      if (data is! Map<String, dynamic>) return const [];
      final photos = data['photos'];
      if (photos is! List) return const [];

      final result = <PhotoPuzzle>[];
      final seen = <String>{};
      for (final entry in photos) {
        if (entry is! Map) continue;
        final photo = PhotoPuzzle.tryParse(
          Map<String, dynamic>.from(entry),
        );
        if (photo == null || !seen.add(photo.id)) continue;
        result.add(photo);
      }
      return result;
    } catch (_) {
      return const [];
    }
  }
}
