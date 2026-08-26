import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Pre-computed cover-scale layout for the puzzle image, resolved once at
/// the board level and shared by every tile — the single coordinate space
/// every cell crops from.
///
/// This is the ONLY place that computes cover-scale and per-cell geometry.
/// A tile never re-derives its own size from the image; it asks this
/// layout for the exact source rectangle to draw into whatever canvas size
/// it is actually given. That is what guarantees the reconstructed image
/// has no gaps and no seams: every cell's source rect is derived from the
/// same [boardW]/[boardH]/[cols]/[rows]/[gap] the GridView itself uses to
/// size that cell, not from the image's own scaled dimensions (which only
/// coincidentally match the board's cell grid when the image's aspect
/// ratio happens to equal the board's — never guaranteed for arbitrary
/// photos).
class ImageLayout {
  factory ImageLayout({
    required double imgW,
    required double imgH,
    required double boardW,
    required double boardH,
    required int cols,
    required int rows,
    double gap = 0,
  }) {
    // Cover-fit: scale just enough that the image fully covers the board
    // on both axes (the larger of the two per-axis scales).
    final scale = math.max(boardW / imgW, boardH / imgH);
    final scaledW = imgW * scale;
    final scaledH = imgH * scale;

    // The scaled image is centered on the board; whichever axis isn't the
    // cover-limiting one overflows equally on both sides.
    final offsetX = (boardW - scaledW) / 2;
    final offsetY = (boardH - scaledH) / 2;

    // The board's own per-cell pixel size — identical to what the
    // GridView's SliverGridDelegateWithFixedCrossAxisCount computes for
    // each tile. This (not the image's scaled size) is the authority for
    // where each cell sits in board space.
    final cellW = (boardW - gap * (cols - 1)) / cols;
    final cellH = (boardH - gap * (rows - 1)) / rows;

    return ImageLayout._(
      imgW: imgW,
      imgH: imgH,
      scale: scale,
      scaledW: scaledW,
      scaledH: scaledH,
      offsetX: offsetX,
      offsetY: offsetY,
      cellW: cellW,
      cellH: cellH,
      gap: gap,
      cols: cols,
      rows: rows,
    );
  }

  const ImageLayout._({
    required this.imgW,
    required this.imgH,
    required this.scale,
    required this.scaledW,
    required this.scaledH,
    required this.offsetX,
    required this.offsetY,
    required this.cellW,
    required this.cellH,
    required this.gap,
    required this.cols,
    required this.rows,
  });

  /// Intrinsic image dimensions (pixels).
  final double imgW;
  final double imgH;

  /// Scale factor applied to the image (cover-fit).
  final double scale;

  /// Scaled image dimensions used for rendering.
  final double scaledW;
  final double scaledH;

  /// Top-left offset of the scaled image within the board coordinate space.
  final double offsetX;
  final double offsetY;

  /// The board's authoritative per-cell size (board pixels) — matches the
  /// GridView tile size exactly, including the gap between pieces.
  final double cellW;
  final double cellH;

  final double gap;
  final int cols;
  final int rows;

  /// The source rectangle (in original image pixel space) that cell
  /// ([row], [col]) should crop. Every tile draws this rect stretched to
  /// fill whatever canvas size it is actually given — never its own
  /// independently computed size — so adjacent tiles always reconstruct a
  /// continuous image with no gap and no overlap.
  Rect sourceRectFor(int row, int col) {
    final dstX = col * (cellW + gap);
    final dstY = row * (cellH + gap);
    return Rect.fromLTWH(
      (dstX - offsetX) / scale,
      (dstY - offsetY) / scale,
      cellW / scale,
      cellH / scale,
    );
  }
}

/// Renders one atomic cell of the puzzle grid by cropping the shared,
/// board-level [layout] at ([row], [col]) and drawing it to fill this
/// tile's actual render size.
///
/// Deliberately does not size itself — it fills whatever box its parent
/// gives it (the GridView cell). Combined with [ImageLayout.sourceRectFor]
/// deriving every cell's source rect from the same board geometry the
/// GridView uses, this is what keeps every tile in one shared coordinate
/// system: no per-tile [BoxFit.cover], no independent scale, no drift.
class PuzzleImageTile extends StatelessWidget {
  const PuzzleImageTile({
    super.key,
    required this.image,
    required this.layout,
    required this.row,
    required this.col,
    this.opacity = 1,
  });

  /// The decoded image to render.
  final ui.Image image;

  /// Pre-computed cover-scale layout (shared across all tiles).
  final ImageLayout layout;

  final int row;
  final int col;

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        painter: _ImageTilePainter(
          image: image,
          sourceRect: layout.sourceRectFor(row, col),
        ),
      ),
    );
  }
}

/// Paints the pre-computed source rect for this cell, stretched to fill
/// whatever canvas size Flutter actually laid this tile out at.
class _ImageTilePainter extends CustomPainter {
  _ImageTilePainter({required this.image, required this.sourceRect});

  final ui.Image image;
  final Rect sourceRect;

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(image, sourceRect, dst, paint);
  }

  @override
  bool shouldRepaint(covariant _ImageTilePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.sourceRect != sourceRect;
}
