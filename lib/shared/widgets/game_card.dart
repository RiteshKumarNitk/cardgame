import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_shadows.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_theme_extension.dart';

/// The app's single card surface: rounded corners, a thick dark outline,
/// and a chunky "3D bevel" band beneath — the same toy-block look as
/// [GameButton] — with an optional frosted-glass look for content sitting
/// on top of a colorful background (used on Home/Levels; the glass
/// variant skips the outline/bevel since a visible dark line would fight
/// the translucency).
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

  /// The card's own fill (or gradient's bottom-most color) — darkened to
  /// derive the bevel band, so it always matches whatever color this card
  /// was given rather than a hand-picked shade per call site.
  Color _bevelBase() {
    final gradient = this.gradient;
    if (gradient is LinearGradient && gradient.colors.isNotEmpty) {
      return gradient.colors.last;
    }
    return color ?? AppColors.card;
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final radius = borderRadius ?? AppRadius.lgRadius;

    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: glass
            ? Colors.white.withValues(alpha: 0.16)
            : gradient == null
            ? (color ?? AppColors.card)
            : null,
        gradient: gradient,
        borderRadius: radius,
        border: glass
            ? Border.all(color: Colors.white.withValues(alpha: 0.32), width: 1)
            : Border.all(color: AppColors.outline, width: 1), // Thin glossy outline
        boxShadow: glass ? null : ext.cardShadow,
      ),
      child: child,
    );

    if (!glass) return surface;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: surface,
      ),
    );
  }
}
