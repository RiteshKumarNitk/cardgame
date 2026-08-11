// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps

// Run: dart run tools/generate_artwork.dart
// Generates painted collection artwork — one themed portrait (3:4) per
// chapter collection — into content/artwork/. This is NOT bundled with
// the app (the game uses real photography); it exists as an art
// reference/repository. Every image is painted procedurally (gradients +
// silhouettes + accents): fully offline, deterministic, license-clean.
//
// NOTE: the user prefers real photos over generated art, so nothing in
// lib/ consumes these files. Keep them here for reference only.
//
// The asset file names MUST stay in sync with the theme keys in
// lib/features/levels/domain/services/chapter_theme.dart. These heroes
// are also the source for the per-level fragments produced by
// tools/generate_level_variants.dart.
//
// Dev-time only: uses the `image` package, declared as a dev_dependency.

import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

const _width = 900;
const _height = 1200;
const _outputDir = 'content/artwork';

void main() {
  Directory(_outputDir).createSync(recursive: true);

  final themes = <String, void Function(img.Image)>{
    'the_beginning': _paintTheBeginning,
    'nature': _paintNature,
    'cities': _paintCities,
    'animals': _paintAnimals,
    'ocean_depths': _paintOceanDepths,
    'mountain_peaks': _paintMountainPeaks,
    'desert_sands': _paintDesertSands,
    'winter_wonderland': _paintWinterWonderland,
    'space_odyssey': _paintSpaceOdyssey,
    'ancient_ruins': _paintAncientRuins,
    'enchanted_forest': _paintEnchantedForest,
    'neon_nights': _paintNeonNights,
    'candy_kingdom': _paintCandyKingdom,
    'sky_islands': _paintSkyIslands,
    'crystal_caves': _paintCrystalCaves,
    'legendary_realm': _paintLegendaryRealm,
  };

  for (final entry in themes.entries) {
    final canvas = img.Image(width: _width, height: _height);
    entry.value(canvas);
    final bytes = img.encodePng(canvas);
    File('$_outputDir/${entry.key}.png').writeAsBytesSync(bytes);
    final kb = (bytes.length / 1024).round();
    print('  wrote $_outputDir/${entry.key}.png (${kb} KB)');
  }

  print('✅ ${themes.length} collection artworks generated in $_outputDir');
}

// ── Color helpers ────────────────────────────────────────────────────

img.ColorRgb8 _c(int r, int g, int b) => img.ColorRgb8(r, g, b);

/// Translucent version of [color] (ColorRgba8's params are `int`).
img.ColorRgba8 _rgba(img.ColorRgb8 color, int alpha) =>
    img.ColorRgba8(color.r.toInt(), color.g.toInt(), color.b.toInt(), alpha);

/// Thick ring outline (drawCircle has no `thickness` in image 4.x).
void _circleRing(
  img.Image dst,
  int cx,
  int cy,
  int radius,
  int thickness,
  img.ColorRgb8 color,
) {
  final outer = radius + thickness;
  for (var y = cy - outer; y <= cy + outer; y++) {
    for (var x = cx - outer; x <= cx + outer; x++) {
      final d = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy)).toDouble();
      if (d >= radius && d <= outer) dst.setPixel(x, y, color);
    }
  }
}

img.ColorRgb8 _lerp(img.ColorRgb8 a, img.ColorRgb8 b, double t) {
  t = t.clamp(0.0, 1.0);
  return _c(
    (a.r + (b.r - a.r) * t).round(),
    (a.g + (b.g - a.g) * t).round(),
    (a.b + (b.b - a.b) * t).round(),
  );
}

// The `image` package's pixel store keeps alpha as-is (no compositing), so
// translucent drawing must blend manually against whatever is underneath.
void _blendPixel(img.Image dst, int x, int y, img.ColorRgba8 c) {
  if (x < 0 || x >= dst.width || y < 0 || y >= dst.height || c.a <= 0) return;
  if (c.a >= 255) {
    dst.setPixelRgb(x, y, c.r, c.g, c.b);
    return;
  }
  final base = dst.getPixel(x, y);
  final a = c.a / 255;
  dst.setPixelRgb(
    x,
    y,
    (base.r * (1 - a) + c.r * a).round(),
    (base.g * (1 - a) + c.g * a).round(),
    (base.b * (1 - a) + c.b * a).round(),
  );
}

