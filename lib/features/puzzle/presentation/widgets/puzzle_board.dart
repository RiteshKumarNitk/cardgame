import 'package:flutter/material.dart';

import '../../../../core/design_system/app_animations.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_shadows.dart';
import '../../../cosmetics/domain/entities/cosmetic_items.dart';
import '../../domain/puzzle_board_size.dart';
import 'puzzle_image_tile.dart';

/// The puzzle board: fills every pixel of its available area with the
/// [dimensions] grid (rows/cols from a portrait reference photo). Pieces
/// sit flush against each other with square corners, so a solved board
/// reads as one seamless photo rather than a grid of separated chips.
/// Drag one piece onto another to swap them — a cell locks with a
/// satisfying pop + glow once its piece is correct.
import 'dart:math' as math;

import '../../../../services/audio_service.dart';

class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    super.key,
    required this.dimensions,
    required this.imageUrl,
    required this.arrangement,
    required this.rotations,
    required this.onSwap,
    required this.onRotate,
    this.solvedProgress = 0.0,
    this.snapFraction = 0.18,
    this.borderFadeFraction = 0.5,
    this.frame,
    this.pieceStyle,
  });

  /// Resolved by the caller — from a chapter's board size
  /// ([boardDimensionsForLevel]) for regular levels, or a fixed
  /// per-difficulty table ([boardDimensionsFor]) for Daily Challenge.
  final BoardDimensions dimensions;
  final String imageUrl;

  /// `arrangement[cell]` is the 1-based piece index in that cell.
  final List<int> arrangement;
  /// `rotations[cell]` is the 0-3 quarter-turns for the piece in that cell.
  final List<int> rotations;
  
  final void Function(int fromCell, int toCell) onSwap;
  final void Function(int cell) onRotate;

  /// 0.0–1.0 progress of the puzzle-solved celebration animation.
  /// 0 = just solved, 1 = about to navigate to Victory.
  final double solvedProgress;

  /// Fraction of [solvedProgress] used for the piece-snap pop animation.
  final double snapFraction;

  /// Fraction of [solvedProgress] used for fading cell borders away.
  final double borderFadeFraction;

  /// The equipped board frame, or `null` for the classic unstyled look.
  final BoardFrame? frame;

  /// The equipped piece style, or `null` for the classic seamless look.
  final PieceStyle? pieceStyle;

  @override
  Widget build(BuildContext context) {
    final gap = pieceStyle?.gap ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The grid fills the entire available area: cells stretch to the
        // full width/height (rectangular, not square), so there is no dead
        // space around the board. These are the exact on-screen cell sizes
        // used to size the drag feedback so a dragged piece reads as the
        // same physical card moving, not a differently-sized copy.
        //
        // When a piece style leaves gaps between tiles, each cell shrinks
        // by its share of the spacing so the board still fills the area
        // exactly.
        final cellWidth =
            (constraints.maxWidth - gap * (dimensions.cols - 1)) /
            dimensions.cols;
        final cellHeight =
            (constraints.maxHeight - gap * (dimensions.rows - 1)) /
            dimensions.rows;

        return Container(
          decoration: BoxDecoration(
            color:
                frame?.backgroundColor ??
                pieceStyle?.tileBackground ??
                AppColors.card,
            border: solvedProgress < borderFadeFraction
                ? Border.all(
                    color: frame?.borderColor ?? AppColors.border,
                    width: frame?.borderWidth ?? 1,
                  )
                : null,
            boxShadow: [
              ...AppShadows.card,
              if (frame != null)
                BoxShadow(
                  color: frame!.glowColor.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
            ],
          ),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: dimensions.cols,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              childAspectRatio: cellWidth / cellHeight,
            ),
            itemCount: dimensions.pieceCount,
            itemBuilder: (context, cellIndex) {
              final pieceIndex = arrangement[cellIndex];
              final rotation = rotations[cellIndex];

              return _BoardCell(
                cellIndex: cellIndex,
                pieceIndex: pieceIndex,
                rotation: rotation,
                gridCols: dimensions.cols,
                gridRows: dimensions.rows,
                imageUrl: imageUrl,
                correct: pieceIndex == cellIndex + 1 && rotation == 0,
                onSwap: onSwap,
                onRotate: onRotate,
                solvedProgress: solvedProgress,
                snapFraction: snapFraction,
                borderFadeFraction: borderFadeFraction,
                cellWidth: cellWidth,
                cellHeight: cellHeight,
                pieceStyle: pieceStyle,
              );
            },
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
    required this.rotation,
    required this.gridCols,
    required this.gridRows,
    required this.imageUrl,
    required this.correct,
    required this.onSwap,
    required this.onRotate,
    required this.cellWidth,
    required this.cellHeight,
    this.solvedProgress = 0.0,
    this.snapFraction = 0.18,
    this.borderFadeFraction = 0.5,
    this.pieceStyle,
  });

  final int cellIndex;
  final int pieceIndex;
  final int rotation;
  final int gridCols;
  final int gridRows;
  final String imageUrl;
  final bool correct;
  final void Function(int fromCell, int toCell) onSwap;
  final void Function(int cell) onRotate;
  final double cellWidth;
  final double cellHeight;
  final double solvedProgress;
  final double snapFraction;
  final double borderFadeFraction;
  final PieceStyle? pieceStyle;

  @override
  State<_BoardCell> createState() => _BoardCellState();
}

