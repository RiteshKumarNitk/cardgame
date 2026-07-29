import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../../../shared/widgets/stat_chip.dart';

/// Top bar for Level Selection: back button, coins, hints, and overall
/// completion progress.
class LevelsTopBar extends StatelessWidget {
  const LevelsTopBar({super.key, required this.progress});

  /// 0.0 - 1.0.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Column(
      children: [
        Row(
          children: [
            PressScale(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed(RouteNames.home);
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            const Spacer(),
            BlocBuilder<WalletCubit, int>(
              builder: (context, coins) => StatChip(
                icon: Icons.monetization_on_rounded,
                value: formatThousands(coins),
                iconColor: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            const StatChip(
              icon: Icons.lightbulb_rounded,
              value: '5',
              iconColor: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.pillRadius,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Text(
              '$percent%',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.textDark),
            ),
          ],
        ),
      ],
    );
  }
}