void _blendCircle(img.Image dst, int cx, int cy, int radius, img.ColorRgba8 c) {
  final r2 = radius * radius;
  for (var y = cy - radius; y <= cy + radius; y++) {
    for (var x = cx - radius; x <= cx + radius; x++) {
      final dx = x - cx;
      final dy = y - cy;
      if (dx * dx + dy * dy <= r2) _blendPixel(dst, x, y, c);
    }
  }
}

/// Easier-to-compute alpha-blended polygon fill (used for soft light rays).
void _blendPolygon(
  img.Image dst,
  List<(double, double)> pts,
  img.ColorRgba8 c,
) {
  var minY = pts.map((p) => p.$2).reduce(min);
  var maxY = pts.map((p) => p.$2).reduce(max);
  for (var y = minY.floor(); y <= maxY.ceil() && y < dst.height; y++) {
    final xs = <double>[];
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];
      if ((a.$2 <= y && b.$2 > y) || (b.$2 <= y && a.$2 > y)) {
        final t = (y - a.$2) / (b.$2 - a.$2);
        xs.add(a.$1 + t * (b.$1 - a.$1));
      }
    }
    xs.sort();
    for (var i = 0; i + 1 < xs.length; i += 2) {
      final x0 = xs[i].round().clamp(0, dst.width - 1);
      final x1 = xs[i + 1].round().clamp(0, dst.width - 1);
      for (var x = x0; x <= x1; x++) {
        _blendPixel(dst, x, y, c);
      }
    }
  }
}

void _blendLine(
  img.Image dst,
  int x1,
  int y1,
  int x2,
  int y2,
  img.ColorRgba8 c,
) {
  final dx = (x2 - x1).abs();
  final dy = (y2 - y1).abs();
  final steps = dx > dy ? dx : dy;
  if (steps == 0) {
    _blendPixel(dst, x1, y1, c);
    return;
  }
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    _blendPixel(
      dst,
      (x1 + (x2 - x1) * t).round(),
      (y1 + (y2 - y1) * t).round(),
      c,
    );
  }
}

// ── Primitive drawing helpers ────────────────────────────────────────

/// Vertical gradient from [top] to [bottom] over [y0]..[y1].
void _vGradient(
  img.Image dst,
  int y0,
  int y1,
  img.ColorRgb8 top,
  img.ColorRgb8 bottom,
) {
  for (var y = y0; y < y1 && y < dst.height; y++) {
    final t = y1 == y0 ? 0.0 : (y - y0) / (y1 - y0);
    final c = _lerp(top, bottom, t);
    for (var x = 0; x < dst.width; x++) {
      dst.setPixel(x, y, c);
    }
  }
}

/// Fills every pixel below the curve [height](fraction of width) → height
/// fraction of the canvas (clamped), with [color].
void _fillBelow(
  img.Image dst,
  double Function(double xFrac) height,
  img.ColorRgb8 color,
) {
  for (var x = 0; x < dst.width; x++) {
    final y = (height(x / dst.width) * dst.height).round().clamp(0, dst.height - 1);
    for (var row = y; row < dst.height; row++) {
      dst.setPixel(x, row, color);
    }
  }
}

/// Convex-or-concave scanline polygon fill (works for any simple polygon).
void _fillPolygon(img.Image dst, List<(double, double)> pts, img.ColorRgb8 c) {
  var minY = pts.map((p) => p.$2).reduce(min);
  var maxY = pts.map((p) => p.$2).reduce(max);
  for (var y = minY.floor(); y <= maxY.ceil(); y++) {
    final xs = <double>[];
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];
      if ((a.$2 <= y && b.$2 > y) || (b.$2 <= y && a.$2 > y)) {
        final t = (y - a.$2) / (b.$2 - a.$2);
        xs.add(a.$1 + t * (b.$1 - a.$1));
      }
    }
    xs.sort();
    for (var i = 0; i + 1 < xs.length; i += 2) {
      final x0 = xs[i].round().clamp(0, dst.width - 1);
      final x1 = xs[i + 1].round().clamp(0, dst.width - 1);
      for (var x = x0; x <= x1; x++) {
        dst.setPixel(x, y, c);
      }
    }
  }
}

