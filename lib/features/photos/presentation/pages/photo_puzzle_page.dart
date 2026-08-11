import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../services/audio_service.dart';
import '../../../../shared/utils/context_read_or_null.dart';
import '../../../../shared/utils/duration_format.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/coin_flight_animation.dart';
import '../../../../shared/widgets/confetti_burst.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../../cosmetics/domain/services/cosmetics_catalog.dart';
import '../../../cosmetics/presentation/bloc/cosmetics_cubit.dart';
import '../../../levels/domain/entities/level.dart';
import '../../../puzzle/domain/puzzle_board_size.dart';
import '../../../puzzle/presentation/widgets/puzzle_board.dart';
import '../../data/photo_progress_service.dart';
import '../../domain/photo_puzzle.dart';
import '../bloc/photo_puzzle_cubit.dart';

/// Photo Puzzle (gameplay) screen: a compact top bar (title, coins,
/// timer, moves) over the same drag-to-swap / tap-to-rotate board as
/// regular levels. On solve the completed photo glows with confetti, coins
/// fly to the wallet chip, and a victory dialog shows the stars — with a
/// one-time coin payout per photo, so replaying for a better star rating
/// stays fun without being farmable.
class PhotoPuzzlePage extends StatelessWidget {
  const PhotoPuzzlePage({
    super.key,
    this.photo,
    this.cubit,
    PhotoProgressService? progressService,
  }) : _progressService = progressService;

  /// The photo to play. Production reads it from the route's `extra`
  /// (the grid page passes it); tests can inject it directly.
  final PhotoPuzzle? photo;

  /// A pre-built cubit (tests). When provided, the page does not create
  /// or dispose it — the caller owns its lifecycle.
  final PhotoPuzzleCubit? cubit;
  final PhotoProgressService? _progressService;

  @override
  Widget build(BuildContext context) {
    final resolved =
        photo ?? (GoRouterState.of(context).extra as PhotoPuzzle?);
    final injected = cubit;

    if (injected != null) {
      // .value does not close the cubit — the caller owns its lifecycle.
      return BlocProvider<PhotoPuzzleCubit>.value(
        value: injected,
        child: _PhotoPuzzleView(photo: resolved),
      );
    }
    return BlocProvider<PhotoPuzzleCubit>(
      create: (context) {
        final cubit = PhotoPuzzleCubit(
          _progressService ?? HivePhotoProgressService(),
        );
        if (resolved != null) cubit.load(resolved);
        return cubit;
      },
      child: _PhotoPuzzleView(photo: resolved),
    );
  }
}

/// How long the completed-board celebration lingers before the dialog.
const _celebrationDelay = Duration(milliseconds: 1600);

/// Fraction of [_celebrationDelay] dedicated to the piece-snap animation.
const _snapFraction = 0.18;

/// Fraction of [_celebrationDelay] dedicated to the border-fade animation.
const _borderFadeFraction = 0.5;

class _PhotoPuzzleView extends StatefulWidget {
  const _PhotoPuzzleView({required this.photo});

  final PhotoPuzzle? photo;

  @override
  State<_PhotoPuzzleView> createState() => _PhotoPuzzleViewState();
}

