import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/utils/duration_format.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../domain/entities/level.dart';
import '../../domain/services/chapter_catalog.dart';
import '../widgets/level_difficulty_style.dart';

/// Opens the [LevelCardSheet] for [level] as a bottom sheet.
Future<void> showLevelCardSheet(BuildContext context, Level level) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => LevelCardSheet(level: level),
  );
}

/// Bottom sheet shown when tapping a level node on the Journey Map: level
/// number, chapter/section context, difficulty, best stars/time/moves, and
/// a Play button into the puzzle.
class LevelCardSheet extends StatelessWidget {
  const LevelCardSheet({super.key, required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chapter = ChapterCatalog.chapterForLevel(level.id);
    final section = ChapterCatalog.sectionForLevel(level.id);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GameCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Level ${level.id}',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${chapter.name} · Section ${section.index}',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DifficultyBadgeChip(difficulty: level.difficulty),
              const SizedBox(height: AppSpacing.lg),
              _StarsRow(stars: level.stars),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StatChip(
                    icon: Icons.timer_rounded,
                    value: level.bestTimeSeconds != null
                        ? formatMinutesSeconds(level.bestTimeSeconds!)
                        : '--',
                    iconColor: AppColors.secondary,
                  ),
                  StatChip(
                    icon: Icons.touch_app_rounded,
                    value: level.bestMoves?.toString() ?? '--',
                    iconColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              GameButton(
                label: level.isCompleted ? 'Replay' : 'Play',
                icon: Icons.play_arrow_rounded,
                width: double.infinity,
                onTap: () {
                  Navigator.of(context).pop();
                  context.goNamed(
                    RouteNames.puzzle,
                    pathParameters: {'levelId': '${level.id}'},
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A slightly larger [DifficultyBadge]-style chip for the sheet's header —
/// same colors, more presence than the compact map/top-bar version.
class DifficultyBadgeChip extends StatelessWidget {
  const DifficultyBadgeChip({super.key, required this.difficulty});

  final LevelDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: difficulty.color,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        difficulty.label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final filled = index < stars;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: 32,
          color: filled ? AppColors.accent : AppColors.border,
        );
      }),
    );
  }
}
