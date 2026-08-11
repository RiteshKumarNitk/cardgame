import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/color_utils.dart';
import '../../domain/entities/cosmetic_items.dart';

/// The player's avatar: a filled circle in the avatar's color with the
/// avatar's icon on top. Used on Home's top bar and as the Avatar
/// category preview in the cosmetics shop.
class AvatarBadge extends StatelessWidget {
  const AvatarBadge({
    super.key,
    required this.avatar,
    this.size = 48,
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [avatar.color, avatar.color.darken(0.22)],
        ),
        border: Border.all(color: AppColors.outline, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: avatar.color.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        avatar.icon,
        color: Colors.white,
        size: size * 0.54,
        shadows: const [
          Shadow(color: AppColors.outline, offset: Offset(0, 1.5)),
        ],
      ),
    );

    if (onTap == null) return badge;
    return GestureDetector(onTap: onTap, child: badge);
  }
}
