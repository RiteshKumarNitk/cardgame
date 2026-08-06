import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_card.dart';

/// In-app Privacy Policy — required for store submission (Google Play
/// Data Safety / App Store privacy). This is a placeholder template: the
/// store-facing policy must be written by the publisher and linked here.
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
                            'Last updated: [DATE]',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _Section(
                            title: 'Data we collect',
                            body: '${AppConstants.appName} stores your game '
                                'progress, coin balance, achievements and '
                                'settings locally on your device. With your '
                                'consent we also use anonymous analytics '
                                '(Firebase Analytics) and crash reporting '
                                '(Firebase Crashlytics) to improve the game. '
                                'Advertising (AdMob) may collect '
                                'advertising identifiers; you can opt out of '
                                'personalized ads at any time in your device '
                                'settings.',
                          ),
                          _Section(
                            title: 'Cloud sync',
                            body: 'When cloud sync is enabled, your progress '
                                'and coins are backed up to Firebase under '
                                'an anonymous user ID. You can erase this '
                                'data by using the "Erase my data" option in '
                                'Settings.',
                          ),
                          _Section(
                            title: 'Purchases',
                            body: 'In-app purchases are processed by the '
                                'platform store (Google Play / App Store) '
                                'and its payment processor. We do not see or '
                                'store your payment details.',
                          ),
                          _Section(
                            title: 'Your choices',
                            body: 'You can disable sound and music, reset '
                                'your local progress, and restore purchases '
                                'from Settings at any time. To request '
                                'deletion of cloud data, contact the '
                                'publisher.',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Replace this placeholder with the publisher\'s '
                            'actual policy and the effective date before '
                            'store submission.',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.danger,
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
