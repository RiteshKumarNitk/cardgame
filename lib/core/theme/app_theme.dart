import 'package:flutter/material.dart';

import '../design_system/app_colors.dart';
import '../design_system/app_radius.dart';
import '../design_system/app_theme_extension.dart';
import '../design_system/app_typography.dart';

/// The game's single, fixed Material 3 theme — "Warm Tactile Serenity".
///
/// Deliberately not split into light/dark: premium casual games ship one
/// consistent, calm brand look regardless of the device's system theme.
/// SuitClash is light-mode only (permanent design constraint).
abstract final class AppTheme {
  static ThemeData get game {
    final colorScheme = const ColorScheme.light().copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimary,
      secondary: AppColors.accent, // warm honey gold
      onSecondary: AppColors.textDark,
      tertiary: AppColors.attention, // dusty rose — sparing
      onTertiary: AppColors.onPrimary,
      error: AppColors.danger,
      onError: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.textDark,
      surfaceContainerHighest: AppColors.cardWellHigh,
      outline: AppColors.textMeta,
      outlineVariant: AppColors.border,
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
