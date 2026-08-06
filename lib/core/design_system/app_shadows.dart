import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Soft, layered shadow presets. Every elevated surface (card, button,
/// tile) picks one of these instead of hand-rolling a `BoxShadow`.
abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4), spreadRadius: -2),
    BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2), spreadRadius: -1),
  ];

  static const List<BoxShadow> button = [
    BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 4), spreadRadius: -2),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, 10), spreadRadius: -4),
  ];

  static List<BoxShadow> glow(Color color, {double opacity = 0.45}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: 24,
      spreadRadius: 2,
      offset: const Offset(0, 8),
    ),
  ];

  /// We no longer use a chunky "3D bevel" band beneath for the water bubble
  /// theme, so this returns an empty list, but the method remains to avoid
  /// breaking existing call sites that still pass it.
  static List<BoxShadow> bevel(
    Color fillColor, {
    double depth = 5,
    double darkenAmount = 0.16,
  }) => const [];
}
