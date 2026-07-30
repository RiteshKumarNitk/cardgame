import 'package:flutter/material.dart';

/// The game's fixed color palette. Every screen pulls colors from here —
/// never from raw hex literals or `Colors.*` sprinkled through widgets —
/// so the whole app can be re-themed from this one file.
abstract final class AppColors {
  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color accent = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);

  static const Color background = Color(0xFFEEF6FF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textDark = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFD9E6F2);
  static const Color shadow = Color(0x1A0F172A); // rgba(15,23,42,0.10)

  // Gradient stops — see AppGradients for the assembled LinearGradients.
  static const Color primaryGradientStart = Color(0xFF5B5BF7);
  static const Color primaryGradientEnd = Color(0xFF3A7BFF);

  static const Color secondaryGradientStart = Color(0xFF6EE7B7);
  static const Color secondaryGradientEnd = Color(0xFF34D399);

  static const Color premiumGradientStart = Color(0xFFFFD54A);
  static const Color premiumGradientEnd = Color(0xFFF59E0B);

  // Difficulty tiers (Level Selection).
  static const Color difficultyEasy = Color(0xFF22C55E);
  static const Color difficultyMedium = Color(0xFF06B6D4);
  static const Color difficultyHard = Color(0xFFF59E0B);
  static const Color difficultyExpert = Color(0xFFEF4444);
  static const Color difficultyMaster = Color(0xFF7C3AED);
}
