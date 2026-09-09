import 'package:flutter/material.dart';

/// The game's fixed color palette — "Warm Tactile Serenity" (the SuitClash
/// Stitch design system is the visual source of truth). Every screen pulls
/// colors from here — never from raw hex literals or `Colors.*` sprinkled
/// through widgets — so the whole app can be re-themed from this one file.
///
/// Personality: calm, tactile, artwork-first. Rich cream/ivory foundations,
/// soft sage as the brand anchor, warm honey-gold for prestige/currency,
/// dusty rose used sparingly for urgency. No casino/gambling cues, no neon,
/// no hyper-saturated toy outlines. Light mode only.
abstract final class AppColors {
  // ── Brand: Soft Sage ──
  /// Deep sage — text, icons, active states on light surfaces.
  static const Color primary = Color(0xFF316342);

  /// Soft sage — primary button fills, CTAs, active trail path, completed
  /// milestones. This is the "brand fill" color.
  static const Color primaryContainer = Color(0xFF4A7C59);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Pale mint — icon bubbles, soft chips, gentle fills.
  static const Color primaryFixed = Color(0xFFB9EFC5);

  /// Mint — progress-bar fills, subtle accents, inverse primary.
  static const Color primaryFixedDim = Color(0xFF9DD3AA);

  // ── Prestige: Warm Honey Gold ──
  /// Honey text / bronze — labels on honey surfaces.
  static const Color honeyText = Color(0xFF7F5700);

  /// Warm honey gold — coins, collected stars, currency badges,
  /// celebratory victory accents. (Alias: [accent].)
  static const Color honey = Color(0xFFFDBA45);

  /// Pale honey — soft badge backgrounds.
  static const Color honeySoft = Color(0xFFFFDEAE);

  // ── Attention: Dusty Rose (used sparingly) ──
  /// Muted coral / dusty rose — streak alerts, urgent counter badges,
  /// "time running low". Never for primary actions.
  static const Color attention = Color(0xFFB85248);
  static const Color attentionStrong = Color(0xFF993A32);

  // ── Semantic aliases (names kept stable for existing call sites) ──
  static const Color secondary = Color(0xFF1C1C18); // deep moss — dark icons/text
  static const Color accent = honey; // coins, rewards, premium
  static const Color success = Color(0xFF3F7D4E); // positive / completion (sage-family)
  static const Color warning = Color(0xFFD99B26); // caution — amber honey
  static const Color danger = Color(0xFFBA1A1A); // error states

  // ── Surfaces (warm ivory / layered cream) ──
  static const Color background = Color(0xFFFCF9F2); // warm ivory cream — app canvas
  static const Color card = Color(0xFFFFFFFF); // lifted cards & playing tiles
  static const Color cardWell = Color(0xFFF0EEE7); // recessed well / tray base
  static const Color cardWellHigh = Color(0xFFE5E2DB); // chips, highest container
  static const Color surfaceLow = Color(0xFFF6F3EC); // low container
  static const Color surfaceDim = Color(0xFFDCDAD3); // dim container

  // ── Text (Deep Moss Bark, not jet black) ──
  static const Color textDark = Color(0xFF1C1C18); // primary text, headings
  static const Color textSecondary = Color(0xFF414942); // secondary labels
  static const Color textMeta = Color(0xFF717971); // muted meta / captions

  // ── Lines & shadow (warm) ──
  static const Color border = Color(0xFFC1C9BF); // hairline borders, dividers
  static const Color shadow = Color(0x14413220); // ~8% warm brown — soft shadows

  /// Feather outline for lifted cards — a 1px warm hairline replacing the
  /// old white gloss. Kept named `outline` for existing call sites.
  static const Color outline = Color(0x142D312E); // ~8% deep moss

  // ── Gradient stops (flattened — SuitClash surfaces are near-flat) ──
  static const Color primaryGradientStart = Color(0xFF4A7C59);
  static const Color primaryGradientEnd = Color(0xFF3F6E4D);

  /// Hard "resting cushion" edge under a tactile primary button.
  static const Color primaryButtonCushion = Color(0xFF365D42);

  static const Color secondaryGradientStart = Color(0xFFFFFFFF);
  static const Color secondaryGradientEnd = Color(0xFFF3EFE6);

  static const Color premiumGradientStart = Color(0xFFFDBA45);
  static const Color premiumGradientEnd = Color(0xFFEBA62E);

  // ── Difficulty tiers — warm ramp (sage → honey → terracotta → rose) ──
  static const Color difficultyEasy = Color(0xFF4A7C59); // sage
  static const Color difficultyMedium = Color(0xFF7FA08A); // sage-grey
  static const Color difficultyHard = Color(0xFFD99B26); // honey amber
  static const Color difficultyExpert = Color(0xFFC9743F); // terracotta
  static const Color difficultyMaster = Color(0xFF993A32); // rose

  // ── Cosmetic catalog colors (board frames, piece styles, avatars) ──
  // Left unchanged in this pass; revisited when the Cosmetics screen is
  // restyled (some are intentionally vivid for unlockable variety).
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
}
