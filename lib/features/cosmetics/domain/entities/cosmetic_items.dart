import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';

/// Anything the player can own and equip with coins: board frames, piece
/// styles, and avatars. A sealed hierarchy so the Cubit can switch over
/// the concrete category without stringly-typed branches.
///
/// Only the [id] is ever persisted — the visual properties are catalog
/// data that can change between releases without a migration.
sealed class CosmeticItem {
  const CosmeticItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });

  final String id;
  final String name;
  final String description;

  /// Cost in coins. 0 means the item is free (the category default).
  final int price;

  /// Human-readable category label, used for analytics.
  String get category;
}

/// The decorative frame around the puzzle board. Rendered as the board's
/// outer border + a soft glow in [glowColor].
class BoardFrame extends CosmeticItem {
  const BoardFrame({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required this.borderColor,
    this.borderWidth = 6,
    required this.glowColor,
    required this.backgroundColor,
  });

  final Color borderColor;
  final double borderWidth;
  final Color glowColor;

  /// The surface color of the board behind the pieces — visible when a
  /// piece style leaves gaps between tiles.
  final Color backgroundColor;

  @override
  String get category => 'board_frame';
}

/// How individual puzzle tiles look: spacing between pieces, corner
/// radius, border tint, and the color used when a piece locks correctly.
class PieceStyle extends CosmeticItem {
  const PieceStyle({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    this.gap = 0,
    this.cornerRadius = 0,
    required this.borderColor,
    required this.correctColor,
    required this.tileBackground,
  });

  /// Spacing (logical pixels) left between adjacent tiles. 0 = seamless
  /// photo, the classic look.
  final double gap;

  /// Corner radius of each tile. 0 = square corners.
  final double cornerRadius;

  /// Border color of a tile that isn't in its home yet.
  final Color borderColor;

  /// Border + glow color once a tile locks into its correct cell.
  final Color correctColor;

  /// Color behind the artwork, visible through rounded corners/gaps.
  final Color tileBackground;

  @override
  String get category => 'piece_style';
}

/// The player's profile icon on Home. Pure icon + color — the id is what
/// persists, so icons can be re-skinned later without touching storage.
class Avatar extends CosmeticItem {
  const Avatar({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  String get category => 'avatar';
}

/// Default, always-owned fallback for each category — used when no
/// cosmetics box exists yet, or a saved id no longer matches the catalog.
const Avatar defaultAvatar = Avatar(
  id: 'default',
  name: 'Player',
  description: 'The classic player profile',
  price: 0,
  icon: Icons.person_rounded,
  color: AppColors.primary,
);
