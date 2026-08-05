import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../puzzle/domain/puzzle_board_size.dart';
import '../../../puzzle/presentation/widgets/puzzle_board.dart';
import '../../../puzzle/presentation/widgets/puzzle_preview_thumbnail.dart';
import '../bloc/daily_challenge_cubit.dart';
import '../bloc/daily_challenge_state.dart';

class DailyPuzzleBoardView extends StatelessWidget {
  const DailyPuzzleBoardView({super.key, required this.state});

  final DailyChallengeReady state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PuzzlePreviewThumbnail(imageUrl: state.imageUrl),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Stack(
            children: [
              PuzzleBoard(
                dimensions: boardDimensionsFor(state.challenge.difficulty),
                imageUrl: state.imageUrl,
                arrangement: state.arrangement,
                rotations: state.rotations,
                onSwap: (fromCell, toCell) => context
                    .read<DailyChallengeCubit>()
                    .swapPieces(fromCell, toCell),
                onRotate: (cell) => context
                    .read<DailyChallengeCubit>()
                    .rotatePiece(cell),
              ),
              if (state.isFailed)
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.background.withValues(alpha: 0.92),
                    child: Center(
                      child: BounceIn(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: GameCard(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_off_rounded,
                                  size: 56,
                                  color: AppColors.danger,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Time\'s Up!',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'You ran out of time.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                BlocBuilder<WalletCubit, int>(
                                  builder: (context, coins) {
                                    return GameButton(
                                      label: 'Retry (50 coins)',
                                      icon: Icons.replay_rounded,
                                      width: double.infinity,
                                      variant: coins >= 50 ? GameButtonVariant.primary : GameButtonVariant.secondary,
                                      onTap: () {
                                        context.read<DailyChallengeCubit>().retry((amount) => context.read<WalletCubit>().spendCoins(amount));
                                      },
                                    );
                                  }
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
