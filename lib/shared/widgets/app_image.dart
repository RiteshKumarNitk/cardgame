import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const ColoredBox(color: AppColors.border);
        },
        errorBuilder: (context, error, stackTrace) => const ColoredBox(
          color: AppColors.border,
          child: Icon(
            Icons.image_not_supported_rounded,
            color: AppColors.textSecondary,
          ),
        ),
      );
    } else {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const ColoredBox(
          color: AppColors.border,
          child: Icon(
            Icons.image_not_supported_rounded,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
  }
}
