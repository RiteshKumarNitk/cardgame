import 'package:flutter/material.dart';

import '../../../../core/design_system/app_animations.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_shadows.dart';
import '../../../levels/domain/entities/level.dart';
import '../../domain/puzzle_board_size.dart';
import 'puzzle_image_tile.dart';

/// The puzzle board: an N×N grid where every cell already holds a piece
/// (shuffled). Pieces sit flush against each other with square corners,
/// so a solved board reads as one seamless photo rather than a grid of
/// separated chips. Drag one piece onto another to swap them — a cell
/// locks with a satisfying pop + glow once its piece is correct.
class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    super.key,
    required this.difficulty,
    required this.imageUrl,
    required this.arrangement,
    required this.onSwap,
  });

  final LevelDifficulty difficulty;
  final String imageUrl;

  /// `arrangement[cell]` is the 1-based piece index in that cell.
  final List<int> arrangement;
  final void Function(int fromCell, int toCell) onSwap;

  @override
  Widget build(BuildContext context) {
    final size = boardSizeFor(difficulty);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: size,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
          ),
          itemCount: size * size,
          itemBuilder: (context, cellIndex) {
            final pieceIndex = arrangement[cellIndex];
            return _BoardCell(
              cellIndex: cellIndex,
              pieceIndex: pieceIndex,
              gridSize: size,
              imageUrl: imageUrl,
              correct: pieceIndex == cellIndex + 1,
              onSwap: onSwap,
            );
          },
        ),
      ),
    );
  }
}

class _BoardCell extends StatefulWidget {
  const _BoardCell({
    required this.cellIndex,
    required this.pieceIndex,
    required this.gridSize,
    required this.imageUrl,
    required this.correct,
    required this.onSwap,
  });

  final int cellIndex;
  final int pieceIndex;
  final int gridSize;
  final String imageUrl;
  final bool correct;
  final void Function(int fromCell, int toCell) onSwap;

  @override
  State<_BoardCell> createState() => _BoardCellState();
}

class _BoardCellState extends State<_BoardCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;
  late final Animation<double> _pop;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: AppAnimations.medium,
    );
    _pop = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.16), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.16, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _popController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _BoardCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.correct && widget.correct) {
      _popController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = (widget.pieceIndex - 1) ~/ widget.gridSize;
    final col = (widget.pieceIndex - 1) % widget.gridSize;

    final content = Stack(
      fit: StackFit.expand,
      children: [
        PuzzleImageTile(
          imageUrl: widget.imageUrl,
          gridSize: widget.gridSize,
          row: row,
          col: col,
        ),
        if (widget.correct)
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
    );

    final decorated = Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.correct ? AppColors.success : AppColors.border,
          width: widget.correct ? 2 : 0.5,
        ),
        boxShadow: widget.correct
            ? AppShadows.glow(AppColors.success, opacity: 0.3)
            : null,
      ),
      child: content,
    );

    final popped = ScaleTransition(scale: _pop, child: decorated);

    if (widget.correct) return popped;

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != widget.cellIndex,
      onAcceptWithDetails: (details) =>
          widget.onSwap(details.data, widget.cellIndex),
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        final hoverRing = hovering
            ? Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: popped,
              )
            : popped;

        return Draggable<int>(
          data: widget.cellIndex,
          feedback: SizedBox(
            width: 72,
            height: 72,
            child: Material(color: Colors.transparent, child: decorated),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: decorated),
          child: hoverRing,
        );
      },
    );
  }
}