class _PhotoPuzzleViewState extends State<_PhotoPuzzleView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _solvedController;
  bool _dialogShowing = false;
  final GlobalKey _walletKey = GlobalKey();

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
  void dispose() {
    _solvedController.dispose();
    super.dispose();
  }

  void _restart() {
    setState(() {
      _dialogShowing = false;
      _solvedController.reset();
    });
    context.read<PhotoPuzzleCubit>().restart();
  }

  void _quit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.photoPuzzles);
    }
  }

  Future<void> _celebrateThenShowDialog(
    BuildContext context,
    PhotoPuzzleReady solved,
  ) async {
    _solvedController.forward();
    await Future.delayed(_celebrationDelay);
    if (!mounted || _dialogShowing) return;
    _dialogShowing = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _VictoryDialog(
        solved: solved,
        onReplay: () {
          Navigator.of(dialogContext).pop();
          _restart();
        },
        onDone: () {
          Navigator.of(dialogContext).pop();
          _quit();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;

    return Scaffold(
      body: GameBackground(
        showFloatingPieces: false,
        child: BlocConsumer<PhotoPuzzleCubit, PhotoPuzzleState>(
          listenWhen: (previous, current) =>
              previous is PhotoPuzzleReady &&
              current is PhotoPuzzleReady &&
              !previous.isSolved &&
              current.isSolved,
          listener: (context, state) {
            final solved = state as PhotoPuzzleReady;
            if (solved.coinsAwarded > 0) {
              context.read<WalletCubit>().addCoins(solved.coinsAwarded);
              CoinFlightOverlay.show(
                context: context,
                endKey: _walletKey,
                count: 16,
              );
            }
            AudioService().playVictory();
            _celebrateThenShowDialog(context, solved);
          },
          builder: (context, state) {
            if (photo == null) {
              return const _PhotoMessage(
                message: 'Photo not found.',
                isError: true,
              );
            }
            return switch (state) {
              PhotoPuzzleLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              PhotoPuzzleError(:final message) => _PhotoMessage(
                message: 'Failed to load photo: $message',
                isError: true,
              ),
              PhotoPuzzleReady() => _LoadedPhotoPuzzle(
                state: state,
                walletKey: _walletKey,
                solvedProgress: _solvedController.value,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _LoadedPhotoPuzzle extends StatelessWidget {
  const _LoadedPhotoPuzzle({
    required this.state,
    required this.walletKey,
    required this.solvedProgress,
  });

  final PhotoPuzzleReady state;
  final GlobalKey walletKey;
  final double solvedProgress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Equipped cosmetics from the app root (null in standalone tests,
    // which keeps the classic look).
    final cosmetics = context.watchOrNull<CosmeticsCubit>()?.state;
    final frame = cosmetics == null
        ? null
        : CosmeticsCatalog.frameById(cosmetics.equippedFrame);
    final pieceStyle = cosmetics == null
        ? null
        : CosmeticsCatalog.pieceStyleById(cosmetics.equippedPieceStyle);

    return Column(
      children: [
        const SizedBox(height: AppSpacing.xs),
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.goNamed(RouteNames.photoPuzzles);
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    state.photo.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Coins from the wallet — the flight target on solve.
                BlocBuilder<WalletCubit, int>(
                  builder: (context, coins) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: StatChip(
                      key: walletKey,
                      icon: Icons.monetization_on_rounded,
                      value: formatThousands(coins),
                      iconColor: AppColors.accent,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: StatChip(
                    icon: Icons.timer_rounded,
                    value: formatMinutesSeconds(state.elapsedSeconds),
                    iconColor: AppColors.secondary,
                  ),
                ),
                StatChip(
                  icon: Icons.touch_app_rounded,
                  value: '${state.moves}',
                  iconColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // ── The board — as much of the screen as possible ──
        Expanded(
          child: Stack(
            children: [
              PuzzleBoard(
                dimensions: boardDimensionsFor(LevelDifficulty.medium),
                imageUrl: state.photo.image,
                arrangement: state.arrangement,
                rotations: state.rotations,
                solvedProgress: solvedProgress,
                snapFraction: _snapFraction,
                borderFadeFraction: _borderFadeFraction,
                frame: frame,
                pieceStyle: pieceStyle,
                onSwap: (fromCell, toCell) => context
                    .read<PhotoPuzzleCubit>()
                    .swapPieces(fromCell, toCell),
                onRotate: (cell) => context
                    .read<PhotoPuzzleCubit>()
                    .rotatePiece(cell),
              ),
              if (state.isSolved) ...[
                // Premium glow behind the completed board.
                Positioned.fill(
                  child: IgnorePointer(
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
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Victory Dialog
/// ────────────────────────────────────────────────────────────────────
class _VictoryDialog extends StatelessWidget {
  const _VictoryDialog({
    required this.solved,
    required this.onReplay,
    required this.onDone,
  });

  final PhotoPuzzleReady solved;
  final VoidCallback onReplay;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: BounceIn(
        child: GameCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Photo Complete!',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Star rating ──
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final filled = index < solved.stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Icon(
                      filled
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: filled ? AppColors.accent : AppColors.border,
                      size: 40,
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xs),

              if (solved.isNewBest)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    'New Best!',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),

              Text(
                '${solved.moves} moves · '
                '${formatMinutesSeconds(solved.elapsedSeconds)}',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                solved.firstCompletion
                    ? '+${solved.coinsAwarded} Coins — thanks for solving '
                          '${solved.photo.title}!'
                    : 'Coins already collected for this photo',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: solved.firstCompletion
                      ? AppColors.accent
                      : AppColors.textSecondary,
                  fontWeight: solved.firstCompletion
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Expanded(
                    child: GameButton(
                      label: 'Replay',
                      icon: Icons.replay_rounded,
                      variant: GameButtonVariant.secondary,
                      width: double.infinity,
                      onTap: onReplay,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GameButton(
                      label: 'Done',
                      icon: Icons.check_rounded,
                      width: double.infinity,
                      onTap: onDone,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoMessage extends StatelessWidget {
  const _PhotoMessage({required this.message, required this.isError});

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
