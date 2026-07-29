import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../levels/domain/entities/level.dart';
import '../../domain/puzzle_board_size.dart';
import 'puzzle_image_tile.dart';

/// The scrambled tray of draggable puzzle pieces below the board. Each
/// piece shows the actual crop of [imageUrl] it belongs at — drag it onto
/// the matching [PuzzleBoard] slot to reveal that part of the picture.
/// Placed pieces disappear from here.
class PuzzlePieceTray extends StatelessWidget {
  const PuzzlePieceTray({
    super.key,
    required this.level,
    required this.imageUrl,
    required this.placedPieceIds,
  });

  final Level level;
  final String imageUrl;
  final Set<int> placedPieceIds;

  @override
  Widget build(BuildContext context) {
    final size = boardSizeFor(level.difficulty);
    final order = List.generate(size * size, (i) => i + 1)
      ..shuffle(Random(level.id));
    final remaining = order.where((i) => !placedPieceIds.contains(i)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pieces',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: AppColors.textDark),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 72,
          child: remaining.isEmpty
              ? Center(
                  child: Text(
                    'All pieces placed!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: remaining.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final pieceIndex = remaining[index];
                    final card = _PieceCard(
                      imageUrl: imageUrl,
                      gridSize: size,
                      row: (pieceIndex - 1) ~/ size,
                      col: (pieceIndex - 1) % size,
                    );
                    return Draggable<int>(
                      data: pieceIndex,
                      feedback: Transform.scale(scale: 1.1, child: card),
                      childWhenDragging: Opacity(opacity: 0.3, child: card),
                      child: card,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PieceCard extends StatelessWidget {
  const _PieceCard({
    required this.imageUrl,
    required this.gridSize,
    required this.row,
    required this.col,
  });

  final String imageUrl;
  final int gridSize;
  final int row;
  final int col;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.mdRadius,
        child: PuzzleImageTile(
          imageUrl: imageUrl,
          gridSize: gridSize,
          row: row,
          col: col,
        ),
      ),
    );
  }
}
