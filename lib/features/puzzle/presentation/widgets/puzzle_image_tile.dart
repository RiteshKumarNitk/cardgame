import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';

/// Renders the (row, col) cell of a [gridSize] x [gridSize] crop of the
/// image at [imageUrl] — without needing any image-decoding/cropping
/// package. The trick: render the *whole* image at
/// `tileExtent * gridSize` square (via [LayoutBuilder] for the tile's own
/// on-screen size) inside a fixed [tileExtent] window, shifted so only
/// the target cell is visible. Every tile for the same [imageUrl] shares
/// Flutter's image cache, so this costs one network fetch/decode total,
/// not one per tile.
class PuzzleImageTile extends StatelessWidget {
  const PuzzleImageTile({
    super.key,
    required this.imageUrl,
    required this.gridSize,
    required this.row,
    required this.col,
    this.opacity = 1,
  });

  final String imageUrl;
  final int gridSize;
  final int row;
  final int col;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileExtent = constraints.maxWidth;
        final fullExtent = tileExtent * gridSize;

        return ClipRect(
          child: OverflowBox(
            maxWidth: fullExtent,
            maxHeight: fullExtent,
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: Offset(-col * tileExtent, -row * tileExtent),
              child: Opacity(
                opacity: opacity,
                child: Image.network(
                  imageUrl,
                  width: fullExtent,
                  height: fullExtent,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const ColoredBox(color: AppColors.border);
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(
                        color: AppColors.border,
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
