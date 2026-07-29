import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/utils/duration_format.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/coin_reward_chip.dart';
import '../../../../shared/widgets/confetti_burst.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/pulsing_glow.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../../levels/presentation/widgets/level_difficulty_style.dart';
import '../../domain/entities/victory_result.dart';

/// Victory screen: confetti burst, a staggered star reveal, level stats,
/// a placeholder coin reward, and Next Level / Back to Levels actions.
///
/// Reached only from Puzzle (via `extra: VictoryResult`) after solving a
/// board — [result] is null only if the route was somehow opened without
/// that context, in which case a graceful fallback is shown instead of
/// crashing.
class VictoryPage extends StatelessWidget {
  const VictoryPage({super.key, this.result});

  final VictoryResult? result;

  @override
  Widget build(BuildContext context) {
    final result = this.result;

    return Scaffold(
      body: GameBackground(
        showFloatingPieces: false,
        child: Stack(
          children: [
            if (result != null) const Positioned.fill(child: ConfettiBurst()),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: result == null
                        ? const _NoResultContent()
                        : _VictoryContent(result: result),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VictoryContent extends StatelessWidget {
  const _VictoryContent({required this.result});

  final VictoryResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BounceIn(child: _TrophyBadge()),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Level Complete!',
          style: textTheme.headlineMedium?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${result.level.title} · ${result.level.difficulty.label}',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _StarsRow(stars: result.stars),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatChip(
              icon: Icons.timer_rounded,
              value: formatMinutesSeconds(result.timeSeconds),
              iconColor: AppColors.secondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            StatChip(
              icon: Icons.touch_app_rounded,
              value: '${result.moves}',
              iconColor: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        BounceIn(
          delay: const Duration(milliseconds: 500),
          child: CoinRewardChip(coins: result.coinsEarned),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (result.nextLevelId case final nextLevelId?) ...[
          BounceIn(
            delay: const Duration(milliseconds: 600),
            child: PulsingGlow(
              color: AppColors.primaryGradientEnd,
              child: GameButton(
                label: 'Next Level',
                icon: Icons.arrow_forward_rounded,
                width: 220,
                height: 60,
                onTap: () => context.goNamed(
                  RouteNames.puzzle,
                  pathParameters: {'levelId': '$nextLevelId'},
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ] else ...[
          Text(
            'You\'ve completed every level!',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.success),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        TextButton(
          onPressed: () => context.goNamed(RouteNames.levels),
          child: const Text('Back to Levels'),
        ),
      ],
    );
  }
}

class _NoResultContent extends StatelessWidget {
  const _NoResultContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'No level result to show.',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.textDark),
        ),
        const SizedBox(height: AppSpacing.lg),
        GameButton(
          label: 'Back to Levels',
          icon: Icons.grid_view_rounded,
          width: 220,
          onTap: () => context.goNamed(RouteNames.levels),
        ),
      ],
    );
  }
}

class _TrophyBadge extends StatelessWidget {
  const _TrophyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.premiumGradientStart,
            AppColors.premiumGradientEnd,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.emoji_events_rounded,
        color: Colors.white,
        size: 56,
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: BounceIn(
              delay: Duration(milliseconds: 200 + i * 180),
              child: Icon(
                i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                size: 56,
                color: i < stars ? AppColors.accent : AppColors.border,
              ),
            ),
          ),
      ],
    );
  }
}
