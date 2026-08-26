import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_animations.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_shadows.dart';
import '../../../../services/audio_service.dart';
import '../../../cosmetics/domain/entities/cosmetic_items.dart';
import '../../domain/puzzle_adjacency.dart';
import '../../domain/puzzle_board_size.dart';
import '../../domain/puzzle_group.dart';
import 'puzzle_image_tile.dart';

/// The puzzle board: fills every pixel of its available area with the
/// [dimensions] grid (rows/cols from a portrait reference photo). Pieces
/// sit flush against each other with square corners, so a solved board
/// reads as one seamless photo rather than a grid of separated chips.
/// Drag one piece onto another to swap them — connected edges remove
/// shared borders, visually joining correct neighbors.
class PuzzleBoard extends StatefulWidget {
  const PuzzleBoard({
    super.key,
    required this.dimensions,
    required this.imageUrl,
    required this.arrangement,
    required this.onSwap,
    this.solvedProgress = 0.0,
    this.snapFraction = 0.18,
    this.borderFadeFraction = 0.5,
    this.frame,
    this.pieceStyle,
    this.adjacency,
    this.grouping,
  });

  /// Resolved by the caller — from a chapter's board size
  /// ([boardDimensionsForLevel]) for regular levels, or a fixed
  /// per-difficulty table ([boardDimensionsFor]) for Daily Challenge.
  final BoardDimensions dimensions;
  final String imageUrl;

  /// `arrangement[cell]` is the 1-based piece index in that cell.
  final List<int> arrangement;

  /// Attempts to move the piece(s) at [fromCell] onto [toCell]. Returns
  /// whether the move was actually accepted — `false` triggers a neutral
  /// snap-back/shake instead of any color-coded feedback.
  final Future<bool> Function(int fromCell, int toCell) onSwap;

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

  /// Edge-level adjacency state. For every cell, determines which of
  /// its four edges are connected to a currently-adjacent solved-image
  /// neighbor — a relative relationship, independent of either piece's
  /// own absolute board position.
  final PuzzleAdjacency? adjacency;

  /// Dynamically-computed groups formed from adjacency connections.
  /// `null` or empty for Easy/Medium (individual tiles only).
  final PuzzleGrouping? grouping;

  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

class _PuzzleBoardState extends State<PuzzleBoard> {
  ui.Image? _image;
  ImageLayout? _layout;

