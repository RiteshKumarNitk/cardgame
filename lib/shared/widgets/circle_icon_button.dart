import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_shadows.dart';
import 'press_scale.dart';

/// A small circular icon button on a white card surface with a warm
/// hairline outline and a soft pill shadow — the app's standard "utility"
/// button (settings, back, hint, ...) wherever a full [GameButton] would
/// be too heavy.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.primary,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: AppShadows.pill,
        ),
        child: Icon(icon, color: iconColor, size: size * 0.48),
      ),
    );
  }
}
