import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/settings/data/settings_repository_impl.dart';
import '../../features/settings/domain/entities/app_settings.dart';
import '../../features/settings/presentation/bloc/settings_cubit.dart';
import '../../game/ads_cubit.dart';
import '../../game/ads_service.dart';
import '../../game/wallet_cubit.dart';
import '../../game/wallet_service.dart';
import '../../services/audio_service.dart';
import '../constants/app_constants.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

/// Root widget of the application.
///
/// Wires together theming, routing, global state (wallet, ads, settings),
/// and the audio system. [SettingsCubit] is provided here so the audio
/// service can sync with the player's sound/music preferences across
/// the entire app. Feature screens reached through [appRouter].
class PuzzleCardsApp extends StatelessWidget {
  /// [walletCubit]/[adsCubit]/[settingsCubit] default to real Hive-backed
  /// services; tests can supply in-memory fakes instead.
  const PuzzleCardsApp({
    super.key,
    WalletCubit? walletCubit,
    AdsCubit? adsCubit,
    SettingsCubit? settingsCubit,
  }) : _walletCubit = walletCubit,
       _adsCubit = adsCubit,
       _settingsCubit = settingsCubit;

  final WalletCubit? _walletCubit;
  final AdsCubit? _adsCubit;
  final SettingsCubit? _settingsCubit;

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
      ],
      child: _AudioSyncWidget(
        child: MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.game,
          themeMode: ThemeMode.light,
          routerConfig: appRouter,
        ),
      ),
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