/// Soft glowing circle: [radius]-ish core with a translucent halo.
void _glowCircle(
  img.Image dst,
  int cx,
  int cy,
  int radius,
  img.ColorRgb8 color,
  int glowRadius,
) {
  for (var r = radius; r <= radius + glowRadius; r += 4) {
    final a = (60 * (1 - (r - radius) / (glowRadius + 1))).round();
    if (a <= 0) break;
    _blendCircle(dst, cx, cy, r, _rgba(color, a));
  }
  img.fillCircle(dst, x: cx, y: cy, radius: radius, color: color);
}

void _cloud(img.Image dst, int cx, int cy, int scale, img.ColorRgb8 color) {
  img.fillCircle(dst, x: cx - scale, y: cy, radius: scale, color: color);
  img.fillCircle(dst, x: cx + scale, y: cy, radius: scale, color: color);
  img.fillCircle(dst, x: cx, y: cy - scale ~/ 2, radius: (scale * 1.3).round(), color: color);
}

void _starField(
  img.Image dst,
  int count,
  int yMax,
  int seed,
  img.ColorRgb8 color,
) {
  final rng = Random(seed);
  for (var i = 0; i < count; i++) {
    final x = rng.nextInt(dst.width);
    final y = rng.nextInt(yMax);
    final size = rng.nextInt(3); // 0 → faint 1px, 1 → 1px, 2 → 2px
    if (size == 0) {
      _blendPixel(dst, x, y, _rgba(color, 130));
    } else {
      img.fillCircle(
        dst,
        x: x,
        y: y,
        radius: size == 2 ? 1 : 0,
        color: color,
      );
    }
  }
}

/// A "ridge" height curve — layered sine noise.
double _ridge(num x, int seed, double amp, double base, num freq) {
  final rng = Random(seed);
  final phase1 = rng.nextDouble() * 2 * pi;
  final phase2 = rng.nextDouble() * 2 * pi;
  return base +
      amp * sin(x * freq + phase1) +
      amp * 0.5 * sin(x * freq * 2.3 + phase2);
}

void _sun(img.Image dst, int cx, int cy, int radius, img.ColorRgb8 color) {
  _glowCircle(dst, cx, cy, radius, color, radius * 3);
  img.fillCircle(dst, x: cx, y: cy, radius: radius, color: color);
}

void _birds(img.Image dst, int seed) {
  final rng = Random(seed);
  final color = _c(30, 20, 40);
  for (var i = 0; i < 5; i++) {
    final x = rng.nextInt(dst.width);
    final y = 150 + rng.nextInt(250);
    final s = 8 + rng.nextInt(6);
    img.drawLine(
      dst,
      x1: x - s,
      y1: y,
      x2: x,
      y2: y - s ~/ 2,
      color: color,
      thickness: 2,
    );
    img.drawLine(
      dst,
      x1: x,
      y1: y - s ~/ 2,
      x2: x + s,
      y2: y,
      color: color,
      thickness: 2,
    );
  }
}

// ── Scenes ───────────────────────────────────────────────────────────

void _paintTheBeginning(img.Image dst) {
  _vGradient(dst, 0, _height, _c(200, 190, 240), _c(255, 224, 178));
  _vGradient(dst, _height ~/ 2, _height, _c(255, 224, 178), _c(255, 170, 130));
  _sun(dst, _width ~/ 2, (_height * 0.68).round(), 70, _c(255, 244, 214));
  _fillBelow(dst, (x) => _ridge(x, 11, 0.05, 0.86, 4), _c(160, 150, 210));
  _fillBelow(dst, (x) => _ridge(x, 12, 0.05, 0.94, 5), _c(120, 105, 175));
  _fillBelow(dst, (x) => 1.0, _c(88, 74, 140));
  _birds(dst, 7);
}

void _paintNature(img.Image dst) {
  _vGradient(dst, 0, _height, _c(126, 200, 250), _c(216, 245, 230));
  _sun(dst, (_width * 0.72).round(), 210, 52, _c(255, 240, 170));
  _cloud(dst, (_width * 0.3).round(), 170, 40, _c(255, 255, 255));
  _cloud(dst, (_width * 0.55).round(), 260, 28, _c(240, 248, 255));
  _fillBelow(dst, (x) => _ridge(x, 21, 0.045, 0.8, 3), _c(90, 165, 105));
  _fillBelow(dst, (x) => _ridge(x, 22, 0.05, 0.9, 4), _c(60, 130, 80));
  _fillBelow(dst, (x) => 1.0, _c(38, 96, 62));
  final rng = Random(23);
  for (var i = 0; i < 26; i++) {
    final x = rng.nextInt(_width);
    final y = 1080 + rng.nextInt(110);
    final flower = [_c(255, 120, 150), _c(255, 210, 100), _c(255, 255, 255)][i % 3];
    img.fillCircle(dst, x: x, y: y, radius: 5, color: flower);
  }
}

