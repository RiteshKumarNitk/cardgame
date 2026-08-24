import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Pre-computed cover-scale layout for the puzzle image, resolved once
/// at the board level and shared by every tile. This avoids each tile
/// independently computing the same layout and ensures a single
/// coordinated coordinate space.
class ImageLayout {
  const ImageLayout({
    required this.imgW,
    required this.imgH,
    required this.scale,
    required this.scaledW,
    required this.scaledH,
    required this.offsetX,
    required this.offsetY,
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
}

/// Renders the (row, col) cell of the puzzle grid by painting the image
/// at the exact board-cover position and clipping to the cell bounds.
///
/// The image layout is computed once at the board level ([ImageLayout])
/// and passed to every tile, so all tiles render from a single
/// coordinated coordinate space — no per-tile [BoxFit.cover], no
/// [OverflowBox], no [Transform.translate]. Adjacent cells are exact
/// neighbors of one scaled image: no white gaps, no stretching, no seams.
class PuzzleImageTile extends StatelessWidget {
  const PuzzleImageTile({
    super.key,
    required this.image,
    required this.layout,
    required this.gridCols,
    required this.gridRows,
    required this.row,
    required this.col,
    this.gap = 0,
    this.opacity = 1,
  });

  /// The decoded image to render.
  final ui.Image image;

  /// Pre-computed cover-scale layout (shared across all tiles).
  final ImageLayout layout;

  final int gridCols;
  final int gridRows;
  final int row;
  final int col;

  /// Gap between tiles (from piece style). Used to compute the correct
  /// offset so the image aligns seamlessly across gapped tiles.
  final double gap;

  final double opacity;

  @override
  Widget build(BuildContext context) {
    // Cell size (logical pixels) — the same dimensions used by the board's
    // GridView delegate.
    final cellW = layout.scaledW / gridCols;
    final cellH = layout.scaledH / gridRows;

    // Offset of this cell within the board coordinate space, including gaps.
    final cellOffsetX = col * (cellW + gap);
    final cellOffsetY = row * (cellH + gap);

    // Position of the image's top-left corner relative to this cell.
    final imageX = layout.offsetX - cellOffsetX;
    final imageY = layout.offsetY - cellOffsetY;

    return Opacity(
      opacity: opacity,
      child: ClipRect(
        child: SizedBox(
          width: cellW,
          height: cellH,
          child: CustomPaint(
            painter: _ImageTilePainter(
              image: image,
              imageX: imageX,
              imageY: imageY,
              imageWidth: layout.scaledW,
              imageHeight: layout.scaledH,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the decoded image at the computed position within a single cell.
class _ImageTilePainter extends CustomPainter {
  _ImageTilePainter({
    required this.image,
    required this.imageX,
    required this.imageY,
    required this.imageWidth,
    required this.imageHeight,
  });

  final ui.Image image;
  final double imageX;
  final double imageY;
  final double imageWidth;
  final double imageHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(imageX, imageY, imageWidth, imageHeight);
    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant _ImageTilePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.imageX != imageX ||
      oldDelegate.imageY != imageY;
}
