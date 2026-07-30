import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/game_button.dart';

class LevelPreviewDialog extends StatelessWidget {
  const LevelPreviewDialog({
    super.key,
    required this.levelId,
    required this.difficulty,
    required this.stars,
    required this.onPlay,
  });

  final int levelId;
  final String difficulty;
  final int stars;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: BounceIn(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Text(
                  'Level $levelId',
                  textAlign: TextAlign.center,
                  style: AppTypography.textTheme().headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      Icons.star_rounded,
                      size: 48,
                      color: index < stars ? AppColors.accent : AppColors.border,
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Difficulty Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(difficulty).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getDifficultyColor(difficulty)),
                ),
                child: Text(
                  difficulty.toUpperCase(),
                  style: AppTypography.textTheme().titleSmall?.copyWith(
                        color: _getDifficultyColor(difficulty),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Play Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: GameButton(
                  label: 'Play',
                  icon: Icons.play_arrow_rounded,
                  onTap: () {
                    Navigator.of(context).pop(); // Close dialog
                    onPlay();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return AppColors.difficultyEasy;
      case 'medium':
        return AppColors.difficultyMedium;
      case 'hard':
        return AppColors.difficultyHard;
      case 'expert':
        return AppColors.difficultyExpert;
      case 'master':
        return AppColors.difficultyMaster;
      default:
        return AppColors.difficultyMedium;
    }
  }
}