void _paintCities(img.Image dst) {
  _vGradient(dst, 0, _height, _c(30, 34, 88), _c(250, 120, 80));
  _moon(dst, (_width * 0.68).round(), 210, 42);
  _skyline(dst, 0.86, _c(18, 20, 52), 3001);
  _skyline(dst, 0.94, _c(10, 11, 32), 3002);
  _fillBelow(dst, (x) => 1.0, _c(6, 7, 22));
}

void _moon(img.Image dst, int cx, int cy, int radius) {
  _glowCircle(dst, cx, cy, radius, _c(255, 250, 225), radius * 2);
  img.fillCircle(dst, x: cx, y: cy, radius: radius, color: _c(255, 250, 225));
  img.fillCircle(dst, x: cx - radius ~/ 3, y: cy - radius ~/ 4, radius: radius ~/ 5, color: _c(238, 230, 200));
  img.fillCircle(dst, x: cx + radius ~/ 4, y: cy + radius ~/ 3, radius: radius ~/ 6, color: _c(238, 230, 200));
}

void _skyline(img.Image dst, double baseFrac, img.ColorRgb8 color, int seed) {
  final rng = Random(seed);
  var x = 0;
  while (x < dst.width) {
    final w = 40 + rng.nextInt(70);
    final h = (120 + rng.nextInt(340)).round();
    final y = (baseFrac * _height).round() - h;
    img.fillRect(dst, x1: x, y1: y, x2: x + w, y2: (baseFrac * _height).round(), color: color);
    // Lit windows
    final windowColor = rng.nextBool() ? _c(255, 200, 120) : _c(255, 240, 200);
    for (var wy = y + 12; wy < y + h - 12; wy += 26) {
      for (var wx = x + 8; wx < x + w - 8; wx += 20) {
        if (rng.nextDouble() < 0.4) {
          img.fillRect(dst, x1: wx, y1: wy, x2: wx + 8, y2: wy + 10, color: windowColor);
        }
      }
    }
    if (rng.nextBool()) {
      img.drawLine(dst, x1: x + w ~/ 2, y1: y, x2: x + w ~/ 2, y2: y - 30, color: color, thickness: 2);
    }
    x += w + 6;
  }
}

void _paintAnimals(img.Image dst) {
  _vGradient(dst, 0, _height, _c(255, 214, 165), _c(255, 150, 90));
  _sun(dst, (_width * 0.5).round(), (_height * 0.62).round(), 95, _c(255, 220, 150));
  _fillBelow(dst, (x) => _ridge(x, 31, 0.04, 0.9, 4), _c(150, 90, 60));
  _fillBelow(dst, (x) => 1.0, _c(110, 62, 40));
  _acacia(dst, (_width * 0.2).round(), 1080, _c(50, 30, 24));
  _acacia(dst, (_width * 0.78).round(), 1140, _c(50, 30, 24));
}

void _acacia(img.Image dst, int cx, int cy, img.ColorRgb8 color) {
  final h = 190;
  img.fillRect(dst, x1: cx - 5, y1: cy - h, x2: cx + 5, y2: cy, color: color);
  final crownY = cy - h - 12;
  img.drawLine(dst, x1: cx, y1: crownY, x2: cx - 70, y2: crownY - 14, color: color, thickness: 4);
  img.drawLine(dst, x1: cx, y1: crownY, x2: cx + 70, y2: crownY - 10, color: color, thickness: 4);
  for (final offset in [-70, -30, 10, 50, 70]) {
    img.fillCircle(dst, x: cx + offset, y: crownY - 12, radius: 16, color: color);
  }
}

