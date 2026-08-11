import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../data/photo_progress_service.dart';
import '../../domain/photo_catalog.dart';
import '../../domain/photo_puzzle.dart';

/// Photo Puzzles: a gallery of the developer's real photos (bundled in
/// `assets/images/photos/` or referenced by URL from `manifest.json`),
/// each playable as a puzzle. Adding an image is a file drop + one JSON
/// line — no code changes — see the README in that folder.
class PhotoPuzzlesPage extends StatefulWidget {
  const PhotoPuzzlesPage({
    super.key,
    Future<List<PhotoPuzzle>> Function()? loadPhotos,
    PhotoProgressService? progressService,
  }) : _loadPhotos = loadPhotos,
       _progressService = progressService;

  final Future<List<PhotoPuzzle>> Function()? _loadPhotos;
  final PhotoProgressService? _progressService;

  @override
  State<PhotoPuzzlesPage> createState() => _PhotoPuzzlesPageState();
}

class _PhotoPuzzlesPageState extends State<PhotoPuzzlesPage> {
  List<PhotoPuzzle>? _photos;
  Map<String, int> _bestStars = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loadPhotos = widget._loadPhotos ?? PhotoCatalog.load;
    final progress = widget._progressService ?? HivePhotoProgressService();
    final photos = await loadPhotos();
    final bestStars = await progress.loadBestStars();
    if (!mounted) return;
    setState(() {
      _photos = photos;
      _bestStars = bestStars;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final photos = _photos;

    return Scaffold(
      body: GameBackground(
        showFloatingPieces: false,
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
                        'Photo Puzzles',
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Text(
                  'Real photos, real puzzles. Add your own in '
                  'assets/images/photos/',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: photos == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : photos.isEmpty
                    ? const _EmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.62,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                            ),
                        itemCount: photos.length,
                        itemBuilder: (context, index) => _PhotoCard(
                          photo: photos[index],
                          bestStars: _bestStars[photos[index].id] ?? 0,
                          onTap: () => context.goNamed(
                            RouteNames.photoPuzzle,
                            extra: photos[index],
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

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.photo,
    required this.bestStars,
    required this.onTap,
  });

  final PhotoPuzzle photo;
  final int bestStars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                    AppImage(imagePath: photo.image, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: AppColors.outline,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.accent,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              bestStars > 0 ? '$bestStars' : 'New',
                              style: textTheme.labelSmall?.copyWith(
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                photo.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.textDark,
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

/// Shown when the manifest has no photos: quick instructions instead of a
/// blank screen.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GameCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_photo_alternate_rounded,
                color: AppColors.primary,
                size: 56,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Add your first photo',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Drop an image into assets/images/photos/ and list it in '
                'manifest.json (or use a URL). See the README in that '
                'folder — no code changes needed.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
