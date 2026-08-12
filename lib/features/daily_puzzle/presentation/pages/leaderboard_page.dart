import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../services/leaderboard_service.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_card.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        showFloatingPieces: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _LeaderboardTopBar(),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: FutureBuilder<List<LeaderboardEntry>>(
                    future: LeaderboardService().getTopSolvers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      final entries = snapshot.data ?? [];
                      if (entries.isEmpty) {
                        return Center(
                          child: Text(
                            'No times recorded yet!\nBe the first!',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final isFirst = index == 0;
                          return GameCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            borderRadius: AppRadius.mdRadius,
                            gradient: isFirst
                                ? const LinearGradient(
                                    colors: [AppColors.premiumGradientStart, AppColors.premiumGradientEnd],
                                  )
                                : null,
                            child: Row(
                              children: [
                                Text(
                                  '#${index + 1}',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: isFirst ? Colors.white : AppColors.textSecondary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.displayName,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: isFirst ? Colors.white : AppColors.textDark,
                                            ),
                                      ),
                                      Text(
                                        DateFormat.yMMMd().add_jm().format(entry.timestamp),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: isFirst ? Colors.white70 : AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer_rounded,
                                      size: 18,
                                      color: isFirst ? Colors.white : AppColors.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${entry.score}s left',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: isFirst ? Colors.white : AppColors.secondary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
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

class _LeaderboardTopBar extends StatelessWidget {
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
            'Global Leaderboard',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textDark,
                ),
          ),
        ),
        const Icon(Icons.emoji_events_rounded, color: AppColors.warning, size: 32),
      ],
    );
  }
}
