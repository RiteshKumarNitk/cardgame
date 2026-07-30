import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/confetti_burst.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/pulsing_glow.dart';

class ChapterCompleteScreen extends StatelessWidget {
  const ChapterCompleteScreen({super.key, required this.chapterId});

  final int chapterId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: GameBackground(
        showFloatingPieces: true,
        child: Stack(
          children: [
            const Positioned.fill(child: ConfettiBurst()),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Large Chapter Badge
                      BounceIn(
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.premiumGradientStart,
                                AppColors.premiumGradientEnd,
                              ],
                            ),
                            border: Border.all(color: Colors.white, width: 8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.premiumGradientStart.withOpacity(0.6),
                                blurRadius: 40,
                                spreadRadius: 10,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 100,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      BounceIn(
                        delay: const Duration(milliseconds: 300),
                        child: Text(
                          'Chapter $chapterId',
                          style: textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      BounceIn(
                        delay: const Duration(milliseconds: 500),
                        child: Text(
                          'Completed!',
                          style: textTheme.displaySmall?.copyWith(
                            color: AppColors.premiumGradientStart,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      // Rewards
                      BounceIn(
                        delay: const Duration(milliseconds: 1000),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _RewardItem(icon: Icons.monetization_on_rounded, amount: '+500', color: AppColors.premiumGradientStart),
                            const SizedBox(width: AppSpacing.xl),
                            _RewardItem(icon: Icons.lightbulb_rounded, amount: '+5', color: AppColors.secondary),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                      BounceIn(
                        delay: const Duration(milliseconds: 1500),
                        child: PulsingGlow(
                          color: AppColors.success,
                          child: GameButton(
                            label: 'Continue Journey',
                            icon: Icons.map_rounded,
                            width: 260,
                            height: 72,
                            onTap: () => context.goNamed(RouteNames.levels),
                          ),
                        ),
                      ),
                    ],
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

class _RewardItem extends StatelessWidget {
  const _RewardItem({required this.icon, required this.amount, required this.color});
  final IconData icon;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 40),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
