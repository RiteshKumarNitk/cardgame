import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../../../shared/widgets/pulsing_glow.dart';

/// Daily Challenge's top bar: back button, title, timer and the current streak.
class DailyChallengeTopBar extends StatelessWidget {
  const DailyChallengeTopBar({
    super.key,
    required this.streak,
    this.timeRemainingSeconds,
    required this.onBack,
  });

  final int streak;
  final int? timeRemainingSeconds;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isLowTime = timeRemainingSeconds != null && timeRemainingSeconds! <= 10;
    
    return Row(
      children: [
        CircleIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        const SizedBox(width: AppSpacing.md),
        
        if (timeRemainingSeconds != null)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLowTime)
                  PulsingGlow(
                    color: AppColors.danger,
                    child: _TimerChip(time: timeRemainingSeconds!, isLowTime: isLowTime),
                  )
                else
                  _TimerChip(time: timeRemainingSeconds!, isLowTime: isLowTime),
              ],
            ),
          )
        else
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
        const SizedBox(width: AppSpacing.sm),
        CircleIconButton(
          icon: Icons.emoji_events_rounded,
          onTap: () => context.goNamed(RouteNames.leaderboard),
        ),
      ],
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.time, required this.isLowTime});
  
  final int time;
  final bool isLowTime;

  @override
  Widget build(BuildContext context) {
    return StatChip(
      icon: Icons.timer_rounded,
      value: '${time}s',
      iconColor: isLowTime ? AppColors.danger : AppColors.secondary,
    );
  }
}
