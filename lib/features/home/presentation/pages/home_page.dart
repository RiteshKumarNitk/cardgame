import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_shadows.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/color_utils.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/game_progress_manager.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/utils/context_read_or_null.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/banner_ad_widget.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../../../shared/widgets/pulsing_glow.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../../cosmetics/domain/entities/cosmetic_items.dart';
import '../../../cosmetics/domain/services/cosmetics_catalog.dart';
import '../../../cosmetics/presentation/bloc/cosmetics_cubit.dart';
import '../../../cosmetics/presentation/widgets/avatar_badge.dart';
import '../../../daily_reward/domain/daily_reward_service.dart';
import '../../../daily_reward/presentation/widgets/daily_rewards_modal.dart';
import '../../../levels/data/datasources/levels_local_datasource.dart';
import '../../../levels/data/repositories/levels_repository_impl.dart';
import '../../../levels/domain/entities/level.dart';
import '../../../levels/domain/services/chapter_catalog.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../../levels/presentation/widgets/level_difficulty_style.dart';
import '../../../levels/presentation/widgets/section_mosaic.dart';

/// Premium Home Hub — "Home & Artwork Journey" (Warm Tactile Serenity).
///
/// A collection-centric landing page: the artwork the player is currently
/// piecing together (one section = one collection), a single tactile
/// "keep playing" action, a compact journey preview strip, and small
/// secondary shortcuts. Everything steps back so the artwork stays the
/// focus.
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
          shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    final hasCurrent = progress != null && progress.currentLevelId != null;
    final allComplete = progress != null &&
        progress.completedCount == progress.totalCount;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: Scaffold(
        body: GameBackground(
          showFloatingPieces: true,
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: _HomeHeader(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    child: hasCurrent
                        ? _HomeBody(
                            levelId: progress.currentLevelId!,
                            levels: _levels,
                          )
                        : allComplete
                        ? const _AllCompleteBanner()
                        : const _LoadingShimmer(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: BannerAdWidget(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Header: profile group (avatar + name + level badge) · coins · settings
/// ────────────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cosmetics = context.watchOrNull<CosmeticsCubit>()?.state;

    return Row(
      children: [
        PressScale(
          onTap: () => context.goNamed(RouteNames.profile),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarBadge(
                avatar: cosmetics == null
                    ? defaultAvatar
                    : CosmeticsCatalog.avatarById(cosmetics.equippedAvatar),
                onTap: null,
              ),
              const SizedBox(width: AppSpacing.xs),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Curator',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'SuitClash Member',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textMeta,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        BlocBuilder<WalletCubit, int>(
          builder: (context, coins) => StatChip(
            icon: Icons.monetization_on_rounded,
            value: formatThousands(coins),
            iconColor: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        CircleIconButton(
          icon: Icons.settings_rounded,
          iconColor: AppColors.textSecondary,
          onTap: () => context.goNamed(RouteNames.settings),
        ),
      ],
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Body: brand row · artwork hero · Continue CTA · journey strip ·
/// Daily Discovery · secondary shortcuts.
/// ────────────────────────────────────────────────────────────────────
class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.levelId, required this.levels});

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
    final completedInSection =
        sectionLevels.where((l) => l.isCompleted).length;
    final fraction = section.levelCount == 0
        ? 0.0
        : completedInSection / section.levelCount;
    final accent = chapter.difficulty.color;
    final currentStars =
        levelId - 1 < levels.length ? levels[levelId - 1].stars : 0;

    return BounceIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Brand row ──
          Row(
            children: [
              const AppLogo(size: 26),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SuitClash',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppColors.primary),
                    ),
                    Text(
                      '${chapter.name} • Section ${section.index}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMeta,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Artwork hero ──
          _ArtworkHero(
            sectionLevels: sectionLevels,
            sectionIndex: section.index,
            accent: accent,
            fraction: fraction,
            collected: completedInSection,
            total: section.levelCount,
            stars: currentStars,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Continue CTA ──
          PulsingGlow(
            color: AppColors.primaryContainer,
            minOpacity: 0.14,
            maxOpacity: 0.42,
            child: GameButton(
              label: 'Continue Puzzle • Level $levelId',
              icon: Icons.play_arrow_rounded,
              width: double.infinity,
              height: 58,
              onTap: () => context.goNamed(
                RouteNames.puzzle,
                pathParameters: {'levelId': '$levelId'},
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Journey preview strip ──
          _JourneyStrip(levels: levels, currentLevelId: levelId, accent: accent),
          const SizedBox(height: AppSpacing.md),

          // ── Daily Discovery ──
          const _DailyDiscovery(),
          const SizedBox(height: AppSpacing.md),

          // ── Secondary shortcuts ──
          const _ShortcutRow(),
        ],
      ),
    );
  }
}

/// The framed collection artwork with a progress scrim, a "section
/// assembled" status chip, and a pieces/stars footer row.
class _ArtworkHero extends StatelessWidget {
  const _ArtworkHero({
    required this.sectionLevels,
    required this.sectionIndex,
    required this.accent,
    required this.fraction,
    required this.collected,
    required this.total,
    required this.stars,
  });

  final List<Level> sectionLevels;
  final int sectionIndex;
  final Color accent;
  final double fraction;
  final int collected;
  final int total;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Column(
        children: [
          // Framed mosaic + scrim + status chip
          ClipRRect(
            borderRadius: AppRadius.lgRadius,
            child: Stack(
              children: [
                Container(
                  color: AppColors.cardWell,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: SectionMosaic(
                    levels: sectionLevels,
                    accentColor: accent,
                  ),
                ),
                // status chip
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.92),
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_open_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'SECTION $sectionIndex',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // bottom progress scrim
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.textDark.withValues(alpha: 0.82),
                          AppColors.textDark.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '$collected / $total Pieces',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.honey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _AnimatedPiecesProgress(
                            fraction: fraction,
                            color: AppColors.primaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.xxs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$collected of $total pieces collected',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMeta,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: AppColors.honey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$stars/3 Stars',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.honeyText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A smoothly-filling progress bar — animates from empty to [fraction] on
/// first build so collecting a new piece always reads as motion.
class _AnimatedPiecesProgress extends StatelessWidget {
  const _AnimatedPiecesProgress({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 8,
      child: ClipRRect(
        borderRadius: AppRadius.pillRadius,
        child: Stack(
          children: [
            ColoredBox(color: Colors.white.withValues(alpha: 0.25)),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => FractionallySizedBox(
                widthFactor: value == 0 ? 0.001 : value,
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

/// A compact horizontal preview of the winding level journey around the
/// current level. Tapping anywhere opens the full Journey Map.
class _JourneyStrip extends StatelessWidget {
  const _JourneyStrip({
    required this.levels,
    required this.currentLevelId,
    required this.accent,
  });

  final List<Level> levels;
  final int currentLevelId;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (levels.length < 2) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    // A window of up to 6 levels centred on the current one.
    final start = (currentLevelId - 3).clamp(1, levels.length);
    final end = (start + 5).clamp(start, levels.length);
    final window = levels.sublist(start - 1, end);

    return PressScale(
      onTap: () => context.goNamed(RouteNames.levels),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppShadows.pill,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Level Journey',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  'View Map',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned(
                    left: 12,
                    right: 12,
                    child: _DashedLine(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final level in window)
                        _StripNode(
                          level: level,
                          accent: accent,
                          isCurrent: level.id == currentLevelId,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StripNode extends StatelessWidget {
  const _StripNode({
    required this.level,
    required this.accent,
    required this.isCurrent,
  });

  final Level level;
  final Color accent;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final size = isCurrent ? 34.0 : 28.0;
    final Widget inner;
    if (level.isCompleted) {
      inner = DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
      );
    } else if (isCurrent) {
      inner = Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          '${level.id}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.primary,
          ),
        ),
      );
    } else if (level.isUnlocked) {
      inner = DecoratedBox(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Center(
          child: Text(
            '${level.id}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: accent,
            ),
          ),
        ),
      );
    } else {
      inner = DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cardWellHigh,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          Icons.lock_rounded,
          size: 12,
          color: AppColors.textMeta,
        ),
      );
    }

    return SizedBox(width: size, height: size, child: inner);
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 2),
      painter: _DashedLinePainter(),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    const gap = 5.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 1), Offset(x + dash, 1), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}

/// Two-up "Daily Discovery" bento — Daily Challenge + Art Collections.
class _DailyDiscovery extends StatelessWidget {
  const _DailyDiscovery();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Text(
            'Daily Discovery',
            style: textTheme.labelLarge?.copyWith(color: AppColors.textDark),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _BentoCard(
                icon: Icons.calendar_today_rounded,
                iconBg: AppColors.honey,
                iconFg: AppColors.honeyText,
                title: 'Daily Challenge',
                subtitle: "Today's puzzle",
                onTap: () => context.goNamed(RouteNames.dailyPuzzle),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _BentoCard(
                icon: Icons.palette_rounded,
                iconBg: AppColors.primaryFixed,
                iconFg: AppColors.primary,
                title: 'Collections',
                subtitle: 'Your gallery',
                onTap: () => context.goNamed(RouteNames.collections),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PressScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppShadows.pill,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: AppRadius.smRadius,
              ),
              child: Icon(icon, size: 18, color: iconFg),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.textDark,
              ),
            ),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textMeta),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small secondary shortcuts so nothing competes with the collection.
class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _Shortcut(
            icon: Icons.map_rounded,
            label: 'Journey',
            color: AppColors.primary,
            onTap: () => context.goNamed(RouteNames.levels),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Shortcut(
            icon: Icons.photo_library_rounded,
            label: 'Gallery',
            color: AppColors.success,
            onTap: () => context.goNamed(RouteNames.gallery),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Shortcut(
            icon: Icons.emoji_events_rounded,
            label: 'Awards',
            color: AppColors.honeyText,
            onTap: () => context.goNamed(RouteNames.achievements),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Shortcut(
            icon: Icons.storefront_rounded,
            label: 'Shop',
            color: AppColors.attention,
            onTap: () => context.goNamed(RouteNames.shop),
          ),
          if (AppConfig.photoPuzzlesEnabled) ...[
            const SizedBox(width: AppSpacing.sm),
            _Shortcut(
              icon: Icons.photo_camera_rounded,
              label: 'Photos',
              color: AppColors.warning,
              onTap: () => context.goNamed(RouteNames.photoPuzzles),
            ),
          ],
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: AppShadows.pill,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMeta,
                fontSize: 10,
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
  const _AllCompleteBanner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BounceIn(
      child: GameCard(
        color: AppColors.primaryContainer,
        borderRadius: AppRadius.xlRadius,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration_rounded,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Collection Complete!',
              style: textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xxs),
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
