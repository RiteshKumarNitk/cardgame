import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';

/// A small reference thumbnail of the full target picture, shown above
/// the board so the player knows what they're reassembling.
class PuzzlePreviewThumbnail extends StatelessWidget {
  const PuzzlePreviewThumbnail({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.visibility_rounded,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Preview',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const Spacer(),
        ClipRRect(
          borderRadius: AppRadius.smRadius,
          child: Image.network(
            imageUrl,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) =>
                progress == null
                    ? child
                    : const SizedBox(
                        width: 44,
                        height: 44,
                        child: ColoredBox(color: AppColors.border),
                      ),
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              width: 44,
              height: 44,
              child: ColoredBox(
                color: AppColors.border,
                child: Icon(
                  Icons.image_not_supported_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
