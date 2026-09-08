import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Named gradients used across buttons, backgrounds, and premium accents.
/// Kept in one place so "what does a primary button look like" only has
/// one answer anywhere in the app.
abstract final class AppGradients {
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
  );

  static const LinearGradient secondaryButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.secondaryGradientStart,
      AppColors.secondaryGradientEnd,
    ],
  );

  static const LinearGradient premiumButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.premiumGradientStart, AppColors.premiumGradientEnd],
  );

  /// The soft, warm backdrop behind every top-level screen.
  /// Light, creamy, and neutral enough that artwork and puzzle photos
  /// remain the visual focus.
  static const LinearGradient screenBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF7FAF5),
      Color(0xFFF1F8F4),
      Color(0xFFEDF4F1),
    ],
  );
}
