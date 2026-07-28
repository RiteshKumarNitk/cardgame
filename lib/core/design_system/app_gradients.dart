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

  /// The soft, colorful backdrop behind every top-level screen.
  static const LinearGradient screenBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEEF6FF),
      Color(0xFFE0E7FF),
      Color(0xFFE0F2FE),
    ],
  );
}
