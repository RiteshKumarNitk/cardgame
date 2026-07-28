import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text styles for the game: Baloo 2 (playful/rounded) for titles and
/// headings, Nunito (clean/friendly) for body and labels. Screens should
/// always read from `Theme.of(context).textTheme` rather than calling
/// `GoogleFonts.*` directly, so every label shares one type system.
abstract final class AppTypography {
  static TextTheme textTheme([Color color = AppColors.textDark]) {
    final base = TextTheme(
      displayLarge: GoogleFonts.baloo2(
        fontSize: 57,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: GoogleFonts.baloo2(
        fontSize: 45,
        fontWeight: FontWeight.w800,
      ),
      displaySmall: GoogleFonts.baloo2(
        fontSize: 36,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.baloo2(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.baloo2(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.baloo2(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.baloo2(fontSize: 22, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
      titleSmall: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800),
      bodyLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
      bodySmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
      labelLarge: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800),
      labelMedium: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800),
      labelSmall: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800),
    );
    return base.apply(displayColor: color, bodyColor: color);
  }
}
