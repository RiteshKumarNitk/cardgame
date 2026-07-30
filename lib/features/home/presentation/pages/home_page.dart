import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_animations.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_gradients.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/game_progress_manager.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/floating_bob.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../../../shared/widgets/pulsing_glow.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../../levels/data/datasources/levels_local_datasource.dart';
import '../../../levels/data/repositories/levels_repository_impl.dart';
import '../../../levels/domain/entities/level.dart';
import '../../../levels/domain/services/chapter_catalog.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../../levels/presentation/widgets/level_difficulty_style.dart';

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
    final textTheme = Theme.of(context).textTheme;
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
                    progress: progress,
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
    return Row(
      children: [
        // Avatar circle
        PressScale(
          onTap: () {},
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.premiumButton,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Player',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Level 1',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        BlocBuilder<WalletCubit, int>(
          builder: (context, coins) => StatChip(
            icon: Icons.monetization_on_rounded,
            value: formatThousands(coins),
            iconColor: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatChip(
          icon: Icons.lightbulb_rounded,
          value: '5',
          iconColor: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.sm),
        CircleIconButton(
          icon: Icons.settings_rounded,
          onTap: () => context.goNamed(RouteNames.settings),
        ),
      ],
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Hero: Current Level Card with Continue Button
/// ────────────────────────────────────────────────────────────────────
class _CurrentLevelHero extends StatelessWidget {
  const _CurrentLevelHero({
    required this.levelId,
    required this.levels,
    required this.progress,
  });

  final int levelId;
  final List<Level> levels;
  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chapter = ChapterCatalog.chapterForLevel(levelId);
    final section = ChapterCatalog.sectionForLevel(levelId);
    final level = levels.firstWhere((l) => l.id == levelId);

    return BounceIn(
      child: GameCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        borderRadius: AppRadius.xlRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            chapter.difficulty.color,
            chapter.difficulty.color.withValues(alpha: 0.85),
          ],
        ),
        child: Column(
          children: [
            // Chapter & Section
            Text(
              'CHAPTER ${chapter.id} — ${chapter.name.toUpperCase()}',
              style: textTheme.labelMedium?.copyWith(
                color: Colors.white70,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: AppRadius.pillRadius,
              ),
              child: Text(
                'Section ${section.index} · Level $levelId',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Progress bar
            ClipRRect(
              borderRadius: AppRadius.pillRadius,
              child: LinearProgressIndicator(
                value: progress.percentComplete,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${progress.completedCount} / ${progress.totalCount} levels',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Continue Button
            PulsingGlow(
              color: Colors.white,
              borderRadius: AppRadius.pillRadius,
              minOpacity: 0.3,
              maxOpacity: 0.6,
              blurRadius: 24,
              child: GestureDetector(
                onTap: () => context.goNamed(
                  RouteNames.puzzle,
                  pathParameters: {'levelId': '$levelId'},
                ),
                child: Container(
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.pillRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: chapter.difficulty.color,
                        size: 32,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Continue',
                        style: textTheme.titleLarge?.copyWith(
                          color: chapter.difficulty.color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Secondary: View Map
            TextButton.icon(
              onPressed: () => context.goNamed(RouteNames.levels),
              icon: const Icon(Icons.map_rounded, size: 18, color: Colors.white70),
              label: Text(
                'View Journey Map',
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ),
          ],
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
    final textTheme = Theme.of(context).textTheme;

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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
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
