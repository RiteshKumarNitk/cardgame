import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../domain/entities/section.dart';

/// Milestone divider marking the end of a [Section] on the Journey Map —
/// lights up green once its last level is completed, otherwise reads as an
/// upcoming waypoint.
class SectionCompleteBanner extends StatelessWidget {
  const SectionCompleteBanner({
    super.key,
    required this.section,
    required this.reached,
  });

  final Section section;

  /// Whether the section's last level has been completed.
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final color = reached ? AppColors.success : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Divider(color: color.withValues(alpha: 0.4))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  reached ? Icons.emoji_events_rounded : Icons.flag_rounded,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Section ${section.index} Complete',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: color),
                ),
              ],
            ),
          ),
          Expanded(child: Divider(color: color.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}
