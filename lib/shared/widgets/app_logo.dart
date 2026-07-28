import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';

/// The game's circular logo mark. Used on Splash and Home so both share a
/// single visual source of truth until a real branded asset replaces it.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFE0E7FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Icon(
        Icons.extension_rounded,
        size: size * 0.53,
        color: AppColors.primary,
      ),
    );
  }
}
