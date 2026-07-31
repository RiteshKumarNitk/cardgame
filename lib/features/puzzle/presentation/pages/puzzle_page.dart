import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../services/audio_service.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/widgets/confetti_burst.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../../../shared/utils/duration_format.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/difficulty_badge.dart';
import '../../../levels/data/datasources/levels_local_datasource.dart';
import '../../../levels/data/repositories/levels_repository_impl.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../../victory/domain/entities/victory_result.dart';
import '../../domain/puzzle_board_size.dart';
import '../../domain/puzzle_image.dart';
import '../bloc/puzzle_cubit.dart';
import '../bloc/puzzle_state.dart';
import '../widgets/puzzle_board.dart';
import '../widgets/puzzle_preview_thumbnail.dart';

/// Puzzle (gameplay) screen: premium top bar with difficulty, timer, moves,
/// reference preview thumbnail, drag-and-drop board, and bottom action bar.
///
/// On solve, the completed board receives a satisfying glow + confetti burst,
/// then after a brief celebration delay navigates to Victory with the
/// full [VictoryResult].
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

/// How long the completed board celebration lingers before Victory.
const _celebrationDelay = Duration(milliseconds: 2800);

/// Fraction of [_celebrationDelay] dedicated to the piece-snap animation.
const _snapFraction = 0.18;

/// Fraction of [_celebrationDelay] dedicated to the border-fade animation.
const _borderFadeFraction = 0.5;

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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: BlocConsumer<PuzzleCubit, PuzzleState>(
              listenWhen: (previous, current) =>
                  previous is PuzzleLoaded &&
                  current is PuzzleLoaded &&
                  !previous.isSolved &&
                  current.isSolved,
              listener: (context, state) {
                final solved = state as PuzzleLoaded;
                context.read<WalletCubit>().addCoins(solved.coinsAwarded);
                _celebrateThenNavigate(context, solved);
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

  Future<void> _celebrateThenNavigate(
    BuildContext context,
    PuzzleLoaded solved,
  ) async {
    await Future.delayed(_celebrationDelay);
    if (!context.mounted) return;

    // Always land on Victory first, even when this was a chapter's last
    // level — Victory shows its own "Chapter Complete" banner in that
    // case, and its Continue button routes onward to the full Chapter
    // Complete celebration. See VictoryPage's _ActionButtons.
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
  }
}

class _LoadedPuzzle extends StatefulWidget {
  const _LoadedPuzzle({super.key, required this.state});

  final PuzzleLoaded state;

  @override
  State<_LoadedPuzzle> createState() => _LoadedPuzzleState();
}

class _LoadedPuzzleState extends State<_LoadedPuzzle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _solvedController;
  bool _wasSolved = false;

  @override
  void initState() {
    super.initState();
    _solvedController = AnimationController(
      vsync: this,
      duration: _celebrationDelay,
    );
    AudioService().playLevelStart();
  }

  @override
  void didUpdateWidget(covariant _LoadedPuzzle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.state.isSolved && widget.state.isSolved && !_wasSolved) {
      _wasSolved = true;
      _solvedController.forward();
    }
  }

  @override
  void dispose() {
    _solvedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final imageUrl = puzzleImageUrlFor(state.level.id);
    final solvedProgress = _solvedController.value;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.xs),

        // ── Top Bar ──
        _PuzzleTopBar(
          level: state,
          imageUrl: imageUrl,
          onBack: () => context.goNamed(RouteNames.home),
          onPause: () => _showPauseDialog(context),
          onPreview: () => _showPreviewSheet(context, imageUrl),
        ),

        const SizedBox(height: AppSpacing.xs),

        // ── Puzzle Board — as much of the screen as possible ──
        Expanded(
          child: Stack(
            children: [
              PuzzleBoard(
                dimensions: boardDimensionsForLevel(state.level.id),
                imageUrl: imageUrl,
                arrangement: state.arrangement,
                solvedProgress: solvedProgress,
                snapFraction: _snapFraction,
                borderFadeFraction: _borderFadeFraction,
                onSwap: (fromCell, toCell) => context
                    .read<PuzzleCubit>()
                    .swapPieces(fromCell, toCell),
              ),

              // Solved celebration overlay
              if (state.isSolved) ...[
                // Premium glow behind the completed board
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.lgRadius,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.premiumGradientStart
                                  .withValues(alpha: 0.4),
                              blurRadius: 50,
                              spreadRadius: 15,
                            ),
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 30,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Confetti bursting from the board
                const Positioned.fill(
                  child: IgnorePointer(child: ConfettiBurst()),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // ── Bottom Action Bar ──
        _BottomActionBar(
          isSolved: state.isSolved,
          onShuffle: () {},
          onHint: () {},
          onUndo: () {},
          onPause: () => _showPauseDialog(context),
        ),

        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }
}

/// Shows the (coin-gated) reference preview in a bottom sheet instead of
/// an always-on-screen card, so the board itself gets the full screen.
void _showPreviewSheet(BuildContext context, String imageUrl) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: PuzzlePreviewThumbnail(imageUrl: imageUrl),
      ),
    ),
  );
}

