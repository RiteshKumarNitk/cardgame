import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_image.dart';

/// Renders the (row, col) cell of a [gridCols] x [gridRows] crop of the
/// image at [imageUrl] — without needing any image-decoding/cropping
/// package.
///
/// Every tile renders the *same* board-sized canvas — the full image scaled
/// once with `BoxFit.cover` to the grid's dimensions — and clips its own
/// cell-sized window out of that canvas. Because the canvas size and the
/// cover-fit are identical for every tile, adjacent cells are exact
/// neighbors of one scaled image: no white gaps, no stretching, no seams.
/// The fit is computed by Flutter from the image's intrinsic size (not an
/// assumed ratio), so artwork of any aspect ratio — portrait or landscape —
/// covers the board correctly.
///
/// All tiles for the same [imageUrl] share Flutter's image cache, so the
/// network fetch/decode happens once total, not once per tile.
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
        final cellWidth = constraints.maxWidth;
        final cellHeight = constraints.maxHeight;

        // The one shared canvas: the full image cover-fitted to the grid,
        // scaled with the same values in every tile.
        final gridWidth = cellWidth * gridCols;
        final gridHeight = cellHeight * gridRows;

        return ClipRect(
          child: OverflowBox(
            maxWidth: gridWidth,
            maxHeight: gridHeight,
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: Offset(-col * cellWidth, -row * cellHeight),
              child: Opacity(
                opacity: opacity,
                child: AppImage(
                  imagePath: imageUrl,
                  width: gridWidth,
                  height: gridHeight,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