  /// The id of the group currently being dragged (from any of its member
  /// cells), or `null` when nothing is being dragged. Every cell belonging
  /// to this group fades on the board while it's set, so the whole group
  /// reads as "picked up" — not just the one cell whose Draggable happens
  /// to be active. Each cell has its own independent Draggable (Flutter
  /// has no built-in notion of a multi-cell drag), so without this, only
  /// the cell that started the drag would fade and its groupmates would
  /// stay fully visible on the board — looking like a duplicate of the
  /// group floating alongside the real one.
  int? _draggingGroupId;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant PuzzleBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolveImage();
    }
  }

  Future<void> _resolveImage() async {
    final provider = widget.imageUrl.startsWith('http')
        ? NetworkImage(widget.imageUrl)
        : AssetImage(widget.imageUrl) as ImageProvider;

    final stream = provider.resolve(const ImageConfiguration());
    final completer = Completer<ui.Image>();
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);

    try {
      final image = await completer.future;
      if (!mounted) return;
      setState(() {
        _image = image;
      });
    } catch (_) {
      // Image failed to resolve — tiles will show placeholder via AppImage.
    }
  }

  @override
  Widget build(BuildContext context) {
    final gap = widget.pieceStyle?.gap ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth =
            (constraints.maxWidth - gap * (widget.dimensions.cols - 1)) /
            widget.dimensions.cols;
        final cellHeight =
            (constraints.maxHeight - gap * (widget.dimensions.rows - 1)) /
            widget.dimensions.rows;

        // Compute the shared cover-scale layout once when the image is
        // available. Every tile crops from this SAME layout — it derives
        // each cell's source rect from the board's own cell geometry
        // (cols/rows/gap), not from the image's independently scaled
        // size, so tiles can never drift out of alignment with the grid.
        ImageLayout? layout;
        if (_image != null) {
          layout = ImageLayout(
            imgW: _image!.width.toDouble(),
            imgH: _image!.height.toDouble(),
            boardW: constraints.maxWidth,
            boardH: constraints.maxHeight,
            cols: widget.dimensions.cols,
            rows: widget.dimensions.rows,
            gap: gap,
          );
          _layout = layout;
        }

        // Use the last successfully computed layout for the grid cells,
        // so tiles stay aligned while a new image loads.
        final effectiveLayout = layout ?? _layout;

        return Container(
          decoration: BoxDecoration(
            color:
                widget.frame?.backgroundColor ??
                widget.pieceStyle?.tileBackground ??
                AppColors.card,
            border: widget.solvedProgress < widget.borderFadeFraction
                ? Border.all(
                    color: widget.frame?.borderColor ?? AppColors.border,
                    width: widget.frame?.borderWidth ?? 1,
                  )
                : null,
            boxShadow: [
              ...AppShadows.card,
              if (widget.frame != null)
                BoxShadow(
                  color: widget.frame!.glowColor.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
            ],
          ),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.dimensions.cols,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              childAspectRatio: cellWidth / cellHeight,
            ),
            itemCount: widget.dimensions.pieceCount,
            itemBuilder: (context, cellIndex) {
              final pieceIndex = widget.arrangement[cellIndex];

              return _BoardCell(
                cellIndex: cellIndex,
                pieceIndex: pieceIndex,
                gridCols: widget.dimensions.cols,
                gridRows: widget.dimensions.rows,
                image: _image,
                layout: effectiveLayout,
                imageUrl: widget.imageUrl,
                correct: pieceIndex == cellIndex + 1,
                onSwap: widget.onSwap,
                solvedProgress: widget.solvedProgress,
                snapFraction: widget.snapFraction,
                borderFadeFraction: widget.borderFadeFraction,
                cellWidth: cellWidth,
                cellHeight: cellHeight,
                gap: gap,
                pieceStyle: widget.pieceStyle,
                adjacency: widget.adjacency,
                grouping: widget.grouping,
                arrangement: widget.arrangement,
                draggingGroupId: _draggingGroupId,
                onGroupDragStart: (id) => setState(() => _draggingGroupId = id),
                onGroupDragEnd: () => setState(() => _draggingGroupId = null),
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
    required this.gridCols,
    required this.gridRows,
    required this.image,
    required this.layout,
    required this.imageUrl,
    required this.correct,
    required this.onSwap,
    required this.cellWidth,
    required this.cellHeight,
    required this.gap,
    this.solvedProgress = 0.0,
    this.snapFraction = 0.18,
    this.borderFadeFraction = 0.5,
    this.pieceStyle,
    this.adjacency,
    this.grouping,
    this.arrangement,
    this.draggingGroupId,
    this.onGroupDragStart,
    this.onGroupDragEnd,
  });

  final int cellIndex;
  final int pieceIndex;
  final int gridCols;
  final int gridRows;
  final ui.Image? image;
  final ImageLayout? layout;
  final String imageUrl;
  final bool correct;
  /// Attempts to move the piece(s) at [fromCell] onto [toCell]. Returns
  /// whether the move was actually accepted — `false` triggers a neutral
  /// snap-back/shake instead of any color-coded feedback.
  final Future<bool> Function(int fromCell, int toCell) onSwap;
  final double cellWidth;
  final double cellHeight;
  final double gap;
  final double solvedProgress;
  final double snapFraction;
  final double borderFadeFraction;
  final PieceStyle? pieceStyle;
  final PuzzleAdjacency? adjacency;
  final PuzzleGrouping? grouping;
  final List<int>? arrangement;

  /// The id of the group currently being dragged board-wide (from any
  /// member cell), or `null`. Lets every cell in that group fade together
  /// regardless of which specific cell's Draggable is the active one.
  final int? draggingGroupId;
  final ValueChanged<int>? onGroupDragStart;
  final VoidCallback? onGroupDragEnd;

  @override
  State<_BoardCell> createState() => _BoardCellState();
}

class _BoardCellState extends State<_BoardCell>
    with TickerProviderStateMixin {
  late final AnimationController _popController;
  late final Animation<double> _pop;

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
    // Pop animation plays the moment this cell gains its first edge
    // connection — the "click" of two pieces fitting together — not when
    // it merely reaches its own correct absolute position. Connections
    // are relative (see computeAdjacency): a piece can connect to its
    // solved neighbor long before either piece is at its final cell, and
    // that's the moment worth celebrating.
    final wasConnected =
        oldWidget.adjacency?.hasAnyConnection(oldWidget.cellIndex) ?? false;
    final isConnected =
        widget.adjacency?.hasAnyConnection(widget.cellIndex) ?? false;
    if (!wasConnected && isConnected) {
      _popController.forward(from: 0);
      AudioService().playPieceSnap();
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = (widget.pieceIndex - 1) ~/ widget.gridCols;
    final col = (widget.pieceIndex - 1) % widget.gridCols;
    final solved = widget.solvedProgress;
    final isAnimatingSolved = solved > 0.0;
    final style = widget.pieceStyle;

    // Border color: always the idle border. Correctness is communicated
    // through image continuity and snap animation, never through color.
    final idleBorderColor = style?.borderColor ?? AppColors.border;

    // Check connectivity for each edge.
    final adj = widget.adjacency;
    final connectedTop = adj != null && adj.isConnected(widget.cellIndex, Edge.top);
    final connectedRight = adj != null && adj.isConnected(widget.cellIndex, Edge.right);
    final connectedBottom = adj != null && adj.isConnected(widget.cellIndex, Edge.bottom);
    final connectedLeft = adj != null && adj.isConnected(widget.cellIndex, Edge.left);

    // Check if this cell belongs to a connected group.
    final group = widget.grouping?.findGroup(widget.cellIndex);
    final isInGroup = group != null && !group.isSingle;

    // ── Phase 1: Snap pop (all pieces together) ──
    final snapLocal = (solved / widget.snapFraction).clamp(0.0, 1.0);
    final snapScale = isAnimatingSolved
        ? 1.0 + 0.14 * math.sin(snapLocal * math.pi) * (1.0 - snapLocal * 0.3)
        : 1.0;

    // ── Phase 2: Border fade ──
    final borderFadeLocal =
        ((solved - widget.snapFraction) / widget.borderFadeFraction).clamp(0.0, 1.0);

    // Base border color: always idle. Correctness is communicated through
    // image continuity, not border color. Connected edges have transparent
    // borders via _edgeBorder.
    final baseBorderColor = idleBorderColor;

    final borderColor = isAnimatingSolved
        ? Color.lerp(baseBorderColor, Colors.transparent, borderFadeLocal)!
        : baseBorderColor;

    // Border width: uniform for all cells. Connected edges will have
    // transparent borders via _edgeBorder.
    final borderWidth = isAnimatingSolved
        ? 0.5 * (1.0 - borderFadeLocal)
        : 0.5;

    // ── Phase 3: Tile glow (subtle lighten as borders disappear) ──
    final tileOpacity = isAnimatingSolved
        ? 1.0 + 0.06 * (solved - widget.snapFraction - widget.borderFadeFraction).clamp(0.0, 0.3) / 0.3
        : 1.0;

    final content = widget.image != null && widget.layout != null
        ? PuzzleImageTile(
            image: widget.image!,
            layout: widget.layout!,
            row: row,
            col: col,
            opacity: tileOpacity.clamp(0.0, 1.0),
          )
        : _PlaceholderTile(
            imageUrl: widget.imageUrl,
            gridCols: widget.gridCols,
            gridRows: widget.gridRows,
            row: row,
            col: col,
            opacity: tileOpacity.clamp(0.0, 1.0),
          );

    // Rounded corners (from the piece style).
    final radius = BorderRadius.circular(style?.cornerRadius ?? 0);
    final clippedContent = ClipRRect(borderRadius: radius, child: content);

    // Build per-edge border: connected edges get transparent border,
    // unconnected edges get the normal border.
    final effectiveBorder = isAnimatingSolved
        ? Border.all(color: borderColor, width: borderWidth)
        : _edgeBorder(
            top: connectedTop,
            right: connectedRight,
            bottom: connectedBottom,
            left: connectedLeft,
            color: borderColor,
            width: borderWidth,
          );

    // Invalid-move feedback is purely physical: a quick rotational shake
    // plus a neutral dark impact shadow — never a color-coded (red/green)
    // signal. Correctness is communicated by image continuity and edge
    // connections alone.
    final decorated = AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        return Transform.rotate(
          angle: _shake.value,
            child: Container(
            decoration: BoxDecoration(
              border: effectiveBorder,
              boxShadow: _shakeController.isAnimating
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
      child: clippedContent,
    );

    // Apply snap scale
    final animated = snapScale != 1.0
        ? Transform.scale(scale: snapScale, child: decorated)
        : decorated;

    final popped = ScaleTransition(scale: _pop, child: animated);

    // Wrap the whole piece in the deal-in entrance so it cascades onto
    // the board on every (re)shuffle. The feedback copy is built from
    // [decorated] directly, so the lifted piece is never double-animated.
    final Widget tree;
    if (isAnimatingSolved) {
      // When solved animation is playing, disable all interactions.
      tree = popped;
    } else if (isInGroup && widget.image != null && widget.layout != null) {
      // ── Group cell: drag the entire group as one unit ──
      //
      // Every cell in the group has its OWN independent Draggable (Flutter
      // has no multi-cell drag primitive), so whichever cell the player
      // actually grabs is the one whose Draggable is "active." Without
      // coordination, only THAT cell would fade via childWhenDragging —
      // every other member would keep rendering normally on the board,
      // looking like a duplicate/leftover tile beside the group that's
      // following the pointer. `draggingGroupId` (lifted to the board)
      // fixes this: every cell in the currently-dragged group fades,
      // regardless of which one started the drag.
      final isThisGroupDragging = widget.draggingGroupId == group.id;
      final fadedForGroupDrag = Opacity(opacity: 0.35, child: decorated);
      tree = DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != widget.cellIndex,
        onAcceptWithDetails: (details) => _handleDrop(details.data),
        builder: (context, candidateData, rejectedData) {
          final hovering = candidateData.isNotEmpty;
          // Sibling cells (this group is dragging, but THIS cell isn't
          // the one whose own Draggable is active) fade via this path.
          // The actively-dragged cell fades via childWhenDragging below,
          // unconditionally and with zero propagation delay.
          final hoverRing = isThisGroupDragging
              ? fadedForGroupDrag
              : (hovering ? _neutralHoverLift(popped, style) : popped);

          return Draggable<int>(
            data: widget.cellIndex,
            feedback: _buildGroupFeedback(group, decorated),
            // The default anchor strategy maps "where within the grabbed
            // cell you touched" onto the SAME fraction of the feedback
            // widget. That's correct for a single tile (child and
            // feedback are the same size) but wrong for a group: the
            // feedback is the whole group's bounding box, so the default
            // would anchor the pointer near the group's top-left corner
            // (roughly wherever cell A sits) instead of under the actual
            // cell the player grabbed — a visible jump the instant the
            // drag starts. This strategy adds this cell's own offset
            // within the group's bounding box, so the grabbed cell stays
            // exactly under the finger.
            dragAnchorStrategy: (draggable, context, position) {
              final box = context.findRenderObject()! as RenderBox;
              final localGrab = box.globalToLocal(position);
              final memberIndex = group.cells.indexOf(widget.cellIndex);
              final rel = group.relativePositions[memberIndex];
              final groupOffset = Offset(
                rel.$2 * (widget.cellWidth + widget.gap),
                rel.$1 * (widget.cellHeight + widget.gap),
              );
              return localGrab + groupOffset;
            },
            onDragStarted: () => widget.onGroupDragStart?.call(group.id),
            onDragEnd: (_) => widget.onGroupDragEnd?.call(),
            childWhenDragging: fadedForGroupDrag,
            child: hoverRing,
          );
        },
      );
    } else {
      // ── Individual cell: standard drag-to-swap ──
      tree = DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != widget.cellIndex,
        onAcceptWithDetails: (details) => _handleDrop(details.data),
        builder: (context, candidateData, rejectedData) {
          final hovering = candidateData.isNotEmpty;
          // Drop-target feedback is purely physical — a subtle lift and
          // neutral shadow, never a color that could read as a
          // correct/incorrect signal.
          final hoverRing = hovering ? _neutralHoverLift(popped, style) : popped;

          return Draggable<int>(
            data: widget.cellIndex,
            // The lifted piece: the exact same physical size and
            // appearance it has on the board — no scale-up, no shadow.
            // Only the pointer-following motion signals "picked up."
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
          );
        },
      );
    }

    return _withSemantics(
      _DealIn(
        delay: Duration(milliseconds: widget.cellIndex * 30),
        child: tree,
      ),
    );
  }

  /// Builds a per-edge [Border] that hides edges where the cell is
  /// connected to a currently-adjacent solved-image neighbor.
  static Border _edgeBorder({
    required bool top,
    required bool right,
    required bool bottom,
    required bool left,
    required Color color,
    required double width,
  }) {
    return Border(
      top: top
          ? BorderSide.none
          : BorderSide(color: color, width: width),
      right: right
          ? BorderSide.none
          : BorderSide(color: color, width: width),
      bottom: bottom
          ? BorderSide.none
          : BorderSide(color: color, width: width),
      left: left
          ? BorderSide.none
          : BorderSide(color: color, width: width),
    );
  }

  /// Attempts the move; if it was rejected (e.g. a group whose shifted
  /// shape doesn't fit the vacated cells — never because of a locked
  /// cell, since no cell is ever locked by its position), plays a
  /// neutral physical "no" — a quick shake plus a soft error haptic/SFX
  /// — instead of any color-coded target feedback. The piece simply
  /// stays where it was; there is nothing to snap back since the
  /// arrangement never changed.
  Future<void> _handleDrop(int fromCell) async {
    final accepted = await widget.onSwap(fromCell, widget.cellIndex);
    if (!accepted && mounted) {
      _shakeController.forward(from: 0);
      AudioService().playError();
    }
  }

  /// Neutral "this is a valid drop target" affordance: a slight lift and
  /// a soft dark shadow. Deliberately colorless — correctness is never
  /// communicated through target color.
  Widget _neutralHoverLift(Widget child, PieceStyle? style) {
    return Transform.scale(
      scale: 1.03,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(style?.cornerRadius ?? 0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  /// Announces the piece for screen readers. Pieces are interactive the
  /// moment the board loads: drag to swap.
  Widget _withSemantics(Widget child) {
    final totalPieces = widget.gridCols * widget.gridRows;
    final isCorrect = widget.correct;
    final isInGroup = widget.grouping?.findGroup(widget.cellIndex) != null &&
        (widget.grouping?.findGroup(widget.cellIndex)?.size ?? 0) > 1;
    return Semantics(
      label: 'Piece ${widget.pieceIndex} of $totalPieces',
      hint: isCorrect
          ? (isInGroup ? 'Connected and correctly placed' : 'Correctly placed')
          : (isInGroup
              ? 'Connected group — drag to move entire group'
              : 'Drag this piece onto another piece to swap them'),
      container: true,
      child: child,
    );
  }

  /// Builds the feedback widget for a connected group drag.
  ///
  /// Shows every cell of [group] at its real relative position within the
  /// group's bounding box, each with its own image content, at the exact
  /// same size it has on the board — no scale, no shadow. This is built
  /// directly from [group.cells]/[group.relativePositions] (the same
  /// shape data the movement engine itself uses), not a re-derived
  /// interpretation of the group's geometry.
  Widget _buildGroupFeedback(PuzzleGroup group, Widget cellContent) {
    final style = widget.pieceStyle;
    final radius = BorderRadius.circular(style?.cornerRadius ?? 0);

    // Compute the bounding box of the group from relative positions.
    final minRow = group.relativePositions
        .map((o) => o.$1)
        .reduce(math.min);
    final maxRow = group.relativePositions
        .map((o) => o.$1)
        .reduce(math.max);
    final minCol = group.relativePositions
        .map((o) => o.$2)
        .reduce(math.min);
    final maxCol = group.relativePositions
        .map((o) => o.$2)
        .reduce(math.max);

    final groupCols = maxCol - minCol + 1;
    final groupRows = maxRow - minRow + 1;
    final groupWidth =
        groupCols * widget.cellWidth + (groupCols - 1) * widget.gap;
    final groupHeight =
        groupRows * widget.cellHeight + (groupRows - 1) * widget.gap;

    // Build each cell of the group with its image content.
    final groupCells = <Widget>[];
    for (var i = 0; i < group.cells.length; i++) {
      final cellIndex = group.cells[i];
      final offset = group.relativePositions[i];
      final cellRow = offset.$1 - minRow;
      final cellCol = offset.$2 - minCol;

      // Get the piece index for this cell from the arrangement.
      final pieceIndex = widget.arrangement != null
          ? widget.arrangement![cellIndex]
          : cellIndex + 1;

      // Compute the row/col for image rendering (piece index is 1-based).
      final displayRow = (pieceIndex - 1) ~/ widget.gridCols;
      final displayCol = (pieceIndex - 1) % widget.gridCols;

      final cellTile = widget.image != null && widget.layout != null
          ? PuzzleImageTile(
              image: widget.image!,
              layout: widget.layout!,
              row: displayRow,
              col: displayCol,
            )
          : _PlaceholderTile(
              imageUrl: widget.imageUrl,
              gridCols: widget.gridCols,
              gridRows: widget.gridRows,
              row: displayRow,
              col: displayCol,
            );

      groupCells.add(
        Positioned(
          left: cellCol * (widget.cellWidth + widget.gap),
          top: cellRow * (widget.cellHeight + widget.gap),
          child: SizedBox(
            width: widget.cellWidth,
            height: widget.cellHeight,
            child: ClipRRect(
              borderRadius: radius,
              child: cellTile,
            ),
          ),
        ),
      );
    }

    // Exactly the group's on-board footprint — no scale, no shadow. Empty
    // cells inside the bounding box (an irregular group shape) stay
    // transparent since only the group's actual cells add a Positioned
    // child to the Stack.
    return SizedBox(
      width: groupWidth,
      height: groupHeight,
      child: Material(
        color: Colors.transparent,
        child: Stack(children: groupCells),
      ),
    );
  }
}

/// Fallback tile shown while the image is still loading.
class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile({
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
    // Show a simple placeholder while the image resolves.
    return Opacity(
      opacity: opacity,
      child: ColoredBox(color: AppColors.border),
    );
  }
}

/// Plays once per shuffle: the cell scales + fades in with a stagger based
/// on [delay] (derived from the cell's board position), so pieces appear to
/// cascade onto the board instead of snapping in. The delay is an
/// [Interval] on the controller — no timers — so widget tests never see a
/// leaked pending timer. Replays when the parent remounts the board (the
/// page keys the board by the shuffle generation).
class _DealIn extends StatefulWidget {
  const _DealIn({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_DealIn> createState() => _DealInState();
}

class _DealInState extends State<_DealIn>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 420);

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    final total = _duration + widget.delay;
    _controller =
        AnimationController(vsync: this, duration: total)..forward();
    final start = widget.delay.inMilliseconds / total.inMilliseconds;
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
