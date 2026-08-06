import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/achievements/data/achievements_repository_impl.dart';
import '../../features/achievements/presentation/bloc/achievements_cubit.dart';
import '../../features/achievements/presentation/bloc/achievements_state.dart';
import '../../features/settings/data/settings_repository_impl.dart';
import '../../features/settings/domain/entities/app_settings.dart';
import '../../features/settings/presentation/bloc/settings_cubit.dart';
import '../../game/ads_cubit.dart';
import '../../game/ads_service.dart';
import '../../game/wallet_cubit.dart';
import '../../game/wallet_service.dart';
import '../../services/audio_service.dart';
import '../../services/analytics_service.dart';
import '../constants/app_constants.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

/// Root widget of the application.
///
/// Wires together theming, routing, global state (wallet, ads, settings,
/// achievements), and the audio system. [SettingsCubit] is provided here
/// so the audio service can sync with the player's sound/music preferences
/// across the entire app. Feature screens reached through [appRouter].
class PuzzleCardsApp extends StatelessWidget {
  /// All cubits default to real Hive-backed services; tests can supply
  /// in-memory fakes instead.
  const PuzzleCardsApp({
    super.key,
    WalletCubit? walletCubit,
    AdsCubit? adsCubit,
    SettingsCubit? settingsCubit,
    AchievementsCubit? achievementsCubit,
  }) : _walletCubit = walletCubit,
       _adsCubit = adsCubit,
       _settingsCubit = settingsCubit,
       _achievementsCubit = achievementsCubit;

  final WalletCubit? _walletCubit;
  final AdsCubit? _adsCubit;
  final SettingsCubit? _settingsCubit;
  final AchievementsCubit? _achievementsCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WalletCubit>(
          create: (_) => _walletCubit ?? WalletCubit(HiveWalletService()),
        ),
        BlocProvider<AdsCubit>(
          create: (_) => _adsCubit ?? AdsCubit(HiveAdsService()),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) =>
              (_settingsCubit ?? SettingsCubit(HiveSettingsRepository())..load()),
        ),
        BlocProvider<AchievementsCubit>(
          create: (_) =>
              (_achievementsCubit ??
                  AchievementsCubit(HiveAchievementsRepository())..load()),
        ),
      ],
      child: _AchievementRewardListener(
        child: _AudioSyncWidget(
          child: MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.game,
            themeMode: ThemeMode.light,
            routerConfig: appRouter,
          ),
        ),
      ),
    );
  }
}

/// Pays out the coin reward exactly once for every newly-unlocked
/// achievement. Lives at the root so reward crediting is independent of
/// whatever screen the player happens to be on when a milestone crosses.
class _AchievementRewardListener extends StatelessWidget {
  const _AchievementRewardListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AchievementsCubit, AchievementsState>(
      listenWhen: (previous, next) =>
          next is AchievementsLoaded &&
          next.justUnlocked.isNotEmpty &&
          (previous is! AchievementsLoaded ||
              previous.justUnlocked != next.justUnlocked),
      listener: (context, state) {
        final stateAsLoaded = state as AchievementsLoaded;
        final total = stateAsLoaded.justUnlocked.fold(
          0,
          (sum, achievement) => sum + achievement.rewardCoins,
        );
        if (total <= 0) return;
        context.read<WalletCubit>().addCoins(total);
        AudioService().playCoinReward();
        AnalyticsService().logEvent(
          AnalyticsService.achievementRewarded,
          parameters: {
            'count': stateAsLoaded.justUnlocked.length,
            'coins': total,
          },
        );
      },
      child: child,
    );
  }
}

/// Listens to [SettingsCubit] changes and syncs them to [AudioService].
class _AudioSyncWidget extends StatelessWidget {
  const _AudioSyncWidget({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsCubit, AppSettings>(
      listenWhen: (prev, next) =>
          prev.soundEnabled != next.soundEnabled ||
          prev.musicEnabled != next.musicEnabled,
      listener: (context, settings) {
        AudioService().updateSettings(
          soundEnabled: settings.soundEnabled,
          musicEnabled: settings.musicEnabled,
        );
      },
      child: child,
    );
  }
}
