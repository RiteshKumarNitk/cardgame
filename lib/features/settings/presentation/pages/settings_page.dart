import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/purchase_service.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../game/ads_cubit.dart';
import '../../../levels/data/datasources/levels_local_datasource.dart';
import '../../../levels/data/repositories/levels_repository_impl.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../data/settings_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../bloc/settings_cubit.dart';

/// Settings screen: sound/music toggles and a (confirmed) reset of level
/// progress.
///
/// Uses the [SettingsCubit] provided by [PuzzleCardsApp] at the app root,
/// so the audio service stays in sync across all screens. Falls back to
/// creating its own if none is found (backward-compat for tests).
class SettingsPage extends StatelessWidget {
  /// [settingsRepository]/[levelService] — defaults to real Hive-backed
  /// stacks; tests can supply ones built on in-memory fakes instead.
  const SettingsPage({
    super.key,
    SettingsRepository? settingsRepository,
    LevelService? levelService,
    PurchaseService? purchaseService,
  }) : _settingsRepository = settingsRepository,
       _levelService = levelService,
       _purchaseService = purchaseService;

  final SettingsRepository? _settingsRepository;
  final LevelService? _levelService;

  /// Defaults to the real RevenueCat-backed service; tests inject fakes.
  final PurchaseService? _purchaseService;

  @override
  Widget build(BuildContext context) {
    // Wrap in a provider only if none exists up the tree (tests).
    Widget view = _SettingsView(
      levelService:
          _levelService ??
          LevelService(LevelsRepositoryImpl(HiveLevelsLocalDataSource())),
      purchaseService: _purchaseService ?? RevenueCatPurchaseService(),
    );
    try {
      context.read<SettingsCubit>();
    } on ProviderNotFoundException {
      view = BlocProvider(
        create: (_) =>
            SettingsCubit(_settingsRepository ?? HiveSettingsRepository())..load(),
        child: view,
      );
    }
    return view;
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({
    required this.levelService,
    required this.purchaseService,
  });

  final LevelService levelService;
  final PurchaseService purchaseService;

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
                      'Settings',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audio',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        BlocBuilder<SettingsCubit, AppSettings>(
                          builder: (context, settings) => Column(
                            children: [
                              _SettingToggle(
                                icon: Icons.volume_up_rounded,
                                title: 'Sound Effects',
                                subtitle: 'Piece drops, wins, and taps',
                                value: settings.soundEnabled,
                                onChanged: (_) =>
                                    context.read<SettingsCubit>().toggleSound(),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _SettingToggle(
                                icon: Icons.music_note_rounded,
                                title: 'Music',
                                subtitle: 'Background music',
                                value: settings.musicEnabled,
                                onChanged: (_) =>
                                    context.read<SettingsCubit>().toggleMusic(),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _VolumeSlider(
                                icon: Icons.volume_up_rounded,
                                label: 'Master Volume',
                                value: settings.masterVolume,
                                onChanged: (v) => context
                                    .read<SettingsCubit>()
                                    .setMasterVolume(v, persist: false),
                                onChangeEnd: (v) => context
                                    .read<SettingsCubit>()
                                    .setMasterVolume(v),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _VolumeSlider(
                                icon: Icons.graphic_eq_rounded,
                                label: 'Sound Effects Volume',
                                value: settings.sfxVolume,
                                enabled: settings.soundEnabled,
                                onChanged: (v) => context
                                    .read<SettingsCubit>()
                                    .setSfxVolume(v, persist: false),
                                onChangeEnd: (v) => context
                                    .read<SettingsCubit>()
                                    .setSfxVolume(v),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _VolumeSlider(
                                icon: Icons.music_note_rounded,
                                label: 'Music Volume',
                                value: settings.musicVolume,
                                enabled: settings.musicEnabled,
                                onChanged: (v) => context
                                    .read<SettingsCubit>()
                                    .setMusicVolume(v, persist: false),
                                onChangeEnd: (v) => context
                                    .read<SettingsCubit>()
                                    .setMusicVolume(v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Progress',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GameCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Reset Progress',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    Text(
                                      'Erases all level stars and unlocks',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _confirmReset(context, levelService),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                ),
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'About',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GameCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Text(
                                AppConstants.appName,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textDark,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'v1.0.0',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Account & Legal',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GameCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            children: [
                              _SettingsRow(
                                icon: Icons.sync_rounded,
                                title: 'Restore Purchases',
                                subtitle: 'Re-apply paid entitlements',
                                onTap: () =>
                                    _restorePurchases(context),
                              ),
                              const Divider(
                                height: AppSpacing.md,
                                color: AppColors.border,
                              ),
                              _SettingsRow(
                                icon: Icons.privacy_tip_rounded,
                                title: 'Privacy Policy',
                                onTap: () => context.goNamed(
                                  RouteNames.privacyPolicy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  /// Runs the platform restore-purchases flow through [PurchaseService]
  /// and mirrors any restored "Remove Ads" entitlement into local state.
  /// Unconfigured RevenueCat (dev/web) degrades to a friendly message
  /// instead of crashing.
  Future<void> _restorePurchases(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await purchaseService.restorePurchases();
    if (!context.mounted) return;

    switch (result.outcome) {
      case PurchaseOutcome.success:
        if (result.restoredRemoveAds) {
          context.read<AdsCubit>().purchaseRemoveAds();
        }
        AnalyticsService().logEvent(AnalyticsService.purchasesRestored);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              result.restoredRemoveAds
                  ? 'Purchases restored · Remove Ads active'
                  : 'No purchasable entitlements found to restore',
            ),
          ),
        );
      case PurchaseOutcome.cancelled:
        messenger.showSnackBar(
          const SnackBar(content: Text('Restore was cancelled')),
        );
      case PurchaseOutcome.unavailable:
        messenger.showSnackBar(
          const SnackBar(content: Text('Restore purchases is not available right now')),
        );
      case PurchaseOutcome.failed:
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not restore purchases — try again.')),
        );
    }
  }

  void _confirmReset(BuildContext context, LevelService levelService) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: GameCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_rounded,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Reset all progress?',
                style: Theme.of(
                  dialogContext,
                ).textTheme.titleLarge?.copyWith(color: AppColors.textDark),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'This erases every level\'s stars and unlocks. This can\'t be undone.',
                textAlign: TextAlign.center,
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GameButton(
                label: 'Reset Progress',
                icon: Icons.restart_alt_rounded,
                width: 220,
                onTap: () async {
                  Navigator.of(dialogContext).pop();
                  await levelService.resetProgress();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Progress reset')),
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GameCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: textTheme.bodySmall?.copyWith(
                  color: enabled
                      ? AppColors.textSecondary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              thumbColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              onChanged: enabled ? onChanged : null,
              onChangeEnd: enabled ? onChangeEnd : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  const _SettingToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GameCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
