import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/stat_chip.dart';

/// Home's top bar: Settings on the left; coins, hints, and Shop clustered
/// on the right — the standard layout for top-grossing casual games.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleIconButton(
          icon: Icons.settings_rounded,
          onTap: () => context.goNamed(RouteNames.settings),
        ),
        const Spacer(),
        const StatChip(
          icon: Icons.monetization_on_rounded,
          value: '1,250',
          iconColor: AppColors.accent,
        ),
        const SizedBox(width: AppSpacing.sm),
        const StatChip(
          icon: Icons.lightbulb_rounded,
          value: '5',
          iconColor: AppColors.success,
        ),
        const SizedBox(width: AppSpacing.sm),
        CircleIconButton(
          icon: Icons.storefront_rounded,
          iconColor: AppColors.secondary,
          onTap: () => context.goNamed(RouteNames.shop),
        ),
      ],
    );
  }
}
