import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../services/audio_service.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/coin_reward_chip.dart';
import '../../../../shared/widgets/confetti_burst.dart';
import '../../../../shared/widgets/fireworks_burst.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/pulsing_glow.dart';
import '../../../../shared/widgets/sparkle_particles.dart';
import '../../domain/entities/level.dart';
import '../../domain/entities/section_complete_result.dart';
import '../widgets/level_difficulty_style.dart';
import '../widgets/section_mosaic.dart';

/// Section Complete celebration: the artwork the player has been
/// collecting is now whole. The last piece "flies in", the mosaic's
/// silhouettes are all gone, a soft glow blooms behind the completed
/// picture, then confetti + sparkles + fireworks + a victory sound play.
/// Rewards (coins, stars, "Collection Added") are shown, and the player
/// presses Continue to unlock the next section — nothing advances
/// automatically.
class SectionCompletePage extends StatefulWidget {
  const SectionCompletePage({super.key, this.result});

  final SectionCompleteResult? result;

  @override
  State<SectionCompletePage> createState() => _SectionCompletePageState();
}

class _SectionCompletePageState extends State<SectionCompletePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _artworkScale;
  late final Animation<double> _artworkGlow;
  late final Animation<double> _contentSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _artworkScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
    );

    _artworkGlow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
    );

    _contentSlide = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOutBack),
    );

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _controller.forward();
        // Reserve the bigger "chapter complete" fanfare for actual
        // chapters (rare); sections complete far more often.
        AudioService().playVictory();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // System back never exits the app mid-celebration: it goes Home,
        // matching the on-screen back arrow and Home action.
        if (didPop) return;
        context.goNamed(RouteNames.home);
      },
      child: Scaffold(
        body: GameBackground(
          showFloatingPieces: false,
          child: Stack(
            children: [
              if (result != null) ...[
                const Positioned.fill(child: FireworksBurst(burstCount: 5)),
                const Positioned.fill(child: ConfettiBurst(particleCount: 46)),
                const Positioned.fill(child: SparkleParticles()),
              ],
              // Main content
              SafeArea(
                child: result == null
                    ? const _NoResultContent()
                    : AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => _SectionCompleteContent(
                          result: result,
                          artworkScale: _artworkScale.value,
                          artworkGlow: _artworkGlow.value,
                          contentSlide: _contentSlide.value,
                        ),
                      ),
              ),
              // Top-left back arrow — never a dead end: always returns
              // Home, so the celebration screen can't strand the player.
              // Painted last so it sits above the scrollable content.
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.goNamed(RouteNames.home),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCompleteContent extends StatelessWidget {
  const _SectionCompleteContent({
    required this.result,
    required this.artworkScale,
    required this.artworkGlow,
    required this.contentSlide,
  });

  final SectionCompleteResult result;
  final double artworkScale;
  final double artworkGlow;
  final double contentSlide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chapter = result.chapter;
    final section = result.section;
    final color = chapter.difficulty.color;
    // Every piece in this section is now collected — a fully-revealed
    // mosaic doubles as "the completed artwork".
    final completedLevels = List<Level>.generate(
      section.levelCount,
      (i) => Level(
        id: section.startLevelId + i,
        title: 'Level ${section.startLevelId + i}',
        difficulty: chapter.difficulty,
        stars: 3,
        isCompleted: true,
        isUnlocked: true,
      ),
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // ── The completed artwork ──
            Transform.scale(
              scale: 0.85 + artworkScale * 0.15,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.xlRadius,
                  border: Border.all(color: AppColors.outline, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3 + artworkGlow * 0.4),
                      blurRadius: 24 + artworkGlow * 30,
                      spreadRadius: artworkGlow * 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.lgRadius,
                  child: SectionMosaic(levels: completedLevels, accentColor: color),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Title ──
            Opacity(
              opacity: contentSlide,
              child: Transform.translate(
                offset: Offset(0, 40 * (1 - contentSlide)),
                child: Column(
                  children: [
                    Text(
                      'Section Complete!',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${chapter.name} · Section ${section.index}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Collection Added ──
            Opacity(
              opacity: contentSlide,
              child: BounceIn(
                delay: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.collections_rounded,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Collection Added',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Stars + Coins ──
            Opacity(
              opacity: contentSlide,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.accent, size: 32),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${result.totalStars} / ${result.maxStars}',
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BounceIn(
                    delay: const Duration(milliseconds: 350),
                    child: CoinRewardChip(coins: result.bonusCoins),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Continue ──
            Opacity(
              opacity: contentSlide,
              child: BounceIn(
                delay: const Duration(milliseconds: 700),
                child: PulsingGlow(
                  color: color,
                  child: GameButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    width: double.infinity,
                    height: 60,
                    onTap: () {
                      final nextLevelId = result.nextLevelId;
                      if (nextLevelId != null) {
                        context.goNamed(
                          RouteNames.puzzle,
                          pathParameters: {'levelId': '$nextLevelId'},
                        );
                      } else {
                        context.goNamed(RouteNames.home);
                      }
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _NoResultContent extends StatelessWidget {
  const _NoResultContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No section result to show.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textDark),
          ),
          const SizedBox(height: AppSpacing.lg),
          GameButton(
            label: 'Back to Home',
            icon: Icons.home_rounded,
            width: 220,
            onTap: () => context.goNamed(RouteNames.home),
          ),
        ],
      ),
    );
  }
}
