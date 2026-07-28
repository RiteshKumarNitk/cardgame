import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../levels/domain/entities/level.dart';
import '../../../levels/presentation/widgets/level_difficulty_style.dart';
import '../../domain/puzzle_board_size.dart';

/// The puzzle board: an N×N grid of drop targets sized by the level's
/// difficulty. Slot `i` (0-based) accepts piece `i + 1` from
/// [PuzzlePieceTray]; a correct drop locks the piece in place, a wrong
/// one shakes the slot and sends the piece back to the tray.
class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    super.key,
    required this.difficulty,
    required this.placedPieceIds,
    required this.onDrop,
  });

  final LevelDifficulty difficulty;
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
              filledPieceIndex: placedPieceIds.contains(pieceIndex)
                  ? pieceIndex
                  : null,
              color: difficulty.color,
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
    required this.filledPieceIndex,
    required this.color,
    required this.onDrop,
  });

  final int slotIndex;
  final int? filledPieceIndex;
  final Color color;
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
    final filled = widget.filledPieceIndex != null;

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) =>
          Transform.translate(offset: Offset(_shake.value, 0), child: child),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (_) => !filled,
        onAcceptWithDetails: (details) => _handleAccept(details.data),
        builder: (context, candidateData, rejectedData) {
          final hovering = candidateData.isNotEmpty;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: filled
                  ? widget.color.withValues(alpha: 0.85)
                  : hovering
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.background,
              borderRadius: AppRadius.smRadius,
              border: Border.all(
                color: filled
                    ? widget.color
                    : hovering
                    ? AppColors.primary
                    : AppColors.border,
                width: hovering || filled ? 2 : 1,
              ),
            ),
            child: filled
                ? const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}
