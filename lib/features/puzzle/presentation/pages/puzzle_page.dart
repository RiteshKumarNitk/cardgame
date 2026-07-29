import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../levels/data/datasources/levels_local_datasource.dart';
import '../../../levels/data/repositories/levels_repository_impl.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../../victory/domain/entities/victory_result.dart';
import '../../domain/puzzle_image.dart';
import '../bloc/puzzle_cubit.dart';
import '../bloc/puzzle_state.dart';
import '../widgets/puzzle_board.dart';
import '../widgets/puzzle_piece_tray.dart';
import '../widgets/puzzle_preview_thumbnail.dart';
import '../widgets/puzzle_top_bar.dart';

/// Puzzle (gameplay) screen: top bar, board, and piece tray for the
/// requested level. Drag a piece from the tray onto its matching board
/// slot; solving the puzzle persists progress via [PuzzleCubit] and
/// advances to Victory.
class PuzzlePage extends StatelessWidget {
  /// [levelService] defaults to the real Hive-backed stack; tests can
  /// supply a service built on an in-memory fake instead.
  const PuzzlePage({
    super.key,
    required this.levelId,
    LevelService? levelService,
  }) : _levelService = levelService;

  final String levelId;
  final LevelService? _levelService;

  @override
  Widget build(BuildContext context) {
    final parsedId = int.tryParse(levelId);

    return BlocProvider(
      create: (_) {
        final cubit = PuzzleCubit(
          _levelService ??
              LevelService(LevelsRepositoryImpl(HiveLevelsLocalDataSource())),
        );
        if (parsedId != null) cubit.loadLevel(parsedId);
        return cubit;
      },
      child: _PuzzleView(levelIdIsValid: parsedId != null),
    );
  }
}

class _PuzzleView extends StatelessWidget {
  const _PuzzleView({required this.levelIdIsValid});

  final bool levelIdIsValid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        showFloatingPieces: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: BlocConsumer<PuzzleCubit, PuzzleState>(
              listenWhen: (previous, current) =>
                  previous is PuzzleLoaded &&
                  current is PuzzleLoaded &&
                  !previous.isSolved &&
                  current.isSolved,
              listener: (context, state) {
                final solved = state as PuzzleLoaded;
                context.read<WalletCubit>().addCoins(solved.coinsAwarded);
                context.goNamed(
                  RouteNames.victory,
                  extra: VictoryResult(
                    level: solved.level,
                    stars: solved.stars,
                    moves: solved.moves,
                    timeSeconds: solved.elapsedSeconds,
                    coinsEarned: solved.coinsAwarded,
                    nextLevelId: context.read<PuzzleCubit>().nextLevelId,
                  ),
                );
              },
              builder: (context, state) {
                if (!levelIdIsValid) {
                  return const _PuzzleMessage(
                    message: 'Invalid level.',
                    isError: true,
                  );
                }
                return switch (state) {
                  PuzzleInitial() || PuzzleLoading() => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  PuzzleError(:final message) => _PuzzleMessage(
                    message: 'Failed to load level: $message',
                    isError: true,
                  ),
                  PuzzleLoaded() => _LoadedPuzzle(state: state),
                };
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadedPuzzle extends StatelessWidget {
  const _LoadedPuzzle({required this.state});

  final PuzzleLoaded state;

  @override
  Widget build(BuildContext context) {
    final imageUrl = puzzleImageUrlFor(state.level.id);

    return Column(
      children: [
        PuzzleTopBar(
          level: state.level,
          elapsedSeconds: state.elapsedSeconds,
          moves: state.moves,
          onBack: () => context.goNamed(RouteNames.levels),
          onPause: () => _showPauseDialog(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        PuzzlePreviewThumbnail(imageUrl: imageUrl),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: PuzzleBoard(
            difficulty: state.level.difficulty,
            imageUrl: imageUrl,
            placedPieceIds: state.placedPieceIds,
            onDrop: (pieceIndex, slotIndex) => context
                .read<PuzzleCubit>()
                .attemptPlacePiece(pieceIndex, slotIndex),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PuzzlePieceTray(
          difficulty: state.level.difficulty,
          shuffleSeed: state.level.id,
          imageUrl: imageUrl,
          placedPieceIds: state.placedPieceIds,
        ),
      ],
    );
  }
}

void _showPauseDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      child: GameCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pause_circle_filled_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Paused',
              style: Theme.of(
                dialogContext,
              ).textTheme.titleLarge?.copyWith(color: AppColors.textDark),
            ),
            const SizedBox(height: AppSpacing.lg),
            GameButton(
              label: 'Resume',
              icon: Icons.play_arrow_rounded,
              width: 220,
              onTap: () => Navigator.of(dialogContext).pop(),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                dialogContext.goNamed(RouteNames.levels);
              },
              child: const Text('Back to Levels'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PuzzleMessage extends StatelessWidget {
  const _PuzzleMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isError ? AppColors.danger : AppColors.textDark,
        ),
      ),
    );
  }
}
