import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../game/ads_cubit.dart';

/// A labeled placeholder standing in for a real banner ad slot — no ad
/// network is wired up (see `AdsService`'s doc comment), but the
/// gating logic is real: it disappears once the player owns "Remove Ads".
class AdBannerPlaceholder extends StatelessWidget {
  const AdBannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdsCubit, bool>(
      builder: (context, adsRemoved) {
        if (adsRemoved) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.campaign_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Advertisement',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}
