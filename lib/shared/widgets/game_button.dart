import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_shadows.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_theme_extension.dart';
import 'outlined_text.dart';
import 'press_scale.dart';

enum GameButtonVariant { primary, secondary, premium }

/// The one and only button surface in the app: gradient fill, pill
/// corners, a thick dark outline, and a chunky "3D bevel" band beneath —
/// a bold toy-block look with press-scale feedback (via [PressScale]).
/// Every CTA — Play, menu tiles, dialogs — should use this instead of a
/// bespoke `Container`/`ElevatedButton`.
class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.variant = GameButtonVariant.primary,
    this.width,
    this.height = 56,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final GameButtonVariant variant;
  final double? width;
  final double height;

  Gradient _gradient(AppThemeExtension ext) => switch (variant) {
    GameButtonVariant.primary => ext.primaryButtonGradient,
    GameButtonVariant.secondary => ext.secondaryButtonGradient,
    GameButtonVariant.premium => ext.premiumButtonGradient,
  };

  /// The gradient's own bottom-most color — darkened to derive the bevel
  /// band beneath the button, so the band always matches this button's
  /// own fill instead of a hand-picked shade per variant.
  Color _baseColor() => switch (variant) {
    GameButtonVariant.primary => AppColors.primaryGradientEnd,
    GameButtonVariant.secondary => AppColors.secondaryGradientEnd,
    GameButtonVariant.premium => AppColors.premiumGradientEnd,
  };

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final textStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(color: Colors.white);

    return PressScale(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: _gradient(ext),
          borderRadius: AppRadius.pillRadius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            ...ext.buttonShadow,
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ), // Inner top gloss effect (faked with drop shadow)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: Colors.white,
                size: 22,
                shadows: [
                  Shadow(
                    color: AppColors.outline.withValues(alpha: 0.5),
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Text(
                label,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
