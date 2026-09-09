import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../entities/cosmetic_items.dart';
import '../entities/player_cosmetics.dart';

/// The single source of truth for every buyable cosmetic, plus lookups.
///
/// The cosmetics set is deliberately small, clean and premium — a
/// restrained "Classics" range, not a wall of decorative themes. No glow,
/// no gradients, no casino/neon colours, no artificial piece gaps.
///
/// Prices form a real progression so the wallet has long-term purpose:
///   Classic (free) · 1,500 · 3,000 · 5,000 · 7,500 · 10,000
/// Only the [id] is ever persisted, so changing prices or trimming the
/// catalogue never re-locks an item the player already owns.
abstract final class CosmeticsCatalog {
  // Price tiers.
  static const int _free = 0;
  static const int _common = 1500;
  static const int _premium = 3000;
  static const int _higher = 5000;
  static const int _rare = 7500;
  static const int _highest = 10000;

  // ── Board Frames — clean hairline borders, no glow ──
  static final List<BoardFrame> frames = [
    const BoardFrame(
      id: PlayerCosmetics.defaultFrameId, // 'classic'
      name: 'Classic',
      description: 'A clean hairline edge — the artwork does the talking',
      price: _free,
      borderColor: AppColors.border,
      borderWidth: 1.5,
      glowColor: Colors.transparent,
      backgroundColor: AppColors.cardWell,
    ),
    const BoardFrame(
      id: 'ivory',
      name: 'Ivory',
      description: 'A soft warm-white border',
      price: _common,
      borderColor: Color(0xFFE6E0D2),
      borderWidth: 3,
      glowColor: Colors.transparent,
      backgroundColor: AppColors.surfaceLow,
    ),
    const BoardFrame(
      id: 'sage',
      name: 'Sage',
      description: 'A quiet sage-green edge',
      price: _premium,
      borderColor: AppColors.primaryContainer,
      borderWidth: 3,
      glowColor: Colors.transparent,
      backgroundColor: AppColors.cardWell,
    ),
    const BoardFrame(
      id: 'slate',
      name: 'Slate',
      description: 'A deep moss border for a bold, minimal look',
      price: _higher,
      borderColor: AppColors.textDark,
      borderWidth: 3,
      glowColor: Colors.transparent,
      backgroundColor: AppColors.cardWell,
    ),
  ];

  // ── Piece Styles — seamless only ──
  static final List<PieceStyle> pieceStyles = [
    const PieceStyle(
      id: PlayerCosmetics.defaultPieceStyleId, // 'classic'
      name: 'Classic',
      description: 'Seamless pieces — the photo looks whole',
      price: _free,
      gap: 0,
      cornerRadius: 0,
      borderColor: AppColors.border,
      correctColor: AppColors.success,
      tileBackground: AppColors.card,
    ),
  ];

  // ── Avatars — flat, on-brand, distinctive silhouettes ──
  static final List<Avatar> avatars = [
    const Avatar(
      id: PlayerCosmetics.defaultAvatarId, // 'default'
      name: 'Player',
      description: 'The classic profile',
      price: _free,
      icon: Icons.person_rounded,
      color: AppColors.primary,
    ),
    const Avatar(
      id: 'paw',
      name: 'Paw',
      description: 'For animal lovers',
      price: _common,
      icon: Icons.pets_rounded,
      color: AppColors.honeyText,
    ),
    const Avatar(
      id: 'leaf',
      name: 'Leaf',
      description: 'Calm and growing',
      price: _common,
      icon: Icons.eco_rounded,
      color: AppColors.primaryContainer,
    ),
    const Avatar(
      id: 'heart',
      name: 'Heart',
      description: 'Spread the love',
      price: _premium,
      icon: Icons.favorite_rounded,
      color: AppColors.attention,
    ),
    const Avatar(
      id: 'rocket',
      name: 'Rocket',
      description: 'Blast off',
      price: _premium,
      icon: Icons.rocket_launch_rounded,
      color: AppColors.textSecondary,
    ),
    const Avatar(
      id: 'music',
      name: 'Music',
      description: 'Play it loud',
      price: _higher,
      icon: Icons.music_note_rounded,
      color: AppColors.attentionStrong,
    ),
    const Avatar(
      id: 'smiley',
      name: 'Smiley',
      description: 'Always smiling',
      price: _higher,
      icon: Icons.mood_rounded,
      color: AppColors.honeyText,
    ),
    const Avatar(
      id: 'bolt',
      name: 'Bolt',
      description: 'Speed runner',
      price: _rare,
      icon: Icons.bolt_rounded,
      color: AppColors.warning,
    ),
    const Avatar(
      id: 'star',
      name: 'Star',
      description: 'A natural superstar',
      price: _rare,
      icon: Icons.star_rounded,
      color: AppColors.honey,
    ),
    const Avatar(
      id: 'gamer',
      name: 'Gamer',
      description: 'Game on',
      price: _highest,
      icon: Icons.sports_esports_rounded,
      color: AppColors.primary,
    ),
    const Avatar(
      id: 'gem',
      name: 'Gem',
      description: 'The rarest of the rare',
      price: _highest,
      icon: Icons.diamond_rounded,
      color: AppColors.textDark,
    ),
  ];

  // ── Lookups (fall back to defaults so UI never crashes on stale ids) ──

  static BoardFrame frameById(String id) =>
      frames.firstWhere((f) => f.id == id, orElse: () => frames.first);

  static PieceStyle pieceStyleById(String id) => pieceStyles.firstWhere(
    (p) => p.id == id,
    orElse: () => pieceStyles.first,
  );

  static Avatar avatarById(String id) =>
      avatars.firstWhere((a) => a.id == id, orElse: () => avatars.first);

  static Set<String> get frameIds => frames.map((f) => f.id).toSet();
  static Set<String> get pieceStyleIds =>
      pieceStyles.map((p) => p.id).toSet();
  static Set<String> get avatarIds => avatars.map((a) => a.id).toSet();
}
