import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_image.dart';

/// Renders the (row, col) cell of a [gridCols] x [gridRows] crop of the
/// image at [imageUrl] — without needing any image-decoding/cropping
/// package. The trick: render the *whole* image at `cols x rows` cells
/// inside a fixed window (each tile is its own on-screen size, which can be
/// rectangular — the grid fills the whole play area), shifted so only the
/// target cell is visible. The image is drawn at [imageAspectRatio] and
/// cover-fitted to the full grid, so cells stay undistorted while the
/// board occupies every pixel. Every tile for the same [imageUrl] shares
/// Flutter's image cache, so this costs one network fetch/decode total,
/// not one per tile.
class PuzzleImageTile extends StatelessWidget {
  const PuzzleImageTile({
    super.key,
    required this.imageUrl,
    required this.gridCols,
    required this.gridRows,
    required this.row,
    required this.col,
    this.opacity = 1,
    this.imageAspectRatio = 3 / 4,
  });

  final String imageUrl;
  final int gridCols;
  final int gridRows;
  final int row;
  final int col;
  final double opacity;

  /// The source artwork's width ÷ height (always portrait 3:4 in this app).
  /// Kept as a parameter so non-3:4 artwork slots in without distortion.
  final double imageAspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth;
        final cellHeight = constraints.maxHeight;
        final gridWidth = cellWidth * gridCols;
        final gridHeight = cellHeight * gridRows;

        // Size the full image to COVER the grid box while keeping the
        // photo's own aspect ratio (no stretching); center it, then clip
        // this tile's window.
        final gridRatio = gridWidth / gridHeight;
        final double drawWidth;
        final double drawHeight;
        if (imageAspectRatio >= gridRatio) {
          drawWidth = gridWidth;
          drawHeight = gridWidth / imageAspectRatio;
        } else {
          drawHeight = gridHeight;
          drawWidth = gridHeight * imageAspectRatio;
        }
        final cropX = (drawWidth - gridWidth) / 2;
        final cropY = (drawHeight - gridHeight) / 2;

        return ClipRect(
          child: OverflowBox(
            maxWidth: drawWidth,
            maxHeight: drawHeight,
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: Offset(
                -cropX - col * cellWidth,
                -cropY - row * cellHeight,
              ),
              child: Opacity(
                opacity: opacity,
                child: AppImage(
                  imagePath: imageUrl,
                  width: drawWidth,
                  height: drawHeight,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
