import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../services/audio_service.dart';
import '../../../../core/design_system/app_gradients.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_shadows.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/color_utils.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/game_progress_manager.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/banner_ad_widget.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/outlined_text.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../../../shared/widgets/pulsing_glow.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../../daily_reward/domain/daily_reward_service.dart';
import '../../../daily_reward/presentation/widgets/daily_rewards_modal.dart';
import '../../../levels/data/datasources/levels_local_datasource.dart';
import '../../../levels/data/repositories/levels_repository_impl.dart';
import '../../../levels/domain/entities/level.dart';
import '../../../levels/domain/entities/section.dart';
import '../../../levels/domain/services/chapter_catalog.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../../levels/presentation/widgets/level_difficulty_style.dart';
import '../../../levels/presentation/widgets/section_mosaic.dart';

/// Premium Home Hub: a collection-centric landing page. The player isn't
/// shown a level list or long stats — just the artwork they're currently
/// piecing together (one section = one collection) and a single "keep
/// playing" action. Everything else (Daily Challenge, Shop, Achievements,
/// the full Journey Map) is a small secondary icon, never the focus.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GameProgress? _progress;
  List<Level> _levels = [];
  DateTime? _lastBackPressed; // for double-back-to-exit

  @override
  void initState() {
    super.initState();
    _loadProgress();
    AudioService().startBgm();
    
    // Check daily reward after a short delay so page transitions finish
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyReward();
    });
  }

  Future<void> _checkDailyReward() async {
    final service = DailyRewardService();
    if (service.isRewardAvailable()) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      
      DailyRewardsModal.show(context);
    }
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

  /// Home is the app's hub (a single-entry go route), so system back must
  /// never exit silently: a double-back confirms exit, otherwise we nudge.
  void _handleSystemBack() {
    final now = DateTime.now();
    final last = _lastBackPressed;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      _lastBackPressed = null;
      SystemNavigator.pop();
      return;
    }
    _lastBackPressed = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Press back again to exit'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.pillRadius,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: Scaffold(
        body: GameBackground(
          showFloatingPieces: true,
          showClouds: true,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  // ── Top Bar: Profile — Settings — Coins — Hints ──
                  _HomeTopBar(),

                  // ── The Collection: current section's artwork ──
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: progress != null && progress.currentLevelId != null
                            ? _CollectionFrame(
                                levelId: progress.currentLevelId!,
                                levels: _levels,
                              )
                            : progress != null &&
                                  progress.completedCount == progress.totalCount
                              ? const _AllCompleteBanner()
                              : const _LoadingShimmer(),
                      ),
                    ),
                  ),

                  // ── Secondary features: small, never in the way ──
                  _QuickActionsRow(),

                  const SizedBox(height: AppSpacing.md),
                  const BannerAdWidget(),
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
/// Top Bar: Profile, Settings, Coins, Hints
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

        // ── Row 2: Coins — Logo — Hints ──
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
            const StatChip(
              icon: Icons.lightbulb_rounded,
              value: '5',
              iconColor: AppColors.success,
            ),
          ],
        ),
      ],
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// The Collection: an artwork frame showing every piece (level) of the
/// player's current section — collected pieces reveal their photo,
/// locked ones stay silhouettes — plus the single "keep playing" button.
/// ────────────────────────────────────────────────────────────────────
class _CollectionFrame extends StatelessWidget {
  const _CollectionFrame({required this.levelId, required this.levels});

  final int levelId;
  final List<Level> levels;

  @override
  Widget build(BuildContext context) {
    final chapter = ChapterCatalog.chapterForLevel(levelId);
    final section = ChapterCatalog.sectionForLevel(levelId);
    final sectionLevels = levels.sublist(
      section.startLevelId - 1,
      section.endLevelId,
    );
    final completedInSection = sectionLevels.where((l) => l.isCompleted).length;
    final fraction = section.levelCount == 0
        ? 0.0
        : completedInSection / section.levelCount;

    return BounceIn(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── Artwork frame: mosaic + collected-pieces progress ──
          Padding(
            padding: const EdgeInsets.only(top: 22, bottom: 30),
            child: SizedBox(
              width: 300,
              child: GameCard(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                borderRadius: AppRadius.xlRadius,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SectionMosaic(
                      levels: sectionLevels,
                      accentColor: chapter.difficulty.color,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AnimatedPiecesProgress(
                      fraction: fraction,
                      color: chapter.difficulty.color,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$completedInSection / ${section.levelCount} Pieces Collected',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Section banner, overlapping the frame's top edge ──
          Positioned(
            top: 0,
            child: _SectionBanner(section: section, color: chapter.difficulty.color),
          ),

          // ── "Level N" button, overlapping the frame's bottom edge ──
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
/// collection frame's top edge, matching a "ribbon tab" look.
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

/// A smoothly-filling progress bar — animates from empty to [fraction] on
/// first build, rather than snapping straight to its value, so collecting
/// a new piece always reads as motion rather than a static counter.
class _AnimatedPiecesProgress extends StatelessWidget {
  const _AnimatedPiecesProgress({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 10,
      child: ClipRRect(
        borderRadius: AppRadius.pillRadius,
        child: Stack(
          children: [
            const ColoredBox(color: AppColors.border),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => FractionallySizedBox(
                widthFactor: value,
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.lighten(0.12)],
                    ),
                  ),
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
/// Quick Actions: Daily Challenge, Shop, Achievements, Journey — small
/// floating icon buttons so secondary features never compete with the
/// collection for attention.
/// ────────────────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickAction(
          icon: Icons.card_giftcard_rounded,
          label: 'Daily Challenge',
          color: AppColors.accent,
          onTap: () => context.goNamed(RouteNames.dailyPuzzle),
        ),
        _QuickAction(
          icon: Icons.storefront_rounded,
          label: 'Shop',
          color: AppColors.secondary,
          onTap: () => context.goNamed(RouteNames.shop),
        ),
        _QuickAction(
          icon: Icons.photo_library_rounded,
          label: 'Gallery',
          color: AppColors.success,
          onTap: () => context.goNamed(RouteNames.gallery),
        ),
        _QuickAction(
          icon: Icons.emoji_events_rounded,
          label: 'Achievements',
          color: AppColors.premiumGradientEnd,
          onTap: () => context.goNamed(RouteNames.achievements),
        ),
        _QuickAction(
          icon: Icons.map_rounded,
          label: 'Journey',
          color: AppColors.primary,
          onTap: () => context.goNamed(RouteNames.levels),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
    return PressScale(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outline, width: 2.5),
                boxShadow: [
                  const BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                  ...AppShadows.bevel(AppColors.card, depth: 3),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontSize: 10),
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
  const _AllCompleteBanner();

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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration_rounded,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Collection Complete!',
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'More artwork coming soon...',
              style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
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

