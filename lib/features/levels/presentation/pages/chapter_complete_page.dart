import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../services/audio_service.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/coin_reward_chip.dart';
import '../../../../shared/widgets/confetti_burst.dart';
import '../../../../shared/widgets/fireworks_burst.dart';
import '../../../../shared/widgets/floating_bob.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/pulsing_glow.dart';
import '../../../../shared/widgets/sparkle_particles.dart';
import '../../domain/entities/chapter_complete_result.dart';
import '../widgets/level_difficulty_style.dart';

/// Premium Chapter Complete celebration screen.
///
/// When a player finishes the final level of a chapter, this screen plays
/// a grand celebration: fireworks + confetti + sparkle particles, a large
/// animated chapter badge, total stars earned, a bonus coin reward, and a
/// reveal of the next chapter — all with premium staggered animations.
class ChapterCompletePage extends StatefulWidget {
  const ChapterCompletePage({super.key, this.result});

  final ChapterCompleteResult? result;

  @override
  State<ChapterCompletePage> createState() => _ChapterCompletePageState();
}

class _ChapterCompletePageState extends State<ChapterCompletePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _badgeScale;
  late final Animation<double> _badgeGlow;
  late final Animation<double> _contentSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _badgeScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
    );

    _badgeGlow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
    );

    _contentSlide = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutBack),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.forward();
        AudioService().playChapterComplete();
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
        // matching the on-screen back arrow and Home / View Map actions.
        if (didPop) return;
        context.goNamed(RouteNames.home);
      },
      child: Scaffold(
        body: GameBackground(
          showFloatingPieces: false,
          child: Stack(
            children: [
              // Celebration effects
              if (result != null) ...[
                const Positioned.fill(child: FireworksBurst(burstCount: 6)),
                const Positioned.fill(
                  child: ConfettiBurst(particleCount: 50),
                ),
                const Positioned.fill(child: SparkleParticles()),
              ],

              // Main content
              SafeArea(
                child: result == null
                    ? const _NoResultContent()
                    : AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return _ChapterCompleteContent(
                            result: result,
                            badgeScale: _badgeScale.value,
                            badgeGlow: _badgeGlow.value,
                            contentSlide: _contentSlide.value,
                          );
                        },
                      ),
              ),

              // Top-left back arrow — never a dead end: always returns
              // Home. Painted last so it sits above the scrollable content.
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

class _ChapterCompleteContent extends StatelessWidget {
  const _ChapterCompleteContent({
    required this.result,
    required this.badgeScale,
    required this.badgeGlow,
    required this.contentSlide,
  });

  final ChapterCompleteResult result;
  final double badgeScale;
  final double badgeGlow;
  final double contentSlide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chapter = result.chapter;
    final nextChapter = result.nextChapter;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.xxl),

            // ── Animated Badge ──
            Transform.scale(
              scale: badgeScale,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.premiumGradientStart,
                      AppColors.premiumGradientEnd,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(
                        alpha: 0.3 + badgeGlow * 0.4,
                      ),
                      blurRadius: 20 + badgeGlow * 30,
                      spreadRadius: badgeGlow * 10,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: badgeGlow * 0.25,
                      ),
                      blurRadius: 40,
                      spreadRadius: badgeGlow * 5,
                    ),
                  ],
                ),
                child: Transform.scale(
                  scale: 0.8 + badgeScale * 0.2,
                  child: FloatingBob(
                    range: 4,
                    duration: const Duration(milliseconds: 3000),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      color: Colors.white,
                      size: 72,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Title ──
            Opacity(
              opacity: contentSlide,
              child: Transform.translate(
                offset: Offset(0, 40 * (1 - contentSlide)),
                child: Text(
                  'Chapter Complete!',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            Opacity(
              opacity: contentSlide,
              child: Transform.translate(
                offset: Offset(0, 50 * (1 - contentSlide)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: chapter.difficulty.color.withValues(alpha: 0.1),
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: chapter.difficulty.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${chapter.name} · ${chapter.difficulty.label}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: chapter.difficulty.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Stars Earned ──
            Opacity(
              opacity: contentSlide,
              child: Transform.translate(
                offset: Offset(0, 60 * (1 - contentSlide)),
                child: _ChapterStars(totalStars: result.totalStars, maxStars: result.maxStars),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Bonus Coins ──
            Opacity(
              opacity: contentSlide,
              child: Transform.translate(
                offset: Offset(0, 70 * (1 - contentSlide)),
                child: BounceIn(
                  delay: const Duration(milliseconds: 600),
                  child: CoinRewardChip(coins: result.bonusCoins),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Next Chapter Preview ──
            if (nextChapter != null)
              Opacity(
                opacity: contentSlide,
                child: Transform.translate(
                  offset: Offset(0, 80 * (1 - contentSlide)),
                  child: BounceIn(
                    delay: const Duration(milliseconds: 800),
                    child: GameCard(
                      borderRadius: AppRadius.xlRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          nextChapter.difficulty.color,
                          nextChapter.difficulty.color.withValues(alpha: 0.8),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Text(
                            'CHAPTER ${nextChapter.id} UNLOCKED',
                            style: textTheme.labelMedium?.copyWith(
                              color: Colors.white70,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            nextChapter.name,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${nextChapter.levelCount} levels · ${nextChapter.difficulty.label}',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Progress preview dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              nextChapter.sections.length.clamp(1, 5),
                              (i) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              _AllChaptersComplete(textTheme: textTheme),

            const SizedBox(height: AppSpacing.xxl),

            // ── Continue Button ──
            Opacity(
              opacity: contentSlide,
              child: Transform.translate(
                offset: Offset(0, 100 * (1 - contentSlide)),
                child: BounceIn(
                  delay: const Duration(milliseconds: 1000),
                  child: PulsingGlow(
                    color: AppColors.primaryGradientEnd,
                    borderRadius: AppRadius.pillRadius,
                    child: GameButton(
                      label: nextChapter != null
                          ? 'Start Chapter ${nextChapter.id}'
                          : 'Back to Home',
                      icon: nextChapter != null
                          ? Icons.double_arrow_rounded
                          : Icons.home_rounded,
                      width: double.infinity,
                      height: 68,
                      onTap: () {
                        if (nextChapter != null) {
                          // Navigate to the first level of the next chapter
                          context.goNamed(
                            RouteNames.puzzle,
                            pathParameters: {
                              'levelId': '${nextChapter.startLevelId}',
                            },
                          );
                        } else {
                          context.goNamed(RouteNames.home);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Bonus: View Map ──
            Opacity(
              opacity: contentSlide,
              child: TextButton.icon(
                onPressed: () => context.goNamed(RouteNames.levels),
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('View Journey Map'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
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

/// ────────────────────────────────────────────────────────────────────
/// Chapter Stars Display
/// ────────────────────────────────────────────────────────────────────
class _ChapterStars extends StatelessWidget {
  const _ChapterStars({required this.totalStars, required this.maxStars});

  final int totalStars;
  final int maxStars;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          'Stars Earned',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.star_rounded,
              color: AppColors.accent,
              size: 40,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$totalStars',
              style: textTheme.displaySmall?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              ' / $maxStars',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// All Chapters Complete
/// ────────────────────────────────────────────────────────────────────
class _AllChaptersComplete extends StatelessWidget {
  const _AllChaptersComplete({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return BounceIn(
      delay: const Duration(milliseconds: 800),
      child: GameCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.success, Color(0xFF16A34A)],
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(
              Icons.celebration_rounded,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'All Chapters Complete!',
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'You\'ve conquered every puzzle. Legendary!',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Fallback (no result)
/// ────────────────────────────────────────────────────────────────────
class _NoResultContent extends StatelessWidget {
  const _NoResultContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No chapter result to show.',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.textDark),
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
