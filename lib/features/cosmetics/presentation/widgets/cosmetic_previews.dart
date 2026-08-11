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
        border: Border.all(color: frame.borderColor, width: frame.borderWidth.clamp(2, 8)),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: frame.glowColor.withValues(alpha: 0.45),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: List.generate(3, (_) {
          return Expanded(
            child: Row(
              children: List.generate(2, (_) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
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

/// A mini grid of tiles styled exactly like the real piece style: gap,
/// corner radius, borders, and the color that appears when correct.
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline, width: 1.5),
      ),
      child: Column(
        children: List.generate(3, (row) {
          return Expanded(
            child: Row(
              children: List.generate(2, (col) {
                final isCorrect = row == 1 && col == 0;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.all(style.gap / 2),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? AppColors.success.withValues(alpha: 0.35)
                          : AppColors.border.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(style.cornerRadius),
                      border: Border.all(
                        color: isCorrect ? style.correctColor : style.borderColor,
                        width: 1.5,
                      ),
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

/// The avatar preview — the badge itself plus a soft color halo.
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
        color: avatar.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline, width: 1.5),
      ),
      child: AvatarBadge(avatar: avatar, size: 56),
    );
  }
}
