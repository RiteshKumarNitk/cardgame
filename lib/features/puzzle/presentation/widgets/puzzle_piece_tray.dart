import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../levels/domain/entities/level.dart';
import '../../../levels/presentation/widgets/level_difficulty_style.dart';
import '../../domain/puzzle_board_size.dart';

/// The scrambled tray of draggable puzzle pieces below the board. Drag a
/// piece onto its matching [PuzzleBoard] slot; placed pieces disappear
/// from here.
class PuzzlePieceTray extends StatelessWidget {
  const PuzzlePieceTray({
    super.key,
    required this.level,
    required this.placedPieceIds,
  });

  final Level level;
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
                      index: pieceIndex,
                      color: level.difficulty.color,
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
  const _PieceCard({required this.index, required this.color});

  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        borderRadius: AppRadius.mdRadius,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.extension_rounded, color: Colors.white, size: 22),
          Text(
            '$index',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
