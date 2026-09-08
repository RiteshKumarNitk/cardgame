import 'package:flutter/material.dart';

/// The game's fixed color palette. Every screen pulls colors from here —
/// never from raw hex literals or `Colors.*` sprinkled through widgets —
/// so the whole app can be re-themed from this one file.
abstract final class AppColors {
  // SuitClash Brand Colors
  static const Color primary = Color(0xFFD32F2F); // Vibrant red — primary actions, accents
  static const Color secondary = Color(0xFF1E1E1E); // Deep charcoal — secondary text, icons
  static const Color accent = Color(0xFFFFC107); // Warm gold — coins, rewards, premium
  static const Color success = Color(0xFF4CAF50); // Fresh green — completion, positive
  static const Color warning = Color(0xFFFF9800); // Warm orange — caution states
  static const Color danger = Color(0xFFD32F2F); // Red — error states

  // Surfaces
  static const Color background = Color(0xFFF1F8F4); // Soft mint-white — main background
  static const Color card = Color(0xFFFFFFFF); // Pure white — cards and elevated surfaces

  // Crisp Text
  static const Color textDark = Color(0xFF263238); // Dark Grey
  static const Color textSecondary = Color(0xFF78909C); // Light Grey
  static const Color border = Color(0xFFCFD8DC); // Grey Border
  static const Color shadow = Color(0x1F000000); // 12% black for soft shadows

  /// Soft translucent outline used for bubble effects
  static const Color outline = Color(0x33FFFFFF); // 20% white gloss

  // Gradient stops
  static const Color primaryGradientStart = Color(0xFFF44336); // Bright red
  static const Color primaryGradientEnd = Color(0xFFB71C1C); // Deep red

  static const Color secondaryGradientStart = Color(0xFF607D8B); // Blue grey
  static const Color secondaryGradientEnd = Color(0xFF37474F); // Dark blue grey

  static const Color premiumGradientStart = Color(0xFFFFE259); // Light gold
  static const Color premiumGradientEnd = Color(0xFFFFA751); // Soft orange

  // Difficulty tiers (Level Selection).
  static const Color difficultyEasy = Color(0xFF81C784);

  // Cosmetic catalog colors (board frames, piece styles, avatars).
  static const Color frameGold = Color(0xFFD4AF37);
  static const Color frameGoldGlow = Color(0xFFFFD700);
  static const Color frameRoyal = Color(0xFF7B1FA2);
  static const Color frameEmerald = Color(0xFF2E7D32);
  static const Color frameMidnight = Color(0xFF1A237E);
  static const Color frameRuby = Color(0xFFB71C1C);
  static const Color pieceNeon = Color(0xFF00E5FF);
  static const Color piecePastelBorder = Color(0xFFF06292);
  static const Color piecePastel = Color(0xFFFCE4EC);
  static const Color avatarBrown = Color(0xFF8D6E63);
  static const Color avatarTeal = Color(0xFF00897B);
  static const Color avatarPink = Color(0xFFEC407A);
  static const Color avatarOrange = Color(0xFFFB8C00);
  static const Color avatarLime = Color(0xFF9E9D24);
  static const Color difficultyMedium = Color(0xFF4FC3F7);
  static const Color difficultyHard = Color(0xFFFFB74D);
  static const Color difficultyExpert = Color(0xFFE57373);
  static const Color difficultyMaster = Color(0xFFBA68C8);
}
