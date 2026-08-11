import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../entities/cosmetic_items.dart';
import '../entities/player_cosmetics.dart';

/// The single source of truth for every buyable cosmetic, plus lookups.
///
/// Prices are the coin sinks that give the wallet a long-term purpose:
/// frame = biggest visual change (400-750), piece style = mid (300-500),
/// avatars = cheap impulse buys (150-400). Owning everything costs
/// roughly 4,700 coins — a stretch goal earned over dozens of levels
/// and daily challenges, not a day-one purchase.
abstract final class CosmeticsCatalog {
  // ── Board Frames ──
  // `final` (not `const`) because several colors are derived with
  // `withValues` at catalog build time.
  static final List<BoardFrame> frames = [
    BoardFrame(
      id: PlayerCosmetics.defaultFrameId,
      name: 'Classic',
      description: 'The clean, timeless frame',
      price: 0,
      borderColor: AppColors.border,
      borderWidth: 2,
      glowColor: AppColors.shadow,
      backgroundColor: AppColors.card,
    ),
    BoardFrame(
      id: 'golden',
      name: 'Golden',
      description: 'A rich gold frame with a warm glow',
      price: 450,
      borderColor: AppColors.frameGold,
      borderWidth: 7,
      glowColor: AppColors.frameGoldGlow,
      backgroundColor: Color(0xFFFFF8E1),
    ),
    BoardFrame(
      id: 'royal',
      name: 'Royal Purple',
      description: 'Deep purple for the royalty in you',
      price: 650,
      borderColor: AppColors.frameRoyal,
      borderWidth: 7,
      glowColor: AppColors.frameRoyal,
      backgroundColor: Color(0xFFF3E5F5),
    ),
    BoardFrame(
      id: 'emerald',
      name: 'Emerald',
      description: 'Casino-green elegance',
      price: 550,
      borderColor: AppColors.frameEmerald,
      borderWidth: 6,
      glowColor: AppColors.frameEmerald,
      backgroundColor: Color(0xFFE8F5E9),
    ),
    BoardFrame(
      id: 'midnight',
      name: 'Midnight',
      description: 'Sleek dark navy for night owls',
      price: 500,
      borderColor: AppColors.frameMidnight,
      borderWidth: 6,
      glowColor: AppColors.frameMidnight,
      backgroundColor: Color(0xFFE8EAF6),
    ),
    BoardFrame(
      id: 'ruby',
      name: 'Ruby',
      description: 'A fiery red frame that pops',
      price: 750,
      borderColor: AppColors.frameRuby,
      borderWidth: 8,
      glowColor: AppColors.frameRuby,
      backgroundColor: Color(0xFFFFEBEE),
    ),
  ];

  // ── Piece Styles ──
  static final List<PieceStyle> pieceStyles = [
    PieceStyle(
      id: PlayerCosmetics.defaultPieceStyleId,
      name: 'Classic',
      description: 'Seamless pieces — the photo looks whole',
      price: 0,
      gap: 0,
      cornerRadius: 0,
      borderColor: AppColors.border,
      correctColor: AppColors.success,
      tileBackground: AppColors.card,
    ),
    PieceStyle(
      id: 'chips',
      name: 'Rounded Chips',
      description: 'Soft rounded pieces with visible seams',
      price: 350,
      gap: 4,
      cornerRadius: 12,
      borderColor: AppColors.border,
      correctColor: AppColors.success,
      tileBackground: AppColors.card,
    ),
    PieceStyle(
      id: 'golden_glow',
      name: 'Golden Glow',
      description: 'Gold-tinted borders; correct pieces shine gold',
      price: 450,
      gap: 2,
      cornerRadius: 8,
      borderColor: AppColors.frameGold.withValues(alpha: 0.55),
      correctColor: AppColors.frameGoldGlow,
      tileBackground: Color(0xFFFFF8E1),
    ),
    PieceStyle(
      id: 'neon',
      name: 'Neon Nights',
      description: 'Electric cyan edges for a late-night vibe',
      price: 500,
      gap: 1,
      cornerRadius: 6,
      borderColor: AppColors.pieceNeon.withValues(alpha: 0.6),
      correctColor: AppColors.pieceNeon,
      tileBackground: Color(0xFFE0F7FA),
    ),
    PieceStyle(
      id: 'pastel',
      name: 'Soft Pastel',
      description: 'Gentle pink corners on every piece',
      price: 300,
      gap: 4,
      cornerRadius: 14,
      borderColor: AppColors.piecePastelBorder.withValues(alpha: 0.5),
      correctColor: AppColors.piecePastelBorder,
      tileBackground: AppColors.piecePastel,
    ),
  ];

  // ── Avatars ──
  static final List<Avatar> avatars = [
    Avatar(
      id: PlayerCosmetics.defaultAvatarId,
      name: 'Player',
      description: 'The classic profile',
      price: 0,
      icon: Icons.person_rounded,
      color: AppColors.primary,
    ),
    Avatar(
      id: 'paw',
      name: 'Paw',
      description: 'For animal lovers',
      price: 150,
      icon: Icons.pets_rounded,
      color: AppColors.avatarBrown,
    ),
    Avatar(
      id: 'heart',
      name: 'Heart',
      description: 'Spread the love',
      price: 150,
      icon: Icons.favorite_rounded,
      color: AppColors.avatarPink,
    ),
    Avatar(
      id: 'rocket',
      name: 'Rocket',
      description: 'Blast off',
      price: 200,
      icon: Icons.rocket_launch_rounded,
      color: AppColors.secondary,
    ),
    Avatar(
      id: 'music',
      name: 'Music',
      description: 'Play it loud',
      price: 200,
      icon: Icons.music_note_rounded,
      color: AppColors.avatarPink,
    ),
    Avatar(
      id: 'star',
      name: 'Star',
      description: 'A natural superstar',
      price: 250,
      icon: Icons.star_rounded,
      color: AppColors.frameGoldGlow,
    ),
    Avatar(
      id: 'smiley',
      name: 'Smiley',
      description: 'Always smiling',
      price: 250,
      icon: Icons.emoji_emotions_rounded,
      color: AppColors.avatarOrange,
    ),
    Avatar(
      id: 'bolt',
      name: 'Bolt',
      description: 'Speed runner',
      price: 300,
      icon: Icons.bolt_rounded,
      color: AppColors.warning,
    ),
    Avatar(
      id: 'sparkle',
      name: 'Sparkle',
      description: 'All that glitters',
      price: 300,
      icon: Icons.auto_awesome_rounded,
      color: AppColors.frameRoyal,
    ),
    Avatar(
      id: 'gamer',
      name: 'Gamer',
      description: 'Game on',
      price: 350,
      icon: Icons.sports_esports_rounded,
      color: AppColors.avatarTeal,
    ),
    Avatar(
      id: 'gem',
      name: 'Gem',
      description: 'The rarest of the rare',
      price: 400,
      icon: Icons.diamond_rounded,
      color: AppColors.pieceNeon,
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
