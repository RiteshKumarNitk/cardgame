import 'package:flutter/material.dart';

import '../../domain/entities/cosmetic_items.dart';

/// The player's avatar: a clean flat disc in the avatar's colour with a
/// crisp centred icon. No gradient, no glow, no coloured drop-shadow —
/// premium and minimal, consistent with the SuitClash art direction.
class AvatarBadge extends StatelessWidget {
  const AvatarBadge({
    super.key,
    required this.avatar,
    this.size = 44,
    this.onTap,
  });

  final Avatar avatar;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatar.color,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        avatar.icon,
        color: Colors.white,
        size: size * 0.52,
      ),
    );

    if (onTap == null) return badge;
    return GestureDetector(onTap: onTap, child: badge);
  }
}
