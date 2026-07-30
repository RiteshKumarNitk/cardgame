import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/ad_banner_placeholder.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../data/datasources/levels_local_datasource.dart';
import '../../data/repositories/levels_repository_impl.dart';
import '../../domain/entities/level.dart';
import '../../domain/services/chapter_catalog.dart';
import '../../domain/services/level_service.dart';
import '../bloc/levels_cubit.dart';
import '../bloc/levels_state.dart';
import '../journey/chapter_banner.dart';
import '../journey/journey_item.dart';
import '../journey/journey_level_node.dart';
import '../journey/journey_path_segment.dart';
import '../journey/level_card_sheet.dart';
import '../journey/section_complete_banner.dart';
import '../widgets/level_difficulty_style.dart';
import '../widgets/levels_top_bar.dart';

/// Level Selection screen: a winding Journey Map (chapters -> sections ->
/// levels) instead of a flat grid, behind a top bar showing coins, hints,
/// and overall completion progress.
///
/// Loading/unlocking/completing levels goes through [LevelsCubit] ->
/// [LevelService] -> [LevelsRepositoryImpl] -> Hive.
class LevelsPage extends StatelessWidget {
  /// [levelService] defaults to the real Hive-backed stack; tests can
  /// supply a service built on an in-memory fake instead of exercising
  /// real disk I/O.
  const LevelsPage({super.key, LevelService? levelService})
    : _levelService = levelService;

  final LevelService? _levelService;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          LevelsCubit(
              _levelService ??
                  LevelService(
                    LevelsRepositoryImpl(HiveLevelsLocalDataSource()),
                  ),
            )
            ..loadLevels(),
      child: const _LevelsView(),
    );
  }
}

class _LevelsView extends StatelessWidget {
  const _LevelsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        showFloatingPieces: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: BlocBuilder<LevelsCubit, LevelsState>(
              builder: (context, state) {
                return switch (state) {
                  LevelsInitial() || LevelsLoading() => const Column(
                    children: [
                      SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  LevelsError(:final message) => Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      const LevelsTopBar(progress: 0),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Failed to load levels: $message',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.danger),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  LevelsLoaded(:final levels, :final progress) => Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      LevelsTopBar(progress: progress.percentComplete),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: _JourneyMap(
                          levels: levels,
                          currentLevelId: progress.currentLevelId,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md),
                        child: AdBannerPlaceholder(),
                      ),
                    ],
                  ),
                };
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyMap extends StatefulWidget {
  const _JourneyMap({required this.levels, required this.currentLevelId});

  final List<Level> levels;
  final int? currentLevelId;

  @override
  State<_JourneyMap> createState() => _JourneyMapState();
}

class _JourneyMapState extends State<_JourneyMap> {
  late final ScrollController _scrollController;
  late List<JourneyItem> _items;

  @override
  void initState() {
    super.initState();
    _items = buildJourneyItems(widget.levels);
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void didUpdateWidget(covariant _JourneyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _items = buildJourneyItems(widget.levels);
  }

  void _scrollToCurrent() {
    if (!_scrollController.hasClients) return;
    final currentId = widget.currentLevelId;
    if (currentId == null) return;

    final index = _items.indexWhere(
      (item) => item is JourneyLevelNode && item.level.id == currentId,
    );
    if (index == -1) return;

    // Roughly center the current level: each item averages ~110px tall.
    final offset = (index * 110 - 240).toDouble().clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(offset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: AppSpacing.lg, top: AppSpacing.sm),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return switch (item) {
          JourneyChapterBanner(:final chapter) => ChapterBanner(
            chapter: chapter,
          ),
          JourneySectionComplete(:final section) => SectionCompleteBanner(
            section: section,
            reached: widget.levels[section.endLevelId - 1].isCompleted,
          ),
          JourneyLevelNode(:final level) => Column(
            children: [
              if (level.id != ChapterCatalog.chapterForLevel(level.id).startLevelId)
                JourneyPathSegment(
                  fromLevelId: level.id - 1,
                  toLevelId: level.id,
                  color: level.isUnlocked
                      ? level.difficulty.color
                      : AppColors.border,
                ),
              Align(
                alignment: Alignment(journeyWavePosition(level.id), 0),
                child: LevelNodeCircle(
                  level: level,
                  isCurrent: level.id == widget.currentLevelId,
                  onTap: level.isUnlocked
                      ? () => showLevelCardSheet(context, level)
                      : null,
                ),
              ),
            ],
          ),
        };
      },
    );
  }
}