class _BoardCellState extends State<_BoardCell>
    with TickerProviderStateMixin {
  late final AnimationController _popController;
  late final Animation<double> _pop;

  late final AnimationController _flipController;
  late final Animation<double> _flipScale;

  late final AnimationController _shakeController;
  late final Animation<double> _shake;

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

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flipScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.08), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.06), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.06, end: -0.06), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.linear));
  }

  @override
  void didUpdateWidget(covariant _BoardCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.correct && widget.correct) {
      _popController.forward(from: 0);
      AudioService().playPieceSnap();
    }
    if (oldWidget.rotation != widget.rotation) {
      _flipController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    _flipController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerErrorShake() {
    if (_shakeController.isAnimating) return;
    AudioService().playError();
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final row = (widget.pieceIndex - 1) ~/ widget.gridCols;
    final col = (widget.pieceIndex - 1) % widget.gridCols;
    final solved = widget.solvedProgress;
    final isAnimatingSolved = solved > 0.0;
    final style = widget.pieceStyle;

    // Colors driven by the equipped piece style, falling back to the
    // classic green/gray scheme when none is equipped.
    final correctColor = style?.correctColor ?? AppColors.success;
    final idleBorderColor = style?.borderColor ?? AppColors.border;

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
            widget.correct ? correctColor : idleBorderColor,
            Colors.transparent,
            borderFadeLocal,
          )!
        : (widget.correct ? correctColor : idleBorderColor);
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

    // Rounded corners (from the piece style) are applied under the
    // rotation so a rotated piece keeps its rounded shape.
    final radius = BorderRadius.circular(style?.cornerRadius ?? 0);
    final clippedContent = ClipRRect(borderRadius: radius, child: content);

    // Apply rotation and flip scale
    final rotatedContent = AnimatedBuilder(
      animation: _flipScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _flipScale.value,
          child: AnimatedRotation(
            turns: widget.rotation / 4.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: child,
          ),
        );
      },
      child: clippedContent,
    );

    final decorated = AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        return Transform.rotate(
          angle: _shake.value,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _shakeController.isAnimating ? AppColors.danger : borderColor,
                width: _shakeController.isAnimating ? 3.0 : borderWidth,
              ),
              boxShadow: widget.correct && !isAnimatingSolved
                  ? AppShadows.glow(correctColor, opacity: 0.3)
                  : (_shakeController.isAnimating ? AppShadows.glow(AppColors.danger, opacity: 0.5) : null),
            ),
            child: child,
          ),
        );
      },
      child: rotatedContent,
    );

    // Apply snap scale
    final animated = snapScale != 1.0
        ? Transform.scale(scale: snapScale, child: decorated)
        : decorated;

    final popped = ScaleTransition(scale: _pop, child: animated);

    // When solved animation is playing, disable all interactions
    if (isAnimatingSolved) return _withSemantics(popped);

    // If correct, it's locked. Tapping or dragging causes error shake.
    if (widget.correct) {
      return _withSemantics(
        GestureDetector(
          onTap: _triggerErrorShake,
          onPanDown: (_) => _triggerErrorShake,
          child: popped,
        ),
      );
    }

    return _withSemantics(
      DragTarget<int>(
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

          return GestureDetector(
            onTap: () => widget.onRotate(widget.cellIndex),
            child: Draggable<int>(
              data: widget.cellIndex,
              feedback: SizedBox(
                width: widget.cellWidth,
                height: widget.cellHeight,
                child: Material(
                  color: Colors.transparent,
                  child: decorated,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.35,
                child: decorated,
              ),
              child: hoverRing,
            ),
          );
        },
      ),
    );
  }

  /// Announces the piece for screen readers. Pieces are interactive the
  /// moment the board loads: drag to swap, tap to rotate — both is told.
  Widget _withSemantics(Widget child) {
    final totalPieces = widget.gridCols * widget.gridRows;
    final isCorrect = widget.correct || widget.solvedProgress > 0;
    return Semantics(
      label: 'Piece ${widget.pieceIndex} of $totalPieces',
      hint: isCorrect
          ? 'Correctly placed'
          : 'Drag this piece onto another piece to swap them, or tap to rotate it',
      container: true,
      child: child,
    );
  }
}