void _paintOceanDepths(img.Image dst) {
  _vGradient(dst, 0, _height, _c(20, 90, 140), _c(10, 40, 80));
  // Light rays from the surface
  final rng = Random(41);
  for (var i = 0; i < 7; i++) {
    final x0 = rng.nextInt(_width);
    final w = 40 + rng.nextInt(50);
    _blendPolygon(
      dst,
      [
        (x0.toDouble(), 0.0),
        ((x0 + w).toDouble(), 0.0),
        (x0 + w + 260.0, _height.toDouble()),
        (x0 + 200.0, _height.toDouble()),
      ],
      _rgba(_c(150, 220, 255), 26),
    );
  }
  // Fish silhouettes
  for (var i = 0; i < 6; i++) {
    final x = 80 + rng.nextInt(_width - 160);
    final y = 260 + rng.nextInt(600);
    final s = 20 + rng.nextInt(18);
    final fish = _c(190, 235, 255);
    img.fillCircle(dst, x: x, y: y, radius: s, color: fish);
    _fillPolygon(
      dst,
      [
        ((x - s - 10).toDouble(), (y - s ~/ 2).toDouble()),
        ((x - s - 34).toDouble(), (y - s ~/ 4).toDouble()),
        ((x - s - 10).toDouble(), (y + s ~/ 4).toDouble()),
      ],
      fish,
    );
  }
  // Bubbles
  for (var i = 0; i < 30; i++) {
    final x = rng.nextInt(_width);
    final y = rng.nextInt(_height - 200);
    final r = 2 + rng.nextInt(4);
    _circleRing(dst, x, y, r, 1, _c(200, 240, 255));
  }
  _fillBelow(dst, (x) => 0.94, _c(8, 26, 52));
}

void _paintMountainPeaks(img.Image dst) {
  _vGradient(dst, 0, _height, _c(150, 190, 220), _c(235, 242, 250));
  _fillBelow(dst, (x) => _mountainCurve(x, 51, 0.9, 9), _c(120, 155, 190));
  _fillBelow(dst, (x) => _mountainCurve(x, 52, 1.02, 11), _c(70, 100, 140));
  _snowCaps(dst, 51, _c(235, 242, 250));
  _snowCaps(dst, 52, _c(210, 224, 240));
  _fillBelow(dst, (x) => 1.0, _c(40, 62, 96));
}

double _mountainCurve(num x, int seed, double base, num freq) {
  final rng = Random(seed);
  final phase = rng.nextDouble() * 2 * pi;
  // Sharp zig-zag peaks instead of smooth ridges.
  final zig = x * freq * 2;
  final t = ((zig + phase) % 2.0) - 1.0;
  final v = (0.9 - (0.4 * pow(1 - t.abs(), 1.2))).toDouble();
  return base * v;
}

void _snowCaps(img.Image dst, int seed, img.ColorRgb8 snow) {
  for (var x = 0; x < dst.width; x++) {
    final topY = (_mountainCurve(x, seed, 1.0, 9) * dst.height).round();
    final peak = _ridge(x, seed + 100, 0.02, 1.0, 9);
    // Snow only on the upper part of each peak.
    final capH = (90 * (1 - peak.abs())).round() + 40;
    for (var y = topY; y < topY + capH && y < dst.height; y++) {
      dst.setPixel(x, y, snow);
    }
  }
}

void _paintDesertSands(img.Image dst) {
  _vGradient(dst, 0, _height, _c(255, 226, 190), _c(255, 160, 90));
  _sun(dst, (_width * 0.5).round(), 430, 105, _c(255, 246, 210));
  _fillBelow(dst, (x) => _ridge(x, 61, 0.06, 0.82, 3.5), _c(235, 170, 110));
  _fillBelow(dst, (x) => _ridge(x, 62, 0.07, 0.92, 4.5), _c(210, 135, 85));
  _fillBelow(dst, (x) => 1.0, _c(170, 105, 62));
}

