import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_theme_extension.dart';

/// The app's card surface — "Warm Tactile Serenity": rounded corners, a
/// 1px warm feather outline, and a soft warm dual-layer shadow (L2). An
/// optional translucent "glass" variant for content sitting directly on
/// the ivory background (Home / Levels) — warm paper-translucent rather
/// than cold frosted glass.
class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius,
    this.gradient,
    this.color,
    this.glass = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final Color? color;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final radius = borderRadius ?? AppRadius.lgRadius;

    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: glass
            ? AppColors.background.withValues(alpha: 0.82)
            : gradient == null
            ? (color ?? AppColors.card)
            : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: AppColors.border, width: 1),
        // Glass cards take the lighter pill shadow so they don't read as
        // heavily elevated while translucent.
        boxShadow: glass ? ext.pillShadow : ext.cardShadow,
      ),
      child: child,
    );

    if (!glass) return surface;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: surface,
      ),
    );
  }
}
