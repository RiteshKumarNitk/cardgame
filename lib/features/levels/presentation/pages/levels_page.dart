import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../data/datasources/levels_local_datasource.dart';
import '../../data/repositories/levels_repository_impl.dart';
import '../../domain/entities/level.dart';
import '../../domain/services/level_service.dart';
import '../bloc/levels_cubit.dart';
import '../bloc/levels_state.dart';
import '../widgets/level_tile.dart';
import '../widgets/levels_top_bar.dart';

/// Level Selection screen: a scrollable grid of the 100 demo levels behind
/// a top bar showing coins, hints, and overall completion progress.
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
                        child: _LevelsGrid(
                          levels: levels,
                          currentLevelId: progress.currentLevelId,
                        ),
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

class _LevelsGrid extends StatelessWidget {
  const _LevelsGrid({required this.levels, required this.currentLevelId});

  final List<Level> levels;
  final int? currentLevelId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 88)
            .floor()
            .clamp(4, 8);

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1,
          ),
          itemCount: levels.length,
          itemBuilder: (context, index) {
            final level = levels[index];
            return LevelTile(
              level: level,
              isCurrent: level.id == currentLevelId,
              onTap: level.isUnlocked
                  ? () => context.goNamed(
                      RouteNames.puzzle,
                      pathParameters: {'levelId': '${level.id}'},
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
