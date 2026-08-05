import 'package:flutter/material.dart';

/// The game's fixed color palette. Every screen pulls colors from here —
/// never from raw hex literals or `Colors.*` sprinkled through widgets —
/// so the whole app can be re-themed from this one file.
abstract final class AppColors {
  // Soft, clear bubble colors
  static const Color primary = Color(0xFF4CA1AF); // Soft Ocean Blue
  static const Color secondary = Color(0xFF2C3E50); // Deep Water Blue
  static const Color accent = Color(0xFFFFB75E); // Sunlit Amber
  static const Color success = Color(0xFF81D4FA); // Light Cyan
  static const Color danger = Color(0xFFFF8A65); // Soft Coral

  // Material 3 Light Surfaces
  static const Color background = Color(0xFFF0F8FF); // Alice Blue / Water tint
  static const Color card = Color(0xFFFFFFFF); // Pure White

  // Crisp Text
  static const Color textDark = Color(0xFF263238); // Blue Grey 900
  static const Color textSecondary = Color(0xFF78909C); // Blue Grey 400
  static const Color border = Color(0xFFCFD8DC); // Blue Grey 100
  static const Color shadow = Color(0x1F000000); // 12% black for soft shadows

  /// Soft translucent outline used for bubble effects
  static const Color outline = Color(0x33FFFFFF); // 20% white gloss

  // Gradient stops for water bubble glossy buttons
  static const Color primaryGradientStart = Color(0xFF89F7FE); // Cyan bright
  static const Color primaryGradientEnd = Color(0xFF66A6FF); // Soft blue

  static const Color secondaryGradientStart = Color(0xFFA1C4FD); // Light sky
  static const Color secondaryGradientEnd = Color(0xFFC2E9FB); // Pale blue

  static const Color premiumGradientStart = Color(0xFFFFE259); // Yellow glow
  static const Color premiumGradientEnd = Color(0xFFFFA751); // Soft orange

  // Difficulty tiers (Level Selection).
  static const Color difficultyEasy = Color(0xFF81D4FA);
  static const Color difficultyMedium = Color(0xFF4FC3F7);
  static const Color difficultyHard = Color(0xFFFFB74D);
  static const Color difficultyExpert = Color(0xFFFF8A65);
  static const Color difficultyMaster = Color(0xFFBA68C8);
}
