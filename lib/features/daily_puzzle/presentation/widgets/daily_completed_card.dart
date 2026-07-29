import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/coin_reward_chip.dart';
import '../../../../shared/widgets/confetti_burst.dart';
import '../../../../shared/widgets/countdown_timer.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';

/// Shown instead of the board once today's challenge is done — either
/// just now ([justSolved], with confetti and the coin reward) or earlier
/// today (a plain "come back tomorrow" reminder). Either way: the current
/// streak and a countdown to the next challenge.
class DailyCompletedCard extends StatelessWidget {
  const DailyCompletedCard({
    super.key,
    required this.streak,
    required this.justSolved,
    required this.coinsEarned,
  });

  final int streak;
  final bool justSolved;
  final int coinsEarned;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (justSolved) const Positioned.fill(child: ConfettiBurst()),
        SingleChildScrollView(
          child: GameCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  justSolved
                      ? Icons.celebration_rounded
                      : Icons.bedtime_rounded,
                  size: 56,
                  color: AppColors.accent,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  justSolved
                      ? 'Daily Challenge Complete!'
                      : 'Come back tomorrow!',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                if (justSolved) ...[
                  const SizedBox(height: AppSpacing.md),
                  CoinRewardChip(coins: coinsEarned),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '$streak day streak',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Next challenge in',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                CountdownTimer(
                  target: _nextMidnight(),
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GameButton(
                  label: 'Back to Home',
                  icon: Icons.home_rounded,
                  width: 220,
                  onTap: () => context.goNamed(RouteNames.home),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DateTime _nextMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }
}
