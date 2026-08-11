import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../../levels/data/datasources/levels_local_datasource.dart';
import '../../../levels/data/repositories/levels_repository_impl.dart';
import '../../../levels/domain/entities/chapter.dart';
import '../../../levels/domain/entities/level.dart';
import '../../../levels/domain/services/chapter_catalog.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../../puzzle/domain/puzzle_image.dart';
import '../../../levels/presentation/widgets/level_difficulty_style.dart';

/// The Collections Showcase: one hero card per chapter, presenting the
/// chapter's painted artwork, difficulty, and the player's progress on
/// that collection. This is the game's "showcase" surface — it shows off
/// the 16 themed artworks that the level images are fragments of.
class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key, LevelService? levelService})
    : _levelService = levelService;

  /// Defaults to the real Hive-backed stack; tests inject a fake.
  final LevelService? _levelService;

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  List<Level>? _levels;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service =
        widget._levelService ??
        LevelService(LevelsRepositoryImpl(HiveLevelsLocalDataSource()));
    final levels = await service.loadLevels();
    if (!mounted) return;
    setState(() => _levels = levels);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: GameBackground(
        showFloatingPieces: true,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.goNamed(RouteNames.home);
                        }
                      },
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Collections',
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Text(
                  'Every chapter is one painted collection — solve its '
                  'levels to gather every fragment.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _levels == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.58,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                            ),
                        itemCount: ChapterCatalog.chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = ChapterCatalog.chapters[index];
                          return _ChapterCard(
                            chapter: chapter,
                            stats: _statsFor(chapter),
                            onTap: () =>
                                _showChapterSheet(context, chapter),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _ChapterStats _statsFor(Chapter chapter) {
    var completed = 0;
    var stars = 0;
    int? currentLevelId;
    for (final level in _levels!) {
      if (level.id < chapter.startLevelId) continue;
      if (level.id > chapter.endLevelId) break;
      if (level.isCompleted) completed++;
      stars += level.stars;
      currentLevelId ??= level.isUnlocked && !level.isCompleted
          ? level.id
          : null;
    }
    return _ChapterStats(
      completed: completed,
      total: chapter.levelCount,
      stars: stars,
      currentLevelId: currentLevelId,
    );
  }

  void _showChapterSheet(BuildContext context, Chapter chapter) {
    final stats = _statsFor(chapter);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _ChapterDetailSheet(
        chapter: chapter,
        stats: stats,
      ),
    );
  }
}

class _ChapterStats {
  const _ChapterStats({
    required this.completed,
    required this.total,
    required this.stars,
    required this.currentLevelId,
  });

  final int completed;
  final int total;
  final int stars;
  final int? currentLevelId;

  double get fraction => total == 0 ? 0 : completed / total;
}

/// The hero image for a chapter: the real photo used by its first level.
String _heroImageFor(Chapter chapter) => puzzleImageUrlFor(chapter.startLevelId);

/// ────────────────────────────────────────────────────────────────────
/// One chapter card in the showcase grid
/// ────────────────────────────────────────────────────────────────────
class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
    required this.stats,
    required this.onTap,
  });

  final Chapter chapter;
  final _ChapterStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = chapter.difficulty.color;

    return GameCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(imagePath: _heroImageFor(chapter), fit: BoxFit.cover),
                    // Completed collections get a subtle celebratory tint.
                    if (stats.completed == stats.total)
                      ColoredBox(
                        color: AppColors.success.withValues(alpha: 0.28),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          chapter.difficulty.label,
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chapter ${chapter.id}',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    chapter.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: AppRadius.pillRadius,
                          child: LinearProgressIndicator(
                            value: stats.fraction,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${stats.completed}/${stats.total}',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.accent,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${stats.stars}',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
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

/// ────────────────────────────────────────────────────────────────────
/// Chapter detail bottom sheet: hero art + stats + play shortcut
/// ────────────────────────────────────────────────────────────────────
class _ChapterDetailSheet extends StatelessWidget {
  const _ChapterDetailSheet({required this.chapter, required this.stats});

  final Chapter chapter;
  final _ChapterStats stats;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = chapter.difficulty.color;
    final allDone = stats.completed == stats.total;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GameCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppRadius.lgRadius,
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: AppImage(
                    imagePath: _heroImageFor(chapter),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Chapter ${chapter.id} · ${chapter.difficulty.label}',
                style: textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                chapter.name,
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppRadius.pillRadius,
                child: LinearProgressIndicator(
                  value: stats.fraction,
                  minHeight: 10,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.extension_rounded, color: accent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${stats.completed} / ${stats.total} pieces',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${stats.stars} stars',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (allDone)
                BounceIn(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.celebration_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Collection complete!',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              else
                GameButton(
                  label: 'Keep Playing · Level ${stats.currentLevelId}',
                  icon: Icons.play_arrow_rounded,
                  width: double.infinity,
                  onTap: () {
                    final levelId = stats.currentLevelId;
                    if (levelId == null) return;
                    Navigator.of(context).pop();
                    context.goNamed(
                      RouteNames.puzzle,
                      pathParameters: {'levelId': '$levelId'},
                    );
                  },
                ),
              const SizedBox(height: AppSpacing.sm),
              PressScale(
                onTap: () {
                  Navigator.of(context).pop();
                  context.goNamed(RouteNames.levels);
                },
                child: Center(
                  child: Text(
                    'View Journey Map',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
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
