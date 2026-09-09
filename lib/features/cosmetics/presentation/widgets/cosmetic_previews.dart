import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../domain/entities/cosmetic_items.dart';
import 'avatar_badge.dart';

/// Miniature visual previews of each cosmetic category, used in the shop
/// grid so players can see exactly what they're buying without entering
/// a level.

/// A small portrait board: the frame's border + glow around a muted
/// placeholder puzzle so the framing is what stands out.
class FramePreview extends StatelessWidget {
  const FramePreview({super.key, required this.frame});

  final BoardFrame frame;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 96,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: frame.backgroundColor,
        border: Border.all(
          color: frame.borderColor,
          width: frame.borderWidth.clamp(1, 4),
        ),
      ),
      // Seamless mini "photo" — pieces sit flush, like a solved puzzle.
      child: Column(
        children: List.generate(3, (r) {
          return Expanded(
            child: Row(
              children: List.generate(2, (c) {
                return Expanded(
                  child: ColoredBox(
                    color: AppColors.border.withValues(
                      alpha: (r + c).isEven ? 0.5 : 0.35,
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

/// A mini seamless "photo" showing how the pieces sit — flush, no gaps,
/// no rounded corners (the Classic look).
class PieceStylePreview extends StatelessWidget {
  const PieceStylePreview({super.key, required this.style});

  final PieceStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 96,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: style.tileBackground,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: List.generate(3, (row) {
          return Expanded(
            child: Row(
              children: List.generate(2, (col) {
                final isCorrect = row == 1 && col == 0;
                return Expanded(
                  child: ColoredBox(
                    color: isCorrect
                        ? AppColors.primaryContainer.withValues(alpha: 0.3)
                        : AppColors.border.withValues(
                            alpha: (row + col).isEven ? 0.5 : 0.35,
                          ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

/// The avatar preview — just the badge on a clean neutral card.
class AvatarPreview extends StatelessWidget {
  const AvatarPreview({super.key, required this.avatar});

  final Avatar avatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: AvatarBadge(avatar: avatar, size: 56),
    );
  }
}
