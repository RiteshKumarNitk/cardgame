import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/action_card.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/bounce_in.dart';
import '../../../../shared/widgets/floating_bob.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/pulsing_glow.dart';
import '../widgets/home_top_bar.dart';

/// Home screen: top stat bar, a floating logo, a glowing Play CTA, and
/// featured Continue Game / Daily Challenge cards.
///
/// No gameplay or backend here — Play/Continue open Level Selection, Daily
/// Challenge and Shop open their placeholder screens.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HomeTopBar(),
                    const SizedBox(height: AppSpacing.xl),
                    const FloatingBob(child: AppLogo(size: 100)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppConstants.appName,
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    BounceIn(
                      child: PulsingGlow(
                        color: AppColors.primaryGradientEnd,
                        child: GameButton(
                          label: 'Play',
                          icon: Icons.play_arrow_rounded,
                          width: 220,
                          height: 68,
                          onTap: () => context.goNamed(RouteNames.levels),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    BounceIn(
                      delay: const Duration(milliseconds: 100),
                      child: ActionCard(
                        icon: Icons.videogame_asset_rounded,
                        iconBackground: AppColors.primary,
                        title: 'Continue Game',
                        subtitle: 'Level 1 · Easy',
                        onTap: () => context.goNamed(RouteNames.levels),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    BounceIn(
                      delay: const Duration(milliseconds: 200),
                      child: ActionCard(
                        icon: Icons.card_giftcard_rounded,
                        iconBackground: AppColors.accent,
                        title: 'Daily Challenge',
                        subtitle: 'A new puzzle is waiting for you!',
                        badgeLabel: 'NEW',
                        onTap: () => context.goNamed(RouteNames.dailyPuzzle),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _HomeFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              child: Text('Privacy Policy', style: textStyle),
            ),
            Text('•', style: textStyle),
            TextButton(
              onPressed: () {},
              child: Text('Restore Purchase', style: textStyle),
            ),
          ],
        ),
        Text('v1.0.0', style: textStyle),
      ],
    );
  }
}