void _paintWinterWonderland(img.Image dst) {
  _vGradient(dst, 0, _height, _c(24, 30, 74), _c(90, 110, 170));
  // Aurora bands
  for (final (y0, color) in [(240, _c(90, 255, 200)), (320, _c(140, 140, 255)), (400, _c(90, 255, 200))]) {
    for (var x = 0; x < dst.width; x++) {
      final wobble = _ridge(x, 71 + y0, 0.06, 0.5, 3);
      final y = (y0 + wobble * 80).round();
      for (var dy = 0; dy < 46; dy += 6) {
        final a = (30 * (1 - dy / 46)).round();
        _blendPixel(dst, x, y + dy, _rgba(color, a));
      }
    }
  }
  _moon(dst, (_width * 0.7).round(), 170, 40);
  _starField(dst, 60, 520, 72, _c(255, 255, 255));
  _fillBelow(dst, (x) => _ridge(x, 73, 0.04, 0.9, 4), _c(150, 175, 215));
  _fillBelow(dst, (x) => 1.0, _c(110, 132, 175));
  final rng = Random(74);
  for (var i = 0; i < 40; i++) {
    final x = rng.nextInt(_width);
    final y = rng.nextInt(_height);
    img.fillCircle(dst, x: x, y: y, radius: 2, color: _c(240, 248, 255));
  }
}

void _paintSpaceOdyssey(img.Image dst) {
  _vGradient(dst, 0, _height, _c(8, 6, 30), _c(38, 10, 60));
  // Nebula glow
  _glowCircle(dst, (_width * 0.4).round(), 700, 130, _c(120, 40, 140), 260);
  _glowCircle(dst, (_width * 0.75).round(), 400, 80, _c(30, 90, 160), 200);
  _starField(dst, 220, _height, 81, _c(255, 255, 255));
  // Ringed planet
  final cx = (_width * 0.68).round();
  final cy = 420;
  img.fillCircle(dst, x: cx, y: cy, radius: 95, color: _c(240, 160, 90));
  img.fillCircle(dst, x: cx - 30, y: cy - 25, radius: 22, color: _c(200, 110, 60));
  for (var i = 0; i < 46; i++) {
    final t = i / 45;
    final x = (cx - 190 + t * 380).round();
    final y = (cy + sin(t * pi) * 42 - 10).round();
    img.fillRect(dst, x1: x, y1: y, x2: x + 3, y2: y + 7, color: _c(255, 220, 160));
  }
  // Small moon
  _glowCircle(dst, 180, 880, 26, _c(200, 210, 230), 40);
}

void _paintAncientRuins(img.Image dst) {
  _vGradient(dst, 0, _height, _c(70, 50, 120), _c(255, 150, 90));
  _sun(dst, (_width * 0.28).round(), 330, 60, _c(255, 210, 140));
  _fillBelow(dst, (x) => _ridge(x, 91, 0.04, 0.92, 3), _c(120, 80, 60));
  _fillBelow(dst, (x) => 1.0, _c(80, 50, 38));
  // Broken columns
  final stone = _c(60, 44, 52);
  final cols = [240, 390, 540, 690];
  for (var i = 0; i < cols.length; i++) {
    final cx = cols[i];
    final h = 150 + (i.isEven ? 90 : 0);
    img.fillRect(dst, x1: cx - 26, y1: 1000 - h, x2: cx + 26, y2: 1000, color: stone);
    img.fillRect(dst, x1: cx - 36, y1: 1000 - h - 16, x2: cx + 36, y2: 1000 - h + 12, color: stone);
    if (i == 1) {
      // A fallen capital
      img.fillRect(dst, x1: cx - 90, y1: 1100, x2: cx - 20, y2: 1128, color: stone);
    }
  }
  // Broken arch between the first two columns
  img.drawLine(dst, x1: 240, y1: 1000 - 240, x2: 390, y2: 1000 - 240, color: stone, thickness: 14);
  _moon(dst, 660, 170, 34);
}

void _paintEnchantedForest(img.Image dst) {
  _vGradient(dst, 0, _height, _c(20, 40, 40), _c(8, 26, 22));
  // Glowing canopy lights
  for (var i = 0; i < 24; i++) {
    final x = (i * 37 + 13) % _width;
    final y = 80 + (i * 53) % 420;
    _glowCircle(dst, x, y, 4, _c(150, 255, 190), 26);
  }
  // Tree trunks
  final trunk = _c(20, 12, 14);
  final rng = Random(101);
  for (var i = 0; i < 12; i++) {
    final x = rng.nextInt(_width);
    final topY = 420 + rng.nextInt(300);
    img.fillRect(dst, x1: x - 8, y1: topY, x2: x + 8, y2: _height, color: trunk);
    final canopy = _c(16, 48, 38);
    img.fillCircle(dst, x: x, y: topY, radius: 60 + rng.nextInt(40), color: canopy);
    img.fillCircle(dst, x: x - 45, y: topY + 30, radius: 36, color: _c(12, 40, 32));
    img.fillCircle(dst, x: x + 48, y: topY + 22, radius: 32, color: _c(12, 40, 32));
  }
  // Fireflies
  for (var i = 0; i < 34; i++) {
    final x = rng.nextInt(_width);
    final y = 500 + rng.nextInt(600);
    _glowCircle(dst, x, y, 2, _c(210, 255, 140), 14);
  }
}

