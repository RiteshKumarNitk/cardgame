import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../levels/domain/entities/level.dart';
import '../../domain/puzzle_board_size.dart';
import 'puzzle_image_tile.dart';

/// The puzzle board: an N×N grid of drop targets sized by the level's
/// difficulty. Slot `i` (0-based) accepts piece `i + 1` from
/// [PuzzlePieceTray]; a correct drop reveals that cell of [imageUrl] in
/// place, a wrong one shakes the slot and sends the piece back to the
/// tray. Unfilled slots show a faint "ghost" of their target cell as a
/// hint.
class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    super.key,
    required this.difficulty,
    required this.imageUrl,
    required this.placedPieceIds,
    required this.onDrop,
  });

  final LevelDifficulty difficulty;
  final String imageUrl;
  final Set<int> placedPieceIds;

  /// Returns whether the drop was correct.
  final Future<bool> Function(int pieceIndex, int slotIndex) onDrop;

  @override
  Widget build(BuildContext context) {
    final size = boardSizeFor(difficulty);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: size,
            crossAxisSpacing: AppSpacing.xs,
            mainAxisSpacing: AppSpacing.xs,
          ),
          itemCount: size * size,
          itemBuilder: (context, index) {
            final pieceIndex = index + 1;
            return _BoardSlot(
              slotIndex: index,
              row: index ~/ size,
              col: index % size,
              gridSize: size,
              imageUrl: imageUrl,
              filled: placedPieceIds.contains(pieceIndex),
              onDrop: onDrop,
            );
          },
        ),
      ),
    );
  }
}

class _BoardSlot extends StatefulWidget {
  const _BoardSlot({
    required this.slotIndex,
    required this.row,
    required this.col,
    required this.gridSize,
    required this.imageUrl,
    required this.filled,
    required this.onDrop,
  });

  final int slotIndex;
  final int row;
  final int col;
  final int gridSize;
  final String imageUrl;
  final bool filled;
  final Future<bool> Function(int pieceIndex, int slotIndex) onDrop;

  @override
  State<_BoardSlot> createState() => _BoardSlotState();
}

class _BoardSlotState extends State<_BoardSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shake =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept(int pieceIndex) async {
    final correct = await widget.onDrop(pieceIndex, widget.slotIndex);
    if (!correct && mounted) _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final tile = PuzzleImageTile(
      imageUrl: widget.imageUrl,
      gridSize: widget.gridSize,
      row: widget.row,
      col: widget.col,
      opacity: widget.filled ? 1 : 0.18,
    );

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) =>
          Transform.translate(offset: Offset(_shake.value, 0), child: child),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (_) => !widget.filled,
        onAcceptWithDetails: (details) => _handleAccept(details.data),
        builder: (context, candidateData, rejectedData) {
          final hovering = candidateData.isNotEmpty;
          return Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.smRadius,
              border: Border.all(
                color: widget.filled
                    ? AppColors.success
                    : hovering
                    ? AppColors.primary
                    : AppColors.border,
                width: hovering || widget.filled ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.smRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  tile,
                  if (hovering && !widget.filled)
                    ColoredBox(color: AppColors.primary.withValues(alpha: 0.18)),
                  if (widget.filled)
                    const Positioned(
                      top: 2,
                      right: 2,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 16,
                        shadows: [Shadow(blurRadius: 3, color: Colors.black45)],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
