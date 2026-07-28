import 'package:flutter/material.dart';

import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_theme_extension.dart';
import 'press_scale.dart';

enum GameButtonVariant { primary, secondary, premium }

/// The one and only button surface in the app: gradient fill, pill
/// corners, soft shadow, and press-scale feedback (via [PressScale]).
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
          boxShadow: ext.buttonShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 22),
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
