import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../services/audio_service.dart';
import '../../../../core/design_system/app_gradients.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_shadows.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/game_progress_manager.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/outlined_text.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../../../shared/widgets/pulsing_glow.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../../levels/data/datasources/levels_local_datasource.dart';
import '../../../levels/data/repositories/levels_repository_impl.dart';
import '../../../levels/domain/entities/level.dart';
import '../../../levels/domain/entities/section.dart';
import '../../../levels/domain/services/chapter_catalog.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../../levels/presentation/widgets/level_difficulty_style.dart';
import '../../../puzzle/domain/puzzle_board_size.dart';
import '../../../puzzle/domain/puzzle_image.dart';

/// Premium Home Hub: the player's landing page showing current progress,
/// daily challenge, a large Continue button, and quick-access bottom
/// actions — designed to feel alive like Royal Match / Candy Crush.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GameProgress? _progress;
  List<Level> _levels = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
    AudioService().startBgm();
  }

  @override
  void dispose() {
    AudioService().stopBgm();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final service = LevelService(
      LevelsRepositoryImpl(HiveLevelsLocalDataSource()),
    );
    final levels = await service.loadLevels();
    if (!mounted) return;
    setState(() {
      _levels = levels;
      _progress = GameProgressManager.computeFrom(levels);
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;

    return Scaffold(
      body: GameBackground(
        showFloatingPieces: true,
        showClouds: true,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl * 2,
            ),
            child: Column(
              children: [
                // ── Top Bar ──
                _HomeTopBar(),
                const SizedBox(height: AppSpacing.md),

                // ── Hero: Current Chapter/Section/Level ──
                if (progress != null && progress.currentLevelId != null) ...[
                  _CurrentLevelHero(
                    levelId: progress.currentLevelId!,
                    levels: _levels,
                  ),
                ] else if (progress != null && progress.completedCount == progress.totalCount) ...[
                  _AllCompleteBanner(),
                ] else ...[
                  const _LoadingShimmer(),
                ],

                const SizedBox(height: AppSpacing.lg),

                // ── Daily Challenge Card ──
                BounceIn(
                  delay: const Duration(milliseconds: 150),
                  child: _DailyChallengeCard(),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Streak + Events Row ──
                Row(
                  children: [
                    Expanded(child: _StreakCard()),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _EventCard()),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Season Pass ──
                BounceIn(
                  delay: const Duration(milliseconds: 450),
                  child: _SeasonPassCard(),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Bottom Action Row ──
                _BottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Top Bar: Avatar, Coins, Hints, Settings
/// ────────────────────────────────────────────────────────────────────
class _HomeTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Row 1: Avatar — Settings ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PressScale(
              onTap: () {},
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.premiumButton,
                  border: Border.all(color: AppColors.outline, width: 2.5),
                  boxShadow: [
                    const BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                    ...AppShadows.bevel(AppColors.premiumGradientEnd, depth: 3),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            CircleIconButton(
              icon: Icons.settings_rounded,
              onTap: () => context.goNamed(RouteNames.settings),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Row 2: Coins — Logo — Daily ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BlocBuilder<WalletCubit, int>(
              builder: (context, coins) => StatChip(
                icon: Icons.monetization_on_rounded,
                value: formatThousands(coins),
                iconColor: AppColors.accent,
              ),
            ),
            const Expanded(
              child: Center(child: AppLogo(size: 44, wordmark: true)),
            ),
            PressScale(
              onTap: () => context.goNamed(RouteNames.dailyPuzzle),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(color: AppColors.outline, width: 2.5),
                  boxShadow: [
                    const BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                    ...AppShadows.bevel(AppColors.card, depth: 3),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.event_rounded,
                      color: AppColors.danger,
                      size: 16,
                    ),
                    Text(
                      '${DateTime.now().day}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
/// Hero: Current Level Card with Continue Button
/// ────────────────────────────────────────────────────────────────────
class _CurrentLevelHero extends StatelessWidget {
  const _CurrentLevelHero({required this.levelId, required this.levels});

  final int levelId;
  final List<Level> levels;

  @override
  Widget build(BuildContext context) {
    final chapter = ChapterCatalog.chapterForLevel(levelId);
    final section = ChapterCatalog.sectionForLevel(levelId);
    final completedInSection = levels
        .where((l) => section.containsLevel(l.id) && l.isCompleted)
        .length;
    final imageUrl = puzzleImageUrlFor(levelId);

    return BounceIn(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── Main card: puzzle preview + section progress ──
          Padding(
            padding: const EdgeInsets.only(top: 22, bottom: 30),
            child: GameCard(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.md,
              ),
              borderRadius: AppRadius.xlRadius,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.lgRadius,
                    child: AspectRatio(
                      aspectRatio: boardDimensionsForLevel(levelId).aspectRatio,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: chapter.difficulty.color,
                            width: 3,
                          ),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                              ? child
                              : const ColoredBox(color: AppColors.border),
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(
                                color: AppColors.border,
                                child: Icon(
                                  Icons.image_not_supported_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$completedInSection / ${section.levelCount}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: chapter.difficulty.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Section banner, overlapping the card's top edge ──
          Positioned(
            top: 0,
            child: _SectionBanner(section: section, color: chapter.difficulty.color),
          ),

          // ── "Level N" button, overlapping the card's bottom edge ──
          Positioned(
            bottom: 0,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: PulsingGlow(
              color: chapter.difficulty.color,
              child: GameButton(
                label: 'Level $levelId',
                icon: Icons.play_arrow_rounded,
                width: double.infinity,
                height: 60,
                onTap: () => context.goNamed(
                  RouteNames.puzzle,
                  pathParameters: {'levelId': '$levelId'},
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chunky pill banner naming the current section — sits overlapping the
/// hero card's top edge, matching a "ribbon tab" look.
class _SectionBanner extends StatelessWidget {
  const _SectionBanner({required this.section, required this.color});

  final Section section;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: AppColors.outline, width: 3),
        boxShadow: AppShadows.bevel(color, depth: 4),
      ),
      child: OutlinedText(
        'Section ${section.index}',
        outlineWidth: 2,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Daily Challenge Card
/// ────────────────────────────────────────────────────────────────────
class _DailyChallengeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PressScale(
      onTap: () => context.goNamed(RouteNames.dailyPuzzle),
      child: GameCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: AppRadius.mdRadius,
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: AppColors.accent,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Daily Challenge',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          'NEW',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'A fresh puzzle awaits you today',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Streak Card
/// ────────────────────────────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PressScale(
      onTap: () {},
      child: GameCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.danger,
                  size: 22,
                ),
                const SizedBox(width: 4),
                Text(
                  '3',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Day Streak',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Events Card
/// ────────────────────────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PressScale(
      onTap: () {},
      child: GameCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            const Icon(
              Icons.celebration_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              'No Events',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Season Pass Card
/// ────────────────────────────────────────────────────────────────────
class _SeasonPassCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PressScale(
      onTap: () {},
      child: GameCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.premiumGradientStart,
            Color(0xFFFF8A65),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Season Pass',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Coming Soon',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: AppRadius.pillRadius,
              ),
              child: Text(
                'SOON',
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Bottom Actions: Shop, Achievements, Levels
/// ────────────────────────────────────────────────────────────────────
class _BottomActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _NavCard(
          icon: Icons.storefront_rounded,
          label: 'Shop',
          color: AppColors.secondary,
          onTap: () => context.goNamed(RouteNames.shop),
        )),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _NavCard(
          icon: Icons.emoji_events_rounded,
          label: 'Achievements',
          color: AppColors.accent,
          onTap: () => context.goNamed(RouteNames.achievements),
        )),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _NavCard(
          icon: Icons.map_rounded,
          label: 'Journey',
          color: AppColors.primary,
          onTap: () => context.goNamed(RouteNames.levels),
        )),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PressScale(
      onTap: onTap,
      child: GameCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        borderRadius: AppRadius.lgRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// All Complete Banner
/// ────────────────────────────────────────────────────────────────────
class _AllCompleteBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BounceIn(
      child: GameCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.success, Color(0xFF16A34A)],
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const Icon(
              Icons.celebration_rounded,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'All Levels Complete!',
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'More levels coming soon...',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Loading Shimmer
/// ────────────────────────────────────────────────────────────────────
class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return GameCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
