import 'package:flutter/material.dart';

import '../../../../core/design_system/app_animations.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_shadows.dart';
import '../../domain/puzzle_board_size.dart';
import 'puzzle_image_tile.dart';

/// The puzzle board: a portrait grid (more rows than columns, matching a
/// portrait reference photo) where every cell already holds a piece
/// (shuffled). Pieces sit flush against each other with square corners,
/// so a solved board reads as one seamless photo rather than a grid of
/// separated chips. Drag one piece onto another to swap them — a cell
/// locks with a satisfying pop + glow once its piece is correct.
import 'dart:math' as math;

import '../../../../services/audio_service.dart';

class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    super.key,
    required this.dimensions,
    required this.imageUrl,
    required this.arrangement,
    required this.onSwap,
    this.solvedProgress = 0.0,
    this.snapFraction = 0.18,
    this.borderFadeFraction = 0.5,
  });

  /// Resolved by the caller — from a chapter's board size
  /// ([boardDimensionsForLevel]) for regular levels, or a fixed
  /// per-difficulty table ([boardDimensionsFor]) for Daily Challenge.
  final BoardDimensions dimensions;
  final String imageUrl;

  /// `arrangement[cell]` is the 1-based piece index in that cell.
  final List<int> arrangement;
  final void Function(int fromCell, int toCell) onSwap;

  /// 0.0–1.0 progress of the puzzle-solved celebration animation.
  /// 0 = just solved, 1 = about to navigate to Victory.
  final double solvedProgress;

  /// Fraction of [solvedProgress] used for the piece-snap pop animation.
  final double snapFraction;

  /// Fraction of [solvedProgress] used for fading cell borders away.
  final double borderFadeFraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cells are always square (aspectRatio ties height to width via
        // rows/cols), so this is the exact on-screen size of one cell —
        // used to size the drag feedback so a dragged piece reads as the
        // same physical card moving, not a differently-sized copy.
        final cellSize = constraints.maxWidth / dimensions.cols;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: solvedProgress < borderFadeFraction
                ? Border.all(color: AppColors.border)
                : null,
            boxShadow: AppShadows.card,
          ),
          child: AspectRatio(
            aspectRatio: dimensions.aspectRatio,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: dimensions.cols,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
              ),
              itemCount: dimensions.pieceCount,
              itemBuilder: (context, cellIndex) {
                final pieceIndex = arrangement[cellIndex];
                return _BoardCell(
                  cellIndex: cellIndex,
                  pieceIndex: pieceIndex,
                  gridCols: dimensions.cols,
                  gridRows: dimensions.rows,
                  imageUrl: imageUrl,
                  correct: pieceIndex == cellIndex + 1,
                  onSwap: onSwap,
                  solvedProgress: solvedProgress,
                  snapFraction: snapFraction,
                  borderFadeFraction: borderFadeFraction,
                  cellSize: cellSize,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BoardCell extends StatefulWidget {
  const _BoardCell({
    required this.cellIndex,
    required this.pieceIndex,
    required this.gridCols,
    required this.gridRows,
    required this.imageUrl,
    required this.correct,
    required this.onSwap,
    required this.cellSize,
    this.solvedProgress = 0.0,
    this.snapFraction = 0.18,
    this.borderFadeFraction = 0.5,
  });

  final int cellIndex;
  final int pieceIndex;
  final int gridCols;
  final int gridRows;
  final String imageUrl;
  final bool correct;
  final void Function(int fromCell, int toCell) onSwap;
  final double cellSize;
  final double solvedProgress;
  final double snapFraction;
  final double borderFadeFraction;

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
      AudioService().playPieceSnap();
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = (widget.pieceIndex - 1) ~/ widget.gridCols;
    final col = (widget.pieceIndex - 1) % widget.gridCols;
    final solved = widget.solvedProgress;
    final isAnimatingSolved = solved > 0.0;

    // ── Phase 1: Snap pop (all pieces together) ──
    final snapLocal = (solved / widget.snapFraction).clamp(0.0, 1.0);
    final snapScale = isAnimatingSolved
        ? 1.0 + 0.14 * math.sin(snapLocal * math.pi) * (1.0 - snapLocal * 0.3)
        : 1.0;

    // ── Phase 2: Border fade ──
    final borderFadeLocal =
        ((solved - widget.snapFraction) / widget.borderFadeFraction).clamp(0.0, 1.0);
    final borderColor = isAnimatingSolved
        ? Color.lerp(
            widget.correct ? AppColors.success : AppColors.border,
            Colors.transparent,
            borderFadeLocal,
          )!
        : (widget.correct ? AppColors.success : AppColors.border);
    final borderWidth = isAnimatingSolved
        ? (widget.correct ? 2.0 : 0.5) * (1.0 - borderFadeLocal)
        : (widget.correct ? 2.0 : 0.5);

    // ── Phase 3: Tile glow (subtle lighten as borders disappear) ──
    final tileOpacity = isAnimatingSolved
        ? 1.0 + 0.06 * (solved - widget.snapFraction - widget.borderFadeFraction).clamp(0.0, 0.3) / 0.3
        : 1.0;

    final content = PuzzleImageTile(
      imageUrl: widget.imageUrl,
      gridCols: widget.gridCols,
      gridRows: widget.gridRows,
      row: row,
      col: col,
      opacity: tileOpacity.clamp(0.0, 1.0),
    );

    final decorated = Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: widget.correct && !isAnimatingSolved
            ? AppShadows.glow(AppColors.success, opacity: 0.3)
            : null,
      ),
      child: content,
    );

    // Apply snap scale
    final animated = snapScale != 1.0
        ? Transform.scale(scale: snapScale, child: decorated)
        : decorated;

    final popped = ScaleTransition(scale: _pop, child: animated);

    // When solved animation is playing, disable all interactions
    if (isAnimatingSolved || widget.correct) return popped;

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
            width: widget.cellSize,
            height: widget.cellSize,
            child: Material(color: Colors.transparent, child: decorated),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: decorated),
          child: hoverRing,
        );
      },
    );
  }
}