/// ────────────────────────────────────────────────────────────────────
/// Premium Puzzle Top Bar
/// ────────────────────────────────────────────────────────────────────
class _PuzzleTopBar extends StatelessWidget {
  const _PuzzleTopBar({
    required this.level,
    required this.imageUrl,
    required this.onBack,
    required this.onPause,
    required this.onPreview,
  });

  final PuzzleLoaded level;
  final String imageUrl;
  final VoidCallback onBack;
  final VoidCallback onPause;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: AppSpacing.sm),
          DifficultyBadge(difficulty: level.level.difficulty),
          const SizedBox(width: AppSpacing.sm),
          // Coins from wallet
          BlocBuilder<WalletCubit, int>(
            builder: (context, coins) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: StatChip(
                icon: Icons.monetization_on_rounded,
                value: formatThousands(coins),
                iconColor: AppColors.accent,
              ),
            ),
          ),
          // Hints (placeholder count)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: StatChip(
              icon: Icons.lightbulb_rounded,
              value: '5',
              iconColor: AppColors.success,
            ),
          ),
          // Timer
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: StatChip(
              icon: Icons.timer_rounded,
              value: formatMinutesSeconds(level.elapsedSeconds),
              iconColor: AppColors.secondary,
            ),
          ),
          // Moves
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: StatChip(
              icon: Icons.touch_app_rounded,
              value: '${level.moves}',
              iconColor: AppColors.primary,
            ),
          ),
          CircleIconButton(
            icon: Icons.visibility_rounded,
            iconColor: AppColors.secondary,
            onTap: onPreview,
          ),
          const SizedBox(width: AppSpacing.xs),
          CircleIconButton(
            icon: Icons.pause_rounded,
            iconColor: AppColors.textSecondary,
            onTap: onPause,
          ),
        ],
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Bottom Action Bar (Shuffle, Hint, Undo, Pause)
/// ────────────────────────────────────────────────────────────────────
class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.isSolved,
    required this.onShuffle,
    required this.onHint,
    required this.onUndo,
    required this.onPause,
  });

  final bool isSolved;
  final VoidCallback onShuffle;
  final VoidCallback onHint;
  final VoidCallback onUndo;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.shuffle_rounded,
            label: 'Shuffle',
            color: AppColors.secondary,
            onTap: isSolved ? null : onShuffle,
          ),
          _ActionButton(
            icon: Icons.lightbulb_rounded,
            label: 'Hint',
            color: AppColors.accent,
            onTap: isSolved ? null : onHint,
          ),
          _ActionButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            color: AppColors.primary,
            onTap: isSolved ? null : onUndo,
          ),
          _ActionButton(
            icon: Icons.pause_rounded,
            label: 'Pause',
            color: AppColors.textSecondary,
            onTap: onPause,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEnabled = onTap != null;

    return PressScale(
      onTap: isEnabled ? onTap! : () {},
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Pause Dialog
/// ────────────────────────────────────────────────────────────────────
void _showPauseDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      child: GameCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.pause_circle_filled_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Paused',
              style: Theme.of(dialogContext)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: AppColors.textDark),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Take a break. Your puzzle is waiting.',
              style: Theme.of(dialogContext)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            GameButton(
              label: 'Resume',
              icon: Icons.play_arrow_rounded,
              width: double.infinity,
              height: 60,
              onTap: () => Navigator.of(dialogContext).pop(),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Let the dialog's own close animation finish before the
                // page transition starts, instead of both playing at
                // once.
                await Future.delayed(const Duration(milliseconds: 200));
                if (context.mounted) context.goNamed(RouteNames.home);
              },
              icon: const Icon(Icons.exit_to_app_rounded, size: 18),
              label: const Text('Quit Puzzle'),
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
