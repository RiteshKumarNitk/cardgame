import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_card.dart';

/// In-app Privacy Policy summary — required for store submission (Google
/// Play Data Safety / App Store privacy). The authoritative full policy is
/// hosted publicly (see docs/legal/privacy-policy.html); keep this summary
/// in sync with it. Update the hosted URL string below before release.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: GameBackground(
        showFloatingPieces: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
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
                    Text(
                      'Privacy Policy',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: SingleChildScrollView(
                    child: GameCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The full policy is published at '
                            'suitclash.example.com/privacy — this is a summary.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _Section(
                            title: 'Data we collect',
                            body: '${AppConstants.appName} stores your game '
                                'progress, coin balance, achievements and '
                                'settings locally on your device. We also use '
                                'anonymous analytics (Firebase Analytics) and '
                                'crash reporting (Firebase Crashlytics) to '
                                'improve the game. This version shows no ads '
                                'and collects no advertising identifier.',
                          ),
                          _Section(
                            title: 'Cloud sync',
                            body: 'Your progress and coins are backed up to '
                                'Firebase under an anonymous user ID that is '
                                'not linked to your name, email or Google '
                                'account. If you set a display name it appears '
                                'on the public leaderboard. Erase this data '
                                'any time with "Erase my data" in Settings.',
                          ),
                          _Section(
                            title: 'Purchases',
                            body: 'In-app purchases are processed by Google '
                                'Play. We do not see or store your payment '
                                'details.',
                          ),
                          _Section(
                            title: 'Your choices',
                            body: 'You can disable sound and music, reset '
                                'your local progress, restore purchases, and '
                                'erase your cloud data from Settings at any '
                                'time.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
