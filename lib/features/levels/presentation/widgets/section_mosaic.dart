import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../shared/widgets/app_image.dart';
import '../../../puzzle/domain/puzzle_image.dart';
import '../../domain/entities/level.dart';

/// A grid of every level in a section — one cell per "piece" of that
/// section's collection. Completed levels reveal their own puzzle photo;
/// the single unlocked-but-not-yet-played level gets a highlighted "play"
/// cell; everything after it is still a silhouette. Used on Home (the
/// player's in-progress collection) and on Section Complete (fully
/// revealed).
class SectionMosaic extends StatelessWidget {
  const SectionMosaic({
    super.key,
    required this.levels,
    required this.accentColor,
  });

  /// Every level belonging to one section, in order.
  final List<Level> levels;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
        ),
        itemCount: levels.length,
        itemBuilder: (context, index) =>
            _MosaicTile(level: levels[index], accentColor: accentColor),
      ),
    );
  }
}

class _MosaicTile extends StatelessWidget {
  const _MosaicTile({required this.level, required this.accentColor});

  final Level level;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (level.isCompleted) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AppImage(
          imagePath: puzzleImageUrlFor(level.id),
          fit: BoxFit.cover,
        ),
      );
    }

    // Exactly one level per section can be unlocked-but-not-completed at
    // a time (levels unlock sequentially) — that's the player's next
    // piece to collect.
    final isNext = level.isUnlocked;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isNext
            ? accentColor.withValues(alpha: 0.18)
            : AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: isNext ? Border.all(color: accentColor, width: 1.5) : null,
      ),
      child: Icon(
        isNext ? Icons.play_arrow_rounded : Icons.extension_rounded,
        color: isNext
            ? accentColor
            : AppColors.textSecondary.withValues(alpha: 0.5),
        size: 14,
      ),
    );
  }
}
