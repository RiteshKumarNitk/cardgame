import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';

import '../../../../shared/widgets/app_image.dart';

/// Renders the (row, col) cell of a [gridCols] x [gridRows] crop of the
/// image at [imageUrl] — without needing any image-decoding/cropping
/// package. The trick: render the *whole* image at
/// `tileExtent * gridCols` by `tileExtent * gridRows` (via [LayoutBuilder]
/// for the tile's own on-screen size, which is square) inside a fixed
/// [tileExtent] window, shifted so only the target cell is visible. Every
/// tile for the same [imageUrl] shares Flutter's image cache, so this
/// costs one network fetch/decode total, not one per tile.
class PuzzleImageTile extends StatelessWidget {
  const PuzzleImageTile({
    super.key,
    required this.imageUrl,
    required this.gridCols,
    required this.gridRows,
    required this.row,
    required this.col,
    this.opacity = 1,
  });

  final String imageUrl;
  final int gridCols;
  final int gridRows;
  final int row;
  final int col;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileExtent = constraints.maxWidth;
        final fullWidth = tileExtent * gridCols;
        final fullHeight = tileExtent * gridRows;

        return ClipRect(
          child: OverflowBox(
            maxWidth: fullWidth,
            maxHeight: fullHeight,
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: Offset(-col * tileExtent, -row * tileExtent),
              child: Opacity(
                opacity: opacity,
                child: AppImage(
                  imagePath: imageUrl,
                  width: fullWidth,
                  height: fullHeight,
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
