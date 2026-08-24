import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../services/audio_service.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../game/onboarding_service.dart';
import '../../../../services/ad_service.dart';
import '../../../../shared/utils/context_read_or_null.dart';
import '../../../../shared/widgets/confetti_burst.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/utils/duration_format.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/difficulty_badge.dart';
import '../../../achievements/presentation/bloc/achievements_cubit.dart';
import '../../../cosmetics/domain/services/cosmetics_catalog.dart';
import '../../../cosmetics/presentation/bloc/cosmetics_cubit.dart';
import '../../../levels/data/datasources/levels_local_datasource.dart';
import '../../../levels/data/repositories/levels_repository_impl.dart';
import '../../../levels/domain/entities/level_config.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../../victory/domain/entities/victory_result.dart';
import '../../domain/puzzle_board_size.dart';
import '../../domain/puzzle_image.dart';
import '../bloc/puzzle_cubit.dart';
import '../bloc/puzzle_state.dart';
import '../widgets/puzzle_board.dart';
import '../../../../shared/widgets/coin_flight_animation.dart';

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
    this.cubit,
  }) : _levelService = levelService;

  final String levelId;
  final LevelService? _levelService;

  /// A pre-built cubit (tests). When provided, the page does not create
  /// or dispose it — the caller owns its lifecycle.
  final PuzzleCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final parsedId = int.tryParse(levelId);
    final injected = cubit;

    if (injected != null) {
      // .value does not close the cubit — the caller owns its lifecycle.
      return BlocProvider<PuzzleCubit>.value(
        value: injected,
        child: _PuzzleView(levelIdIsValid: parsedId != null),
      );
    }
    return BlocProvider<PuzzleCubit>(
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
  bool _isPaused = false;
  final GlobalKey _walletKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final canPop = context.watch<PuzzleCubit>().state is! PuzzleLoaded;

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
                    
                    CoinFlightOverlay.show(
                      context: context,
                      endKey: _walletKey,
                      count: 20,
                    );

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
                        walletKey: _walletKey,
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

  void _togglePause() {
    final current = context.read<PuzzleCubit>().state;
    if (current is! PuzzleLoaded || current.isSolved) return;
    final next = !_isPaused;
    context.read<PuzzleCubit>().setPaused(next);
    setState(() => _isPaused = next);
  }

  void _restart() {
    setState(() => _isPaused = false);
    context.read<PuzzleCubit>().restart();
  }

  void _quit() {
    context.goNamed(RouteNames.home);
  }

  Future<void> _celebrateThenNavigate(
    BuildContext context,
    PuzzleLoaded solved,
  ) async {
    await Future.delayed(_celebrationDelay);
    if (!context.mounted) return;

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
  const _LoadedPuzzle({required this.state, required this.walletKey, required this.onPause});

  final PuzzleLoaded state;
  final GlobalKey walletKey;
  final VoidCallback onPause;

  @override
  State<_LoadedPuzzle> createState() => _LoadedPuzzleState();
}

class _LoadedPuzzleState extends State<_LoadedPuzzle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _solvedController;
  bool _wasSolved = false;

  bool _showTutorial = OnboardingService().shouldShowTutorial();
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

    // Equipped cosmetics from the app root (null in standalone tests,
    // which keeps the classic look). Rebuilds when the loadout changes.
    final cosmetics = context.watchOrNull<CosmeticsCubit>()?.state;
    final frame = cosmetics == null
        ? null
        : CosmeticsCatalog.frameById(cosmetics.equippedFrame);
    final pieceStyle = cosmetics == null
        ? null
        : CosmeticsCatalog.pieceStyleById(cosmetics.equippedPieceStyle);

    final content = Column(
      children: [
        const SizedBox(height: AppSpacing.xs),

        // ── Top Bar ──
        SafeArea(
          bottom: false,
          child: _PuzzleTopBar(
            level: state,
            imageUrl: imageUrl,
            walletKey: widget.walletKey,
            onBack: widget.onPause,
            onPreview: () => _showPreviewSheet(context, state.config, imageUrl),
            onPause: widget.onPause,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // ── Puzzle Board — as much of the screen as possible ──
        Expanded(
          child: Stack(
            children: [
              PuzzleBoard(
                // Remounts on every (re)shuffle so the deal-in entrance
                // animation replays instead of only playing once.
                key: ValueKey(state.shuffleGeneration),
                dimensions: boardDimensionsFromConfig(state.config),
                imageUrl: imageUrl,
                arrangement: state.arrangement,
                solvedProgress: solvedProgress,
                snapFraction: _snapFraction,
                borderFadeFraction: _borderFadeFraction,
                frame: frame,
                pieceStyle: pieceStyle,
                adjacency: state.adjacency,
                grouping: state.grouping,
                onSwap: (fromCell, toCell) => context
                    .read<PuzzleCubit>()
                    .swapPieces(fromCell, toCell),
              ),

              // Combo Listener
              BlocListener<PuzzleCubit, PuzzleState>(
                listenWhen: (previous, current) {
                  if (previous is PuzzleLoaded && current is PuzzleLoaded) {
                    return current.currentCombo > previous.currentCombo && current.currentCombo > 1;
                  }
                  return false;
                },
                listener: (context, state) {
                  final current = state as PuzzleLoaded;
                  final bonus = current.currentCombo * 5;
                  context.read<WalletCubit>().addCoins(bonus);
                  AudioService().playCoinReward(); // Nice feedback for a combo
                  
                  CoinFlightOverlay.show(
                    context: context,
                    endKey: widget.walletKey,
                    count: current.currentCombo * 2,
                  );
                },
                child: const SizedBox.shrink(),
              ),

              // Combo popup overlay
              Positioned(
                top: 20,
                right: 20,
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(
                          parent: animation, curve: Curves.elasticOut,
                        )),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: state.currentCombo > 1
                        ? _ComboBadge(key: ValueKey(state.currentCombo), combo: state.currentCombo)
                        : const SizedBox.shrink(),
                  ),
                ),
              ),

              // Stuck pity-shuffle prompt: appears after several
              // no-progress moves and re-shuffles the board for free.
              if (state.stuckShuffleReady && !state.isSolved)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Center(
                    child: GameButton(
                      label: 'Stuck? Free Shuffle',
                      icon: Icons.shuffle_rounded,
                      height: 48,
                      width: 230,
                      onTap: () =>
                          context.read<PuzzleCubit>().shuffleBoard(),
                    ),
                  ),
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
                                  .withOpacity(0.4),
                              blurRadius: 50,
                              spreadRadius: 15,
                            ),
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 30,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Confetti bursting from the board (skipped when the user
                // has reduced motion enabled).
                if (!MediaQuery.disableAnimationsOf(context))
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

    return Stack(
      children: [
        content,
        if (_showTutorial)
          Positioned.fill(
            child: _TutorialOverlay(
              onDismiss: () {
                OnboardingService().markTutorialSeen();
                setState(() => _showTutorial = false);
              },
            ),
          ),
      ],
    );
  }

  /// Shows the (coin-gated) reference preview large, in a bottom sheet,
  /// instead of an always-on-screen card — so the board itself gets the
  /// full screen, and tapping the preview shows the photo properly
  /// instead of a small inline thumbnail.
  Future<void> _showPreviewSheet(
    BuildContext context,
    LevelConfig config,
    String imageUrl,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _PreviewSheetContent(
        imageUrl: imageUrl,
        dimensions: boardDimensionsFromConfig(config),
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
    required this.walletKey,
    required this.onBack,
    required this.onPreview,
    required this.onPause,
  });

  final PuzzleLoaded level;
  final String imageUrl;
  final GlobalKey walletKey;
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
          // Star target: how many moves away from a perfect (3-star) solve.
          if (!level.isSolved && level.minimalSwaps + 1 - level.moves > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: StatChip(
                icon: Icons.star_rounded,
                value: '3★ in ${level.minimalSwaps + 1 - level.moves}',
                iconColor: AppColors.accent,
              ),
            ),
          // Hint Button
          BlocBuilder<WalletCubit, int>(
            builder: (context, coins) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: CircleIconButton(
                icon: Icons.lightbulb_rounded,
                iconColor: coins >= 10 ? AppColors.warning : AppColors.primary,
                onTap: () async {
                  if (coins >= 10) {
                    final success = await context.read<WalletCubit>().spendCoins(10);
                    if (success && context.mounted) {
                      context.read<PuzzleCubit>().useHint();
                    }
                  } else {
                    // Not enough coins? Offer a rewarded ad!
                    _showRewardedAdOffer(context);
                  }
                },
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

  void _showRewardedAdOffer(BuildContext context) {
    onPause(); // Pause the game while ad offer is showing
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        title: Text(
          'Need Hints?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Watch a short video to earn 50 coins instantly!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onPause(); // Resume game
            },
            child: const Text('No Thanks', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              AdService().showRewardedAd(
                onReward: () {
                  context.read<WalletCubit>().addCoins(50);
                  CoinFlightOverlay.show(
                    context: context,
                    endKey: walletKey,
                    count: 25, // Big reward flight!
                  );
                },
                onAdDismissed: () {
                  onPause(); // Resume game
                },
              );
            },
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            label: const Text('Watch Ad', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
            ),
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

class _ComboBadge extends StatelessWidget {
  const _ComboBadge({super.key, required this.combo});

  final int combo;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.1, // Slight tilt for dynamism
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: AppRadius.pillRadius,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_rounded, color: AppColors.danger, size: 24),
            const SizedBox(width: 4),
            Text(
              'COMBO x$combo!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
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

/// ────────────────────────────────────────────────────────────────────
/// One-time How-to-Play Tutorial
/// ────────────────────────────────────────────────────────────────────
/// Full-screen scrim shown above the very first puzzle board, walking the
/// player through the drag-to-swap gesture and the hint button. Dismissed
/// by tapping "Got it!", which marks it seen.
class _TutorialOverlay extends StatelessWidget {
  const _TutorialOverlay({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: AppColors.background.withValues(alpha: 0.94),
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
                    Icons.touch_app_rounded,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'How to Play',
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _TutorialStep(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Drag to swap',
                    body: 'Drag a piece onto another piece to swap them around.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _TutorialStep(
                    icon: Icons.lightbulb_rounded,
                    title: 'Stuck? Use a hint',
                    body: 'The hint button finds a piece a home for a few coins.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GameButton(
                    label: 'Got it!',
                    icon: Icons.play_arrow_rounded,
                    width: double.infinity,
                    onTap: onDismiss,
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

class _TutorialStep extends StatelessWidget {
  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: AppRadius.mdRadius,
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                body,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
