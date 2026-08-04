import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../domain/entities/achievement.dart';
import '../bloc/achievements_cubit.dart';
import '../bloc/achievements_state.dart';

/// Achievements screen: every milestone in the catalog with live progress.
///
/// Unlocked achievements glow gold with a check badge; locked ones show a
/// progress bar and the coin reward waiting on the other side. Reached
/// the app root as a provider, so despite being reachable via `goNamed`
/// (which replaces the stack) the explicit back button always returns
/// Home — never a dead end.
class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        showFloatingPieces: false,
        showClouds: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _AchievementsTopBar(),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: BlocBuilder<AchievementsCubit, AchievementsState>(
                    builder: (context, state) {
                      if (state is! AchievementsLoaded) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) => _AchievementCard(
                          progress: state.items[index],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementsTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteNames.home);
            }
          },
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'Achievements',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textDark),
          ),
        ),
        BlocBuilder<WalletCubit, int>(
          builder: (context, coins) => StatChip(
            icon: Icons.monetization_on_rounded,
            value: formatThousands(coins),
            iconColor: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.progress});

  final AchievementProgress progress;

  @override
  Widget build(BuildContext context) {
    final achievement = progress.achievement;

    return GameCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      borderRadius: AppRadius.lgRadius,
      child: Row(
        children: [
          _AchievementIcon(progress: progress),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  achievement.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: progress.isUnlocked
                        ? AppColors.accent
                        : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: progress.isUnlocked
                        ? AppColors.textSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (progress.isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Unlocked · +${achievement.rewardCoins} coins',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  )
                else
                  _AchievementProgressBar(progress: progress),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementIcon extends StatelessWidget {
  const _AchievementIcon({required this.progress});

  final AchievementProgress progress;

  @override
  Widget build(BuildContext context) {
    final achievement = progress.achievement;
    final unlocked = progress.isUnlocked;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: unlocked
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.premiumGradientStart,
                  AppColors.premiumGradientEnd,
                ],
              )
            : null,
        color: unlocked ? null : AppColors.border.withValues(alpha: 0.5),
        border: Border.all(
          color: unlocked ? AppColors.accent : AppColors.border,
          width: 2.5,
        ),
      ),
      child: Icon(
        achievementIcon(achievement.iconKey),
        color: unlocked ? Colors.white : AppColors.textSecondary,
        size: 26,
      ),
    );
  }
}

class _AchievementProgressBar extends StatelessWidget {
  const _AchievementProgressBar({required this.progress});

  final AchievementProgress progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 8,
          child: ClipRRect(
            borderRadius: AppRadius.pillRadius,
            child: Stack(
              children: [
                const ColoredBox(color: AppColors.border),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress.fraction,
                    child: const ColoredBox(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${progress.current} / ${progress.achievement.goal} · '
          '+${progress.achievement.rewardCoins} coins',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}