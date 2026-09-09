import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_theme_extension.dart';
import '../../core/design_system/app_typography.dart';

/// Compact stadium capsule showing an icon + value — coins / timer / moves
/// on Home, Levels and the Puzzle top bar.
///
/// "Warm Tactile Serenity": semi-translucent ivory pill, an integrated
/// tinted icon *bubble* on the left, and a bold **tabular** number on the
/// right (digits don't jitter as the value updates).
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, AppSpacing.sm, 5),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.9),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: ext.pillShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTypography.tabular(
              Theme.of(context).textTheme.labelLarge,
            )?.copyWith(color: AppColors.textDark),
          ),
        ],
      ),
    );
  }
}
