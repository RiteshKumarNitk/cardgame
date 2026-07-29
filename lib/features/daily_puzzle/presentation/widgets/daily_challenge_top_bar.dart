import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/stat_chip.dart';

/// Daily Challenge's top bar: back button, title, and the current streak.
class DailyChallengeTopBar extends StatelessWidget {
  const DailyChallengeTopBar({
    super.key,
    required this.streak,
    required this.onBack,
  });

  final int streak;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'Daily Challenge',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textDark),
          ),
        ),
        StatChip(
          icon: Icons.local_fire_department_rounded,
          value: '$streak',
          iconColor: AppColors.accent,
        ),
      ],
    );
  }
}
