import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_shadows.dart';
import '../../core/design_system/app_spacing.dart';
import 'press_scale.dart';

enum GameButtonVariant { primary, secondary, premium }

/// The app's primary button surface — "Warm Tactile Serenity": a **solid**
/// pill fill with a hard resting "cushion" edge beneath it (via
/// [AppShadows.tactile]) so it feels physically pressable, plus press-scale
/// feedback (via [PressScale]). Every CTA — Play, menu tiles, dialogs —
/// should use this instead of a bespoke `Container`/`ElevatedButton`.
///
/// * primary   — Soft Sage fill, white label. Main CTAs.
/// * secondary — Warm cream fill, hairline stroke, dark label.
/// * premium   — Honey Gold fill, dark label. Coin / boost actions.
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

  ({Color fill, Color fg, Color cushion, Color? stroke}) _palette() =>
      switch (variant) {
        GameButtonVariant.primary => (
          fill: AppColors.primaryContainer,
          fg: AppColors.onPrimary,
          cushion: AppColors.primaryButtonCushion,
          stroke: null,
        ),
        GameButtonVariant.secondary => (
          fill: AppColors.card,
          fg: AppColors.textDark,
          cushion: AppColors.border,
          stroke: AppColors.border,
        ),
        GameButtonVariant.premium => (
          fill: AppColors.honey,
          fg: AppColors.textDark,
          cushion: AppColors.premiumGradientEnd,
          stroke: null,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: p.fg,
      letterSpacing: 0.4,
    );

    return PressScale(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: p.fill,
          borderRadius: AppRadius.pillRadius,
          border: p.stroke == null
              ? null
              : Border.all(color: p.stroke!, width: 1.5),
          boxShadow: variant == GameButtonVariant.secondary
              ? AppShadows.pill
              : AppShadows.tactile(p.cushion),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: p.fg, size: 20),
              const SizedBox(width: AppSpacing.xs),
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
