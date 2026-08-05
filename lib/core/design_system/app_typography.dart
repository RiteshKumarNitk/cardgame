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
      displayLarge: GoogleFonts.quicksand(
        fontSize: 57,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: GoogleFonts.quicksand(
        fontSize: 45,
        fontWeight: FontWeight.w800,
      ),
      displaySmall: GoogleFonts.quicksand(
        fontSize: 36,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.quicksand(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.quicksand(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.quicksand(fontSize: 22, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w700),
      titleSmall: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700),
      bodyLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500),
      bodySmall: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500),
      labelLarge: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700),
      labelMedium: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700),
      labelSmall: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w700),
    );
    return base.apply(displayColor: color, bodyColor: color);
  }
}
