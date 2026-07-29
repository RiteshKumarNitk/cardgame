import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/widgets/game_background.dart';
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
      create: (_) =>
          DailyChallengeCubit(
              _service ??
                  DailyChallengeService(HiveDailyChallengeRepository()),
            )
            ..load(),
      child: const _DailyPuzzleView(),
    );
  }
}

class _DailyPuzzleView extends StatelessWidget {
  const _DailyPuzzleView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        onBack: () => context.goNamed(RouteNames.home),
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
    );
  }
}
