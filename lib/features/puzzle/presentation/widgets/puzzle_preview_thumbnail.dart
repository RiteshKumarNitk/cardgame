import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/game_card.dart';

/// The reference photo the player is reassembling — the only place it's
/// shown now that pieces live directly on the board instead of a tray, so
/// it's framed like a small "goal card" rather than a minor utility row.
class PuzzlePreviewThumbnail extends StatelessWidget {
  const PuzzlePreviewThumbnail({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GameCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.smRadius,
            child: Image.network(
              imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null
                      ? child
                      : const SizedBox(
                          width: 56,
                          height: 56,
                          child: ColoredBox(color: AppColors.border),
                        ),
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                width: 56,
                height: 56,
                child: ColoredBox(
                  color: AppColors.border,
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_rounded,
                      size: 15,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Reassemble this photo',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Drag pieces on the board to swap them into place',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
