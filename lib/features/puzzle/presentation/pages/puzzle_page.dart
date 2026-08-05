import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../services/audio_service.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/utils/context_read_or_null.dart';
import '../../../../shared/widgets/confetti_burst.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/glass_panel.dart';
import '../../../../shared/widgets/top_bar.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/utils/duration_format.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/difficulty_badge.dart';
import '../../../achievements/presentation/bloc/achievements_cubit.dart';
import '../../../levels/data/datasources/levels_local_datasource.dart';
import '../../../levels/data/repositories/levels_repository_impl.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../../victory/domain/entities/victory_result.dart';
import '../../domain/puzzle_board_size.dart';
import '../../domain/puzzle_image.dart';
import '../bloc/puzzle_cubit.dart';
import '../bloc/puzzle_state.dart';
import '../widgets/puzzle_board.dart';

/// Puzzle (gameplay) screen: a compact top bar (difficulty, coins,
/// timer, moves, preview, pause) over a drag-and-drop board that fills
/// the rest of the screen — no footer. Leaving mid-puzzle is always an
/// explicit choice: the system back button and the top-bar back arrow
/// open the pause menu (Resume / Restart / Give Up) instead of exiting,
/// and the elapsed clock stops while it's up.
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
      create: (context) {
        final cubit = PuzzleCubit(
          _levelService ??
              LevelService(LevelsRepositoryImpl(HiveLevelsLocalDataSource())),
          achievementEvents: context.readOrNull<AchievementsCubit>(),
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

class _PuzzleView extends StatefulWidget {
  const _PuzzleView({required this.levelIdIsValid});

  final bool levelIdIsValid;

  @override
  State<_PuzzleView> createState() => _PuzzleViewState();
}

class _PuzzleViewState extends State<_PuzzleView> {
  /// Whether the pause menu is up. The menu is a full-screen overlay, so
  /// this lives here rather than in [PuzzleCubit] — the cubit only
  /// mirrors it as [PuzzleLoaded.isPaused] to stop the clock.
  bool _isPaused = false;

  @override
  Widget build(BuildContext context) {
    // While a puzzle is loaded, the system back button never leaves the
    // screen: it toggles the pause menu instead. Loading/error/invalid
    // states keep the default pop behavior.
    final canPop = context.read<PuzzleCubit>().state is! PuzzleLoaded;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _togglePause();
      },
      child: Scaffold(
        body: Stack(
          children: [
            GameBackground(
              showFloatingPieces: false,
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
                    if (!widget.levelIdIsValid) {
                      return const _PuzzleMessage(
                        message: 'Invalid level.',
                        isError: true,
                      );
                    }
                    return switch (state) {
                      PuzzleInitial() || PuzzleLoading() => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                      PuzzleError(:final message) => _PuzzleMessage(
                        message: 'Failed to load level: $message',
                        isError: true,
                      ),
                      PuzzleLoaded() => _LoadedPuzzle(
                        state: state,
                        onPause: _togglePause,
                      ),
                    };
                  },
                ),
              ),
            ),
            if (_isPaused)
              Positioned.fill(
                child: _PauseOverlay(
                  onResume: _togglePause,
                  onRestart: _restart,
                  onQuit: _quit,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Opens the pause menu (or closes it when already up), keeping the
  /// [PuzzleCubit]'s clock in sync. No-op while the solve celebration is
  /// playing — the puzzle is already over at that point.
  void _togglePause() {
    final current = context.read<PuzzleCubit>().state;
    if (current is! PuzzleLoaded || current.isSolved) return;
    final next = !_isPaused;
    context.read<PuzzleCubit>().setPaused(next);
    setState(() => _isPaused = next);
  }

  /// Closes the menu and re-shuffles the level from scratch.
  void _restart() {
    setState(() => _isPaused = false);
    context.read<PuzzleCubit>().restart();
  }

  /// Gives up: back to Home, losing current progress on this level.
  void _quit() {
    context.goNamed(RouteNames.home);
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
  const _LoadedPuzzle({required this.state, required this.onPause});

  final PuzzleLoaded state;
  final VoidCallback onPause;

  @override
  State<_LoadedPuzzle> createState() => _LoadedPuzzleState();
}

class _LoadedPuzzleState extends State<_LoadedPuzzle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _solvedController;
  bool _wasSolved = false;

  /// Session-only: once unlocked, stays unlocked for the rest of this
  /// puzzle screen's lifetime, so reopening the preview sheet doesn't
  /// charge coins a second time.
  bool _previewUnlocked = false;

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
        SafeArea(
          bottom: false,
          child: _PuzzleTopBar(
            level: state,
            imageUrl: imageUrl,
            onBack: widget.onPause,
            onPreview: () => _showPreviewSheet(context, state.level.id, imageUrl),
            onPause: widget.onPause,
          ),
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
                rotations: state.rotations,
                solvedProgress: solvedProgress,
                snapFraction: _snapFraction,
                borderFadeFraction: _borderFadeFraction,
                onSwap: (fromCell, toCell) => context
                    .read<PuzzleCubit>()
                    .swapPieces(fromCell, toCell),
                onRotate: (cell) => context
                    .read<PuzzleCubit>()
                    .rotatePiece(cell),
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
      ],
    );
  }

  /// Shows the (coin-gated) reference preview large, in a bottom sheet,
  /// instead of an always-on-screen card — so the board itself gets the
  /// full screen, and tapping the preview shows the photo properly
  /// instead of a small inline thumbnail.
  Future<void> _showPreviewSheet(
    BuildContext context,
    int levelId,
    String imageUrl,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _PreviewSheetContent(
        imageUrl: imageUrl,
        dimensions: boardDimensionsForLevel(levelId),
        unlocked: _previewUnlocked,
        onUnlocked: () => setState(() => _previewUnlocked = true),
      ),
    );
  }
}

/// How much a locked reference preview costs to unlock, in coins.
const _previewUnlockCost = 15;

/// ────────────────────────────────────────────────────────────────────
/// Large Preview Sheet
/// ────────────────────────────────────────────────────────────────────
class _PreviewSheetContent extends StatefulWidget {
  const _PreviewSheetContent({
    required this.imageUrl,
    required this.dimensions,
    required this.unlocked,
    required this.onUnlocked,
  });

  final String imageUrl;
  final BoardDimensions dimensions;
  final bool unlocked;
  final VoidCallback onUnlocked;

  @override
  State<_PreviewSheetContent> createState() => _PreviewSheetContentState();
}

class _PreviewSheetContentState extends State<_PreviewSheetContent> {
  bool _unlocking = false;
  late bool _unlocked;

  @override
  void initState() {
    super.initState();
    _unlocked = widget.unlocked;
  }

  Future<void> _unlock() async {
    setState(() => _unlocking = true);
    final success = await context.read<WalletCubit>().spendCoins(
      _previewUnlockCost,
    );
    if (!mounted) return;
    
    if (success) {
      setState(() {
        _unlocking = false;
        _unlocked = true;
      });
      widget.onUnlocked();
    } else {
      setState(() => _unlocking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GameCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: AppRadius.lgRadius,
                child: AspectRatio(
                  aspectRatio: widget.dimensions.aspectRatio,
                  child: _unlocked
                      ? AppImage(
                          imagePath: widget.imageUrl,
                          fit: BoxFit.fill,
                        )
                      : const ColoredBox(
                          color: AppColors.border,
                          child: Icon(
                            Icons.lock_rounded,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_unlocked)
                Text(
                  'Reference Photo',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark,
                  ),
                )
              else ...[
                Text(
                  'Preview locked',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Spend $_previewUnlockCost coins to see the full photo',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                GameButton(
                  label: _unlocking
                      ? 'Unlocking...'
                      : 'Unlock for $_previewUnlockCost coins',
                  icon: Icons.monetization_on_rounded,
                  variant: GameButtonVariant.premium,
                  width: double.infinity,
                  onTap: _unlocking ? () {} : _unlock,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Premium Puzzle Top Bar
/// ────────────────────────────────────────────────────────────────────
class _PuzzleTopBar extends StatelessWidget {
  const _PuzzleTopBar({
    required this.level,
    required this.imageUrl,
    required this.onBack,
    required this.onPreview,
    required this.onPause,
  });

  final PuzzleLoaded level;
  final String imageUrl;
  final VoidCallback onBack;
  final VoidCallback onPreview;
  final VoidCallback onPause;

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
          // Hint Button
          BlocBuilder<WalletCubit, int>(
            builder: (context, coins) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: CircleIconButton(
                icon: Icons.lightbulb_rounded,
                iconColor: coins >= 10 ? AppColors.warning : AppColors.border,
                onTap: coins >= 10
                    ? () async {
                        final success = await context.read<WalletCubit>().spendCoins(10);
                        if (success && context.mounted) {
                          context.read<PuzzleCubit>().useHint();
                        }
                      }
                    : null,
              ),
            ),
          ),
          CircleIconButton(
            icon: Icons.visibility_rounded,
            iconColor: AppColors.secondary,
            onTap: onPreview,
          ),
          const SizedBox(width: AppSpacing.sm),
          CircleIconButton(
            icon: Icons.pause_rounded,
            iconColor: AppColors.secondary,
            onTap: onPause,
          ),
        ],
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Pause Menu
/// ────────────────────────────────────────────────────────────────────
/// Full-screen scrim with a centered card offering Resume, Restart and
/// Give Up. While it's up, PuzzleCubit.setPaused keeps the elapsed clock
/// stopped, and the board underneath is covered so no stray drag can
/// land on it. The card pops in with [BounceIn].
class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
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
                    Icons.pause_circle_rounded,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Paused',
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'The clock is stopped — take your time.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GameButton(
                    label: 'Resume',
                    icon: Icons.play_arrow_rounded,
                    width: double.infinity,
                    onTap: onResume,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GameButton(
                    label: 'Restart',
                    icon: Icons.restart_alt_rounded,
                    variant: GameButtonVariant.secondary,
                    width: double.infinity,
                    onTap: onRestart,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton.icon(
                    onPressed: onQuit,
                    icon: const Icon(
                      Icons.exit_to_app_rounded,
                      color: AppColors.danger,
                    ),
                    label: Text(
                      'Give Up',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
