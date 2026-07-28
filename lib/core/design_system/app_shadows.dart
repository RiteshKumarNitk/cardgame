import 'package:flutter/material.dart';

import 'app_colors.dart';

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
}
