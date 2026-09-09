import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import 'outlined_text.dart';

/// The game's circular logo mark. Used on Splash and Home so both share a
/// single visual source of truth until a real branded asset replaces it.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 120, this.wordmark = false});

  final double size;

  /// Shows the "SuitClash" wordmark beneath the mark, outlined to match the
  /// design system — used in Home's compact top bar.
  final bool wordmark;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.surfaceLow],
        ),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Icon(
        Icons.extension_rounded,
        size: size * 0.53,
        color: AppColors.primary,
      ),
    );

    if (!wordmark) return mark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(height: 2),
        OutlinedText(
          'SuitClash',
          outlineWidth: 1.5,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
