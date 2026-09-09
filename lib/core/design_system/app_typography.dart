import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text styles for the game — **Plus Jakarta Sans** throughout (geometric
/// precision with friendly open apertures), matching the SuitClash Stitch
/// design system. Screens should always read from
/// `Theme.of(context).textTheme` rather than calling `GoogleFonts.*`
/// directly, so every label shares one type system.
///
/// Scale (Stitch): display 40/32 · headline 28/22/18 · body 16/14/12 ·
/// label 14/12/11 (bold, slight positive tracking). Headlines carry a
/// small negative tracking for structural polish.
abstract final class AppTypography {
  static TextStyle _jakarta({
    required double size,
    required FontWeight weight,
    double? lineHeight,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      height: lineHeight == null ? null : lineHeight / size,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme textTheme([Color color = AppColors.textDark]) {
    final base = TextTheme(
      displayLarge: _jakarta(
        size: 40,
        weight: FontWeight.w800,
        lineHeight: 48,
        letterSpacing: -0.8,
      ),
      displayMedium: _jakarta(
        size: 32,
        weight: FontWeight.w800,
        lineHeight: 40,
        letterSpacing: -0.6,
      ),
      displaySmall: _jakarta(
        size: 28,
        weight: FontWeight.w700,
        lineHeight: 36,
        letterSpacing: -0.3,
      ),
      headlineLarge: _jakarta(
        size: 28,
        weight: FontWeight.w700,
        lineHeight: 36,
        letterSpacing: -0.3,
      ),
      headlineMedium: _jakarta(
        size: 22,
        weight: FontWeight.w700,
        lineHeight: 28,
        letterSpacing: -0.2,
      ),
      headlineSmall: _jakarta(size: 18, weight: FontWeight.w600, lineHeight: 24),
      titleLarge: _jakarta(size: 18, weight: FontWeight.w700, lineHeight: 24),
      titleMedium: _jakarta(size: 16, weight: FontWeight.w600, lineHeight: 22),
      titleSmall: _jakarta(size: 14, weight: FontWeight.w600, lineHeight: 20),
      bodyLarge: _jakarta(size: 16, weight: FontWeight.w500, lineHeight: 24),
      bodyMedium: _jakarta(size: 14, weight: FontWeight.w500, lineHeight: 20),
      bodySmall: _jakarta(size: 12, weight: FontWeight.w500, lineHeight: 16),
      labelLarge: _jakarta(
        size: 14,
        weight: FontWeight.w700,
        lineHeight: 18,
        letterSpacing: 0.3,
      ),
      labelMedium: _jakarta(
        size: 12,
        weight: FontWeight.w700,
        lineHeight: 16,
        letterSpacing: 0.4,
      ),
      labelSmall: _jakarta(
        size: 11,
        weight: FontWeight.w700,
        lineHeight: 14,
        letterSpacing: 0.5,
      ),
    );
    return base.apply(displayColor: color, bodyColor: color);
  }

  /// Applies tabular (fixed-width) figures. Use for move counts, coin
  /// balances, timers and any number that updates in place, so digits
  /// don't jitter as they change.
  static TextStyle? tabular(TextStyle? style) => style?.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
