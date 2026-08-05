import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../services/audio_service.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/utils/duration_format.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/coin_reward_chip.dart';
import '../../../../shared/widgets/confetti_burst.dart';
import '../../../../shared/widgets/fireworks_burst.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/pulsing_glow.dart';
import '../../../../shared/widgets/sparkle_particles.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../../levels/data/datasources/levels_local_datasource.dart';
import '../../../levels/data/repositories/levels_repository_impl.dart';
import '../../../levels/domain/entities/chapter.dart';
import '../../../levels/domain/entities/chapter_complete_result.dart';
import '../../../levels/domain/entities/section.dart';
import '../../../levels/domain/entities/section_complete_result.dart';
import '../../../levels/domain/services/chapter_catalog.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../../levels/presentation/widgets/level_difficulty_style.dart';
import '../../../puzzle/domain/puzzle_image.dart';
import '../../domain/entities/victory_result.dart';

/// Premium Victory screen: the "Puzzle Complete!" moment.
///
/// Upon reaching this screen, the completed puzzle image appears with a
/// smooth reveal animation — pieces snap into place, borders fade, the
/// seamless photo glows up. Confetti, fireworks, sparkles, and a camera
/// flash celebrate the moment. Stars animate in one by one, then stats
/// and action buttons slide up.
///
/// If the solved level was the final level of its chapter, a banner
/// announces the chapter completion as well.
class VictoryPage extends StatefulWidget {
  const VictoryPage({super.key, this.result});

  final VictoryResult? result;

  @override
  State<VictoryPage> createState() => _VictoryPageState();
}

