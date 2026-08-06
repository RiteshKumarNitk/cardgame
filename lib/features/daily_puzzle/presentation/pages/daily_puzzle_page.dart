import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/utils/context_read_or_null.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../achievements/presentation/bloc/achievements_cubit.dart';
import '../../data/daily_challenge_repository_impl.dart';
import '../../domain/services/daily_challenge_service.dart';
import '../bloc/daily_challenge_cubit.dart';
import '../bloc/daily_challenge_state.dart';
import '../widgets/daily_challenge_top_bar.dart';
import '../widgets/daily_completed_card.dart';
import '../widgets/daily_puzzle_board_view.dart';

/// Daily Challenge screen: a fresh piece-matching puzzle every day. Shows
/// the board if today's hasn't been solved yet, otherwise a streak +
/// countdown-to-next-reset card.
class DailyPuzzlePage extends StatelessWidget {
  /// [service] defaults to the real Hive-backed stack; tests can supply
  /// one built on an in-memory fake instead.
  const DailyPuzzlePage({super.key, DailyChallengeService? service})
    : _service = service;

  final DailyChallengeService? _service;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DailyChallengeCubit(
              _service ??
                  DailyChallengeService(HiveDailyChallengeRepository()),
              achievementEvents: context.readOrNull<AchievementsCubit>(),
            )
            ..load(),
      child: const _DailyPuzzleView(),
    );
  }
}

class _DailyPuzzleView extends StatelessWidget {
  const _DailyPuzzleView();

  void _handleBack(BuildContext context) {
    final state = context.read<DailyChallengeCubit>().state;
    if (state is DailyChallengeReady && !state.isComplete) {
      _confirmLeave(context);
      return;
    }
    // Already completed (or loading/error): leaving loses nothing.
    context.goNamed(RouteNames.home);
  }

  Future<void> _confirmLeave(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        title: Text(
          'Leave Daily Challenge?',
          style: Theme.of(dialogContext).textTheme.headlineSmall?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Your progress on today\'s puzzle will be lost.',
          style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Keep Solving',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.goNamed(RouteNames.home);
            },
            icon: const Icon(Icons.exit_to_app_rounded, size: 18),
            label: const Text('Give Up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.pillRadius,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // System back never silently discards an in-progress run (and never
    // exits the app from here): it falls through to the same confirm flow
    // as the top-bar arrow, or Home when there's nothing to lose.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        body: GameBackground(
          showFloatingPieces: false,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: BlocConsumer<DailyChallengeCubit, DailyChallengeState>(
                listenWhen: (previous, current) =>
                    previous is DailyChallengeReady &&
                    current is DailyChallengeReady &&
                    !previous.justSolved &&
                    current.justSolved,
                listener: (context, state) {
                  final solved = state as DailyChallengeReady;
                  context.read<WalletCubit>().addCoins(solved.coinsEarned);
                },
                builder: (context, state) {
                  return switch (state) {
                    DailyChallengeLoading() => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                    DailyChallengeError(:final message) => Center(
                      child: Text(
                        'Failed to load Daily Challenge: $message',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                    DailyChallengeReady() => Column(
                      children: [
                        DailyChallengeTopBar(
                          streak: state.challenge.streak,
                          timeRemainingSeconds: state.isComplete ? null : state.timeRemainingSeconds,
                          onBack: () => _handleBack(context),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Expanded(
                          child: state.isComplete
                              ? DailyCompletedCard(
                                  streak: state.challenge.streak,
                                  justSolved: state.justSolved,
                                  coinsEarned: state.coinsEarned,
                                )
                              : DailyPuzzleBoardView(state: state),
                        ),
                      ],
                    ),
                  };
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
