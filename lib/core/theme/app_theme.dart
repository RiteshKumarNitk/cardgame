import 'package:flutter/material.dart';

import '../design_system/app_colors.dart';
import '../design_system/app_radius.dart';
import '../design_system/app_theme_extension.dart';
import '../design_system/app_typography.dart';

/// The game's single, fixed Material 3 theme.
///
/// Deliberately not split into light/dark: premium casual games (Royal
/// Match, Candy Crush, Toon Blast, ...) ship one consistent, colorful
/// brand look regardless of the device's system theme, rather than
/// adapting to OS dark mode.
abstract final class AppTheme {
  static ThemeData get game {
    final colorScheme = const ColorScheme.light().copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      error: AppColors.danger,
      surface: AppColors.card,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.textTheme().titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      ),
      extensions: const [AppThemeExtension.standard],
    );
  }
}