class _VictoryPageState extends State<VictoryPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final ConfettiController _confettiController;
  late final Animation<double> _imageReveal;
  late final Animation<double> _imageGlow;
  late final Animation<double> _contentSlide;
  late final Animation<double> _flashOpacity;

  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _imageReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
    );

    _imageGlow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );

    _contentSlide = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.85, curve: Curves.easeOutBack),
    );

    _flashOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.5, curve: Curves.easeOut),
    );

    // Start the sequence after a brief pause
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _controller.forward();
        setState(() => _showCelebration = true);
        AudioService().playVictory();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration get _celebrationDelay => const Duration(milliseconds: 1600);

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Scaffold(
      body: GameBackground(
        showFloatingPieces: false,
        child: Stack(
          children: [
            // Fireworks & Confetti (after brief delay)
            if (result != null && _showCelebration)
              const Positioned.fill(child: FireworksBurst()),
            if (result != null && _showCelebration)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    AppColors.primary,
                    AppColors.secondary,
                    AppColors.accent,
                    AppColors.success,
                    AppColors.danger,
                  ],
                ),
              ),
            if (result != null && _showCelebration)
              const Positioned.fill(
                child: IgnorePointer(child: SparkleParticles()),
              ),

            // Camera Flash overlay
            if (result != null)
              FadeTransition(
                opacity: _flashOpacity,
                child: const IgnorePointer(
                  child: ColoredBox(color: Colors.white),
                ),
              ),

            // Main content
            SafeArea(
              child: result == null
                  ? const _NoResultContent()
                  : AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return _VictoryContent(
                          result: result,
                          imageReveal: _imageReveal.value,
                          imageGlow: _imageGlow.value,
                          contentSlide: _contentSlide.value,
                          celebrationDelay: _celebrationDelay,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VictoryContent extends StatelessWidget {
  const _VictoryContent({
    required this.result,
    required this.imageReveal,
    required this.imageGlow,
    required this.contentSlide,
    required this.celebrationDelay,
  });

  final VictoryResult result;
  final double imageReveal;
  final double imageGlow;
  final double contentSlide;
  final Duration celebrationDelay;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final imageUrl = puzzleImageUrlFor(result.level.id);
    final chapter = ChapterCatalog.chapterForLevel(result.level.id);
    final section = ChapterCatalog.sectionForLevel(result.level.id);
    final isChapterComplete = chapter.endLevelId == result.level.id;
    final isSectionComplete = !isChapterComplete && section.endLevelId == result.level.id;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),

            // ── Completed Image with Reveal ──
            _AnimatedPuzzleImage(
              imageUrl: imageUrl,
              reveal: imageReveal,
              glow: imageGlow,
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── "Puzzle Complete!" Header ──
            Opacity(
              opacity: contentSlide,
              child: Transform.translate(
                offset: Offset(0, 40 * (1 - contentSlide)),
                child: Column(
                  children: [
                    Text(
                      'Puzzle Complete!',
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
                        color: result.level.difficulty.color.withValues(alpha: 0.12),
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(
                          color: result.level.difficulty.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${result.level.title} · ${result.level.difficulty.label}',
                        style: textTheme.bodySmall?.copyWith(
                          color: result.level.difficulty.color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    // ── Chapter/Section Complete Banner ──
                    if (isChapterComplete) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _ChapterCompleteBanner(chapter: chapter),
                    ] else if (isSectionComplete) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _SectionCompleteBanner(section: section),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Stars ──
            Opacity(
              opacity: contentSlide,
              child: Transform.translate(
                offset: Offset(0, 40 * (1 - contentSlide)),
                child: _StarsRow(stars: result.stars),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Stats Grid ──
            Opacity(
              opacity: contentSlide,
              child: Transform.translate(
                offset: Offset(0, 60 * (1 - contentSlide)),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    StatChip(
                      icon: Icons.timer_rounded,
                      value: formatMinutesSeconds(result.timeSeconds),
                      iconColor: AppColors.secondary,
                    ),
                    StatChip(
                      icon: Icons.touch_app_rounded,
                      value: '${result.moves}',
                      iconColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Coin Reward Chip ──
            Opacity(
              opacity: contentSlide,
              child: Transform.translate(
                offset: Offset(0, 80 * (1 - contentSlide)),
                child: BounceIn(
                  delay: celebrationDelay,
                  child: CoinRewardChip(coins: result.coinsEarned),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Action Buttons ──
            Opacity(
              opacity: contentSlide,
              child: Transform.translate(
                offset: Offset(0, 100 * (1 - contentSlide)),
                child: _ActionButtons(
                  result: result,
                  nextLevelId: result.nextLevelId,
                  celebrationDelay: celebrationDelay,
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
/// Animated Puzzle Image
/// ────────────────────────────────────────────────────────────────────
class _AnimatedPuzzleImage extends StatelessWidget {
  const _AnimatedPuzzleImage({
    required this.imageUrl,
    required this.reveal,
    required this.glow,
  });

  final String imageUrl;
  final double reveal;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = (screenWidth * 0.65).clamp(160.0, 280.0);
    final imageHeight = imageWidth * 1.15;

    return Center(
      child: SizedBox(
        width: imageWidth * reveal,
        height: imageHeight * reveal,
        child: Transform.scale(
          scale: 1.0 + (1.0 - reveal) * 0.3,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.xlRadius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.premiumGradientStart.withValues(
                    alpha: glow * 0.5,
                  ),
                  blurRadius: 30 + glow * 30,
                  spreadRadius: glow * 8,
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: glow * 0.3),
                  blurRadius: 20 + glow * 20,
                  spreadRadius: glow * 4,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: ClipRRect(
              borderRadius: AppRadius.xlRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The seamless image
                  AppImage(
                    imagePath: imageUrl,
                    fit: BoxFit.cover,
                  ),
                  // Grid lines that fade away as reveal progresses
                  // to simulate borders dissolving
                  ...List.generate(3, (index) {
                    final pos = (index + 1) / 4;
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: imageHeight * reveal * pos - 1,
                      child: Opacity(
                        opacity: (1.0 - reveal).clamp(0.0, 1.0),
                        child: Container(
                          height: 2,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }),
                  ...List.generate(2, (index) {
                    final pos = (index + 1) / 3;
                    return Positioned(
                      top: 0,
                      bottom: 0,
                      left: imageWidth * reveal * pos - 1,
                      child: Opacity(
                        opacity: (1.0 - reveal).clamp(0.0, 1.0),
                        child: Container(
                          width: 2,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Chapter Complete Banner
/// ────────────────────────────────────────────────────────────────────
class _ChapterCompleteBanner extends StatelessWidget {
  const _ChapterCompleteBanner({required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.premiumGradientStart,
            AppColors.premiumGradientEnd,
          ],
        ),
        borderRadius: AppRadius.pillRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.military_tech_rounded, color: Colors.white, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Chapter ${chapter.id} Complete!',
            style: textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Section Complete Banner
/// ────────────────────────────────────────────────────────────────────
class _SectionCompleteBanner extends StatelessWidget {
  const _SectionCompleteBanner({required this.section});

  final Section section;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: AppRadius.pillRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.collections_rounded, color: Colors.white, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Section ${section.index} Complete!',
            style: textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Stars Row with Staggered Animation
/// ────────────────────────────────────────────────────────────────────
class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: BounceIn(
              delay: Duration(milliseconds: 600 + i * 250),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < stars
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: i < stars ? AppColors.accent : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Icon(
                  i < stars
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 36,
                  color: i < stars ? AppColors.accent : AppColors.border,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Action Buttons
/// ────────────────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.result,
    required this.nextLevelId,
    required this.celebrationDelay,
  });

  final VictoryResult result;
  final int? nextLevelId;
  final Duration celebrationDelay;

  @override
  Widget build(BuildContext context) {
    final chapter = ChapterCatalog.chapterForLevel(result.level.id);
    final section = ChapterCatalog.sectionForLevel(result.level.id);
    final isChapterComplete = chapter.endLevelId == result.level.id;
    // A chapter's last level is always its last section's last level too
    // — when both are true, Chapter Complete's bigger celebration wins.
    final isSectionComplete = !isChapterComplete && section.endLevelId == result.level.id;

    return Column(
      children: [
        // Continue / Next Level
        if (nextLevelId != null) ...[
          BounceIn(
            delay: celebrationDelay + const Duration(milliseconds: 200),
            child: PulsingGlow(
              color: AppColors.primaryGradientEnd,
              borderRadius: AppRadius.pillRadius,
              child: GameButton(
                label: isChapterComplete
                    ? 'Continue to Chapter ${chapter.id + 1}'
                    : isSectionComplete
                    ? 'Continue to Section ${section.index + 1}'
                    : 'Next Level',
                icon: Icons.double_arrow_rounded,
                width: double.infinity,
                height: 68,
                onTap: () async {
                  if (isChapterComplete) {
                    final nextChapter = chapter.id < ChapterCatalog.chapters.length
                        ? ChapterCatalog.chapters[chapter.id]
                        : null;
                    // Sum stars across every level in the chapter (not
                    // just this one) for an accurate chapter total.
                    final levelService = LevelService(
                      LevelsRepositoryImpl(HiveLevelsLocalDataSource()),
                    );
                    final levels = await levelService.loadLevels();
                    final totalStars = levels
                        .where((level) => chapter.containsLevel(level.id))
                        .fold(0, (sum, level) => sum + level.stars);
                    if (!context.mounted) return;
                    context.goNamed(
                      RouteNames.chapterComplete,
                      extra: ChapterCompleteResult(
                        chapter: chapter,
                        totalStars: totalStars,
                        nextChapter: nextChapter,
                      ),
                    );
                  } else if (isSectionComplete) {
                    // Sum stars across every level in the section (not
                    // just this one) for an accurate section total.
                    final levelService = LevelService(
                      LevelsRepositoryImpl(HiveLevelsLocalDataSource()),
                    );
                    final levels = await levelService.loadLevels();
                    final totalStars = levels
                        .where((level) => section.containsLevel(level.id))
                        .fold(0, (sum, level) => sum + level.stars);
                    if (!context.mounted) return;
                    context.goNamed(
                      RouteNames.sectionComplete,
                      extra: SectionCompleteResult(
                        chapter: chapter,
                        section: section,
                        totalStars: totalStars,
                        nextLevelId: nextLevelId,
                      ),
                    );
                  } else {
                    context.goNamed(
                      RouteNames.puzzle,
                      pathParameters: {'levelId': '$nextLevelId'},
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ] else ...[
          BounceIn(
            delay: celebrationDelay + const Duration(milliseconds: 200),
            child: GameButton(
              label: 'All Levels Complete!',
              icon: Icons.celebration_rounded,
              width: double.infinity,
              height: 68,
              variant: GameButtonVariant.premium,
              onTap: () {},
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Replay & Home Row
        Row(
          children: [
            Expanded(
              child: BounceIn(
                delay: celebrationDelay + const Duration(milliseconds: 350),
                child: GameButton(
                  label: 'Replay',
                  icon: Icons.replay_rounded,
                  height: 54,
                  variant: GameButtonVariant.secondary,
                  onTap: () => context.goNamed(
                    RouteNames.puzzle,
                    pathParameters: {'levelId': '${result.level.id}'},
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: BounceIn(
                delay: celebrationDelay + const Duration(milliseconds: 450),
                child: OutlinedButton.icon(
                  onPressed: () => context.goNamed(RouteNames.home),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
            'No level result to show.',
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


