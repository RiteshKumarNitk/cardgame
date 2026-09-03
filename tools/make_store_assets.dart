// Generates Play Store graphics from the existing brand art.
//   dart run tools/make_store_assets.dart
// Outputs into docs/store-assets/.
//
// - icon-512.png            512x512, opaque, from assets/images/suitclash.png
// - feature-graphic-1024x500.png  brand-blue field with the logo centred
//
// Not shipped in the app. Uses the `image` dev-dependency.

import 'dart:io';
import 'package:image/image.dart' as img;

const brandR = 0x01, brandG = 0x75, brandB = 0xC2; // #0175C2

void main() {
  final srcBytes = File('assets/images/suitclash.png').readAsBytesSync();
  final logo = img.decodeImage(srcBytes);
  if (logo == null) {
    stderr.writeln('Could not decode assets/images/suitclash.png');
    exit(1);
  }

  Directory('docs/store-assets').createSync(recursive: true);

  // ── 512 icon ──────────────────────────────────────────────────────
  final icon = img.copyResize(
    logo,
    width: 512,
    height: 512,
    interpolation: img.Interpolation.cubic,
  );
  // Flatten onto opaque brand blue in case the source has any alpha.
  final iconBg = img.Image(width: 512, height: 512)
    ..clear(img.ColorRgb8(brandR, brandG, brandB));
  img.compositeImage(iconBg, icon);
  File('docs/store-assets/icon-512.png')
      .writeAsBytesSync(img.encodePng(iconBg));

  // ── 1024x500 feature graphic ─────────────────────────────────────
  final feature = img.Image(width: 1024, height: 500)
    ..clear(img.ColorRgb8(brandR, brandG, brandB));
  // Subtle darker band at the bottom for depth.
  img.fillRect(
    feature,
    x1: 0,
    y1: 430,
    x2: 1024,
    y2: 500,
    color: img.ColorRgb8(
      (brandR * 0.82).round(),
      (brandG * 0.82).round(),
      (brandB * 0.82).round(),
    ),
  );
  const logoH = 380;
  final scaledLogo = img.copyResize(
    logo,
    width: logoH,
    height: logoH,
    interpolation: img.Interpolation.cubic,
  );
  img.compositeImage(
    feature,
    scaledLogo,
    dstX: (1024 - logoH) ~/ 2,
    dstY: (500 - logoH) ~/ 2,
  );
  File('docs/store-assets/feature-graphic-1024x500.png')
      .writeAsBytesSync(img.encodePng(feature));

  stdout.writeln('Wrote docs/store-assets/icon-512.png');
  stdout.writeln('Wrote docs/store-assets/feature-graphic-1024x500.png');
}