void _paintNeonNights(img.Image dst) {
  _vGradient(dst, 0, 700, _c(24, 10, 60), _c(70, 20, 80));
  _vGradient(dst, 700, _height, _c(70, 20, 80), _c(10, 8, 30));
  // Neon sun with scanlines
  for (var i = 0; i < 50; i++) {
    final t = i / 49;
    final y = (700 - 8 - t * 580).round();
    final half = (sqrt(1 - t * t) * 290).round();
    final a = (i % 4 == 0 ? 140 : 220);
    _blendLine(
      dst,
      _width ~/ 2 - half,
      y,
      _width ~/ 2 + half,
      y,
      img.ColorRgba8(255, 80, 120, a),
    );
  }
  // Horizon line
  img.drawLine(dst, x1: 0, y1: 700, x2: _width, y2: 700, color: _c(255, 80, 120), thickness: 3);
  // Perspective grid
  for (var i = 0; i < 9; i++) {
    final x = _width ~/ 2 + ((i - 4) * (i - 4) * 14);
    img.drawLine(dst, x1: _width ~/ 2, y1: 700, x2: x, y2: _height, color: _c(140, 60, 200), thickness: 2);
  }
  for (var i = 1; i <= 6; i++) {
    final y = 700 + (i * i * 14);
    img.drawLine(dst, x1: 0, y1: y, x2: _width, y2: y, color: _c(140, 60, 200), thickness: 2);
  }
  _starField(dst, 80, 620, 111, _c(255, 255, 255));
}

void _paintCandyKingdom(img.Image dst) {
  _vGradient(dst, 0, _height, _c(255, 210, 230), _c(255, 240, 200));
  _cloud(dst, 140, 150, 38, _c(255, 255, 255));
  _cloud(dst, 760, 200, 44, _c(255, 255, 255));
  // Giant lollipops
  final rng = Random(121);
  for (var i = 0; i < 5; i++) {
    final x = 110 + i * 170;
    final topY = 520 + (i % 3) * 60;
    final colors = [_c(255, 110, 150), _c(140, 200, 255), _c(255, 190, 90), _c(170, 240, 160), _c(220, 140, 255)];
    final base = colors[i % colors.length];
    img.fillRect(dst, x1: x - 10, y1: topY, x2: x + 10, y2: _height, color: _c(255, 255, 255));
    for (var ring = 0; ring < 7; ring++) {
      final r = 88 - ring * 12;
      _circleRing(
        dst,
        x,
        topY - 70,
        r,
        12,
        ring.isEven ? base : _c(255, 255, 255),
      );
    }
  }
  _fillBelow(dst, (x) => _ridge(x, 122, 0.04, 0.94, 4), _c(255, 170, 190));
  _fillBelow(dst, (x) => 1.0, _c(250, 120, 150));
  // Sprinkles
  for (var i = 0; i < 60; i++) {
    final x = rng.nextInt(_width);
    final y = 1090 + rng.nextInt(100);
    final s = [_c(255, 255, 255), _c(255, 240, 120), _c(120, 220, 255)][i % 3];
    img.fillRect(dst, x1: x, y1: y, x2: x + 9, y2: y + 5, color: s);
  }
}

