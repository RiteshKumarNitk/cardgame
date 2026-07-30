import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'color_utils.dart';

/// Soft, layered shadow presets. Every elevated surface (card, button,
/// tile) picks one of these instead of hand-rolling a `BoxShadow`.
abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> button = [
    BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 12)),
  ];

  static List<BoxShadow> glow(Color color, {double opacity = 0.45}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: 20,
      spreadRadius: 1,
      offset: const Offset(0, 6),
    ),
  ];

  /// A crisp, un-blurred "3D bevel" band the same shape as the surface
  /// itself, offset straight down by [depth] — reads as a chunky toy-block
  /// base sitting under a button/card/chip. [fillColor] is darkened to
  /// derive the band's color, so it always matches whatever brand color a
  /// widget was given instead of needing a hand-picked shade per call
  /// site. Pair with a thick `AppColors.outline` border on the surface
  /// itself.
  static List<BoxShadow> bevel(
    Color fillColor, {
    double depth = 5,
    double darkenAmount = 0.16,
  }) => [
    BoxShadow(
      color: fillColor.darken(darkenAmount),
      offset: Offset(0, depth),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];
}
