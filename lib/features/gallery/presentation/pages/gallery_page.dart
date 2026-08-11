import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/banner_ad_widget.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../levels/data/datasources/levels_local_datasource.dart';
import '../../../levels/data/repositories/levels_repository_impl.dart';
import '../../../levels/domain/entities/level.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../../puzzle/domain/puzzle_image.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<Level> _levels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    final service = LevelService(LevelsRepositoryImpl(HiveLevelsLocalDataSource()));
    final levels = await service.loadLevels();
    if (!mounted) return;
    setState(() {
      _levels = levels;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _levels.where((l) => l.isCompleted).length;
    final totalCount = _levels.length;

    return Scaffold(
      body: GameBackground(
        showFloatingPieces: true,
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
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
                        'Gallery',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(color: AppColors.outline, width: 2),
                        ),
                        child: Text(
                          '$completedCount / $totalCount',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    // The Collections Showcase: one hero card per chapter
                    // with its painted artwork and progress.
                    CircleIconButton(
                      icon: Icons.collections_bookmark_rounded,
                      iconColor: AppColors.secondary,
                      onTap: () => context.goNamed(RouteNames.collections),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Photo Puzzles: the developer's real-photo section.
                    CircleIconButton(
                      icon: Icons.photo_camera_rounded,
                      iconColor: AppColors.warning,
                      onTap: () => context.goNamed(RouteNames.photoPuzzles),
                    ),
                  ],
                ),
              ),

              // Grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 3 / 4,
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                        ),
                        itemCount: totalCount,
                        itemBuilder: (context, index) {
                          final level = _levels[index];
                          return _GalleryItem(level: level);
                        },
                      ),
              ),
              
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryItem extends StatelessWidget {
  const _GalleryItem({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final imageUrl = puzzleImageUrlFor(level.id);

    return GameCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.lgRadius,
        child: level.isCompleted
            ? AppImage(
                imagePath: imageUrl,
                fit: BoxFit.cover,
              )
            : Container(
                color: AppColors.border,
                child: Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    size: 32,
                  ),
                ),
              ),
      ),
    );
  }
}