void _paintSkyIslands(img.Image dst) {
  _vGradient(dst, 0, _height, _c(110, 200, 250), _c(210, 245, 255));
  _sun(dst, 620, 200, 48, _c(255, 250, 220));
  _cloud(dst, 200, 260, 52, _c(255, 255, 255));
  _cloud(dst, 700, 560, 60, _c(255, 255, 255));
  _cloud(dst, 320, 760, 46, _c(255, 255, 255));
  // Floating islands
  for (var i = 0; i < 4; i++) {
    final x = 130 + i * 190 + (i % 2) * 40;
    final topY = 480 + (i % 3) * 130;
    final w = 150 + (i % 2) * 40;
    final green = _lerp(_c(90, 200, 110), _c(60, 160, 90), (i % 2) * 0.6);
    img.fillCircle(dst, x: x, y: topY, radius: w, color: green);
    _fillPolygon(
      dst,
      [
        ((x - w * 0.8).toDouble(), (topY + 40).toDouble()),
        (x.toDouble(), (topY + 150 + w * 0.9).toDouble()),
        ((x + w * 0.8).toDouble(), (topY + 40).toDouble()),
      ],
      _c(140, 110, 70),
    );
    // Waterfall
    img.drawLine(dst, x1: x, y1: topY + 120, x2: x, y2: topY + 320, color: _c(220, 245, 255), thickness: 8);
    img.drawLine(dst, x1: x - 6, y1: topY + 130, x2: x - 6, y2: topY + 300, color: _c(255, 255, 255), thickness: 2);
  }
  _birds(dst, 131);
}

void _paintCrystalCaves(img.Image dst) {
  _vGradient(dst, 0, _height, _c(16, 26, 60), _c(50, 20, 70));
  // Stalactites
  final rng = Random(141);
  for (var i = 0; i < 14; i++) {
    final x = rng.nextInt(_width);
    final w = 16 + rng.nextInt(30);
    final h = 120 + rng.nextInt(300);
    _fillPolygon(dst, [(x - w / 2, 0.0), (x + w / 2, 0.0), (x.toDouble(), h.toDouble())], _c(30, 16, 60));
  }
  // Crystal clusters
  for (var i = 0; i < 9; i++) {
    final x = 60 + rng.nextInt(_width - 120);
    final y = 820 + rng.nextInt(260);
    final hues = [_c(150, 220, 255), _c(190, 140, 255), _c(255, 160, 220), _c(120, 255, 200)];
    final c = hues[i % hues.length];
    for (var spike = -1; spike <= 1; spike++) {
      final h = 90 + rng.nextInt(110) + spike.abs() * 30;
      final w = 26 + rng.nextInt(18);
      _fillPolygon(
        dst,
        [
          ((x + spike * 46 - w / 2).toDouble(), y.toDouble()),
          ((x + spike * 46 + w / 2).toDouble(), y.toDouble()),
          ((x + spike * 52).toDouble(), (y - h).toDouble()),
        ],
        c,
      );
    }
    _glowCircle(dst, x, y - 190, 6, c, 40);
  }
  _fillBelow(dst, (x) => 0.94, _c(10, 8, 34));
}

void _paintLegendaryRealm(img.Image dst) {
  _vGradient(dst, 0, _height, _c(120, 60, 110), _c(255, 130, 70));
  _sun(dst, (_width * 0.5).round(), 620, 120, _c(255, 240, 190));
  _fillBelow(dst, (x) => _mountainCurve(x, 151, 0.88, 8), _c(60, 30, 80));
  // Castle silhouette
  final castle = _c(24, 14, 40);
  final baseY = (_height * 0.86).round();
  img.fillRect(dst, x1: 320, y1: baseY - 240, x2: 580, y2: baseY, color: castle);
  img.fillRect(dst, x1: 300, y1: baseY - 200, x2: 340, y2: baseY, color: castle);
  img.fillRect(dst, x1: 560, y1: baseY - 200, x2: 600, y2: baseY, color: castle);
  for (final tx in [340, 440, 540]) {
    img.fillRect(dst, x1: tx, y1: baseY - 300, x2: tx + 20, y2: baseY - 240, color: castle);
    _fillPolygon(
      dst,
      [
        ((tx - 8).toDouble(), (baseY - 300).toDouble()),
        ((tx + 28).toDouble(), (baseY - 300).toDouble()),
        ((tx + 10).toDouble(), (baseY - 330).toDouble()),
      ],
      castle,
    );
  }
  // Arrow slits
  for (final sx in [380, 480]) {
    img.fillRect(dst, x1: sx, y1: baseY - 190, x2: sx + 8, y2: baseY - 150, color: _c(255, 200, 120));
  }
  img.fillRect(dst, x1: 432, y1: baseY - 110, x2: 468, y2: baseY - 70, color: _c(255, 200, 120));
  _fillBelow(dst, (x) => 1.0, _c(20, 12, 34));
  _birds(dst, 152);
}
