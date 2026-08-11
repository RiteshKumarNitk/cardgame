// ignore_for_file: avoid_print

// Run: dart run tools/generate_level_variants.dart
//
// NOTE: the game currently uses the developer's real photos (see
// lib/features/puzzle/domain/puzzle_image.dart), so this tool's output is
// NOT bundled or consumed — it is kept as an optional art pipeline.
//
// Generates per-level puzzle images from the 16 themed chapter artworks
// (content/artwork/<theme>.png, produced by tools/generate_artwork.dart).
// For every theme it writes 32 variants —
// a deterministic crop window (zoom + pan) of the artwork plus a subtle
// color grade (hue/saturation/brightness/contrast) — as 600x800 JPGs
// into assets/images/collections/<theme>/v_1.jpg .. v_32.jpg.
//
// The "one painting, many fragments" idea is the point: every level in a
// chapter shows a different on-theme fragment of that chapter's artwork,
// so a section's mosaic reads as pieces of a single collection, and the
// level images always match the chapter theme (Nature shows nature art,
// Candy Kingdom shows candy art).
//
// v_1 is always the full artwork, unmodified — the same image the
// Collections Showcase displays as the chapter hero.
//
// MUST stay in sync with the theme keys in
// lib/features/levels/domain/services/chapter_theme.dart and the variant
// count there (kVariantsPerTheme).
//
// Dev-time only: uses the `image` package, declared as a dev_dependency.

import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const List<String> themes = [
  'the_beginning',
  'nature',
  'cities',
  'animals',
  'ocean_depths',
  'mountain_peaks',
  'desert_sands',
  'winter_wonderland',
  'space_odyssey',
  'ancient_ruins',
  'enchanted_forest',
  'neon_nights',
  'candy_kingdom',
  'sky_islands',
  'crystal_caves',
  'legendary_realm',
];

const int variantsPerTheme = 32;

const int srcWidth = 900;
const int srcHeight = 1200;
const int outWidth = 600;
const int outHeight = 800;

const String outputDir = 'content/artwork';

void main() {
  final root = Directory(outputDir);
  if (!root.existsSync()) {
    print('Run tools/generate_artwork.dart first — no $outputDir found.');
    exitCode = 1;
    return;
  }

  for (final theme in themes) {
    final srcBytes = File('$outputDir/$theme.png').readAsBytesSync();
    final src = img.decodeImage(srcBytes);
    if (src == null) {
      print('  SKIP $theme: could not decode $outputDir/$theme.png');
      continue;
    }

    final themeDir = Directory('$outputDir/$theme');
    themeDir.createSync(recursive: true);

    for (var v = 1; v <= variantsPerTheme; v++) {
      final rng = Random(theme.hashCode * 31 + v * 7919);

      img.Image variant;
      if (v == 1) {
        // Hero variant: the full artwork, unmodified.
        variant = img.copyResize(src, width: outWidth, height: outHeight);
      } else {
        // Crop a deterministic window: zoom 1.0-1.6x, panned around the
        // canvas so each variant frames a different part of the scene.
        final zoom = 1.0 + rng.nextDouble() * 0.6;
        final winW = (srcWidth / zoom).round();
        final winH = (srcHeight / zoom).round();
        final panX = (rng.nextDouble() * (srcWidth - winW)).round();
        final panY = (rng.nextDouble() * (srcHeight - winH)).round();
        variant = img.copyCrop(src, x: panX, y: panY, width: winW, height: winH);
        variant = img.copyResize(variant, width: outWidth, height: outHeight);

        // Subtle deterministic color grade — same scene, different mood.
        final hue = (rng.nextDouble() - 0.5) * 60; // ±30 degrees
        final saturation = 0.82 + rng.nextDouble() * 0.36; // 0.82-1.18
        final brightness = 0.9 + rng.nextDouble() * 0.2; // 0.9-1.1
        final contrast = 0.92 + rng.nextDouble() * 0.16; // 0.92-1.08
        variant = img.adjustColor(
          variant,
          hue: hue,
          saturation: saturation,
          brightness: brightness,
          contrast: contrast,
        );
      }

      final bytes = img.encodeJpg(variant, quality: 72);
      File('${themeDir.path}/v_$v.jpg').writeAsBytesSync(bytes);
    }

    final kb = (Directory(themeDir.path)
                .listSync()
                .fold<int>(0, (sum, f) => sum + File(f.path).lengthSync()) /
            1024)
        .round();
    print('  wrote $variantsPerTheme variants for $theme ($kb KB total)');
  }

  print('✅ ${themes.length * variantsPerTheme} level images in $outputDir');
}
