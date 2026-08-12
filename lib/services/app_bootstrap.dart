import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'ad_service.dart';
import 'analytics_service.dart';
import 'cloud_save_service.dart';
import 'purchase_service.dart';

/// The boot/login stages the splash loader shows. Each stage maps to a
/// chunk of real startup work, so the loading screen is honest progress
/// instead of a fixed fake delay.
enum BootstrapStage {
  /// No startup work has begun (or the platform needs no login, e.g. web).
  preparing,

  /// Firebase init + anonymous sign-in (the game's "login").
  loggingIn,

  /// Mirroring already-owned RevenueCat entitlements.
  syncing,

  /// Initializing ads and preloading the first units.
  loadingAds,

  /// Everything finished — the splash can navigate to Home.
  ready,
}

/// Runs the app's deferred startup work and publishes each stage on a
/// [ValueNotifier] the splash screen observes.
///
/// Singleton (same pattern as the other services). [run] is called once
/// from `main()` right after `runApp`, so the splash is already on screen
/// while login/sync/ad-init happen. Every step is failure-tolerant — a
/// missing backend must never block the game from starting.
class AppBootstrap {
  static final AppBootstrap _instance = AppBootstrap._();
  factory AppBootstrap() => _instance;
  AppBootstrap._();

  final ValueNotifier<BootstrapStage> stage = ValueNotifier(
    BootstrapStage.preparing,
  );

  bool _started = false;

  /// Whether [run] has been invoked (distinguishes a real boot from test
  /// harnesses that never call it).
  bool get started => _started;

  Future<void> run() async {
    _started = true;
    if (!kIsWeb) {
      stage.value = BootstrapStage.loggingIn;
      try {
        await Firebase.initializeApp();
        AnalyticsService().enableCrashReporting();
        await CloudSaveService().signInAnonymously();
      } catch (e) {
        debugPrint('Firebase init failed: $e');
      }

      stage.value = BootstrapStage.syncing;
      try {
        // Production keys are injected with --dart-define; without them
        // this degrades to a no-op instead of crashing.
        await Purchases.setLogLevel(LogLevel.debug);
        if (defaultTargetPlatform == TargetPlatform.android) {
          final key = const String.fromEnvironment('REVENUECAT_ANDROID_KEY');
          if (key.isNotEmpty) {
            await Purchases.configure(PurchasesConfiguration(key));
          }
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final key = const String.fromEnvironment('REVENUECAT_IOS_KEY');
          if (key.isNotEmpty) {
            await Purchases.configure(PurchasesConfiguration(key));
          }
        }
        // Mirror already-owned entitlements (reinstall, other device) so
        // the first ad placement respects Remove Ads.
        await RevenueCatPurchaseService().syncEntitlements();
      } catch (e) {
        debugPrint('RevenueCat init failed: $e');
      }

      stage.value = BootstrapStage.loadingAds;
      try {
        await MobileAds.instance.initialize();
        AdService().loadRewardedAd();
        AdService().loadInterstitial();
      } catch (e) {
        debugPrint('Ads init failed: $e');
      }
    }

    await AnalyticsService().logEvent(AnalyticsService.appLaunch);
    stage.value = BootstrapStage.ready;
  }

  /// Completes when the bootstrap reaches [BootstrapStage.ready] (or
  /// immediately if it already has). The splash awaits this with a hard
  /// timeout so a hung network can never trap the player on the loader.
  Future<void> whenReady() {
    if (stage.value == BootstrapStage.ready) return Future.value();
    final completer = Completer<void>();
    void listener() {
      if (stage.value == BootstrapStage.ready) {
        stage.removeListener(listener);
        completer.complete();
      }
    }

    stage.addListener(listener);
    return completer.future;
  }
}
