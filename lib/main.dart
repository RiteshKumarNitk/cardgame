import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/cloud_save_service.dart';
import 'core/app/puzzle_cards_app.dart';
import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'services/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await HiveService.init();

  if (!kIsWeb) {
    try {
      // Note: The user needs to run `flutterfire configure` to fully support iOS/Web
      await Firebase.initializeApp();
      AnalyticsService().enableCrashReporting();
      await CloudSaveService().signInAnonymously();
    } catch (e) {
      debugPrint("Firebase init failed: $e");
    }

    // Initialize Ads
    await MobileAds.instance.initialize();
    AdService().loadRewardedAd();

    // Initialize RevenueCat. Production keys are injected at build time
    // with --dart-define (see AppConstants.revenueCatAndroidKey etc.);
    // without them, purchases fall back to an invalid sandbox key and
    // every purchase API degrades to a no-op instead of crashing.
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      if (Platform.isAndroid) {
        final key = const String.fromEnvironment('REVENUECAT_ANDROID_KEY');
        if (key.isNotEmpty) {
          await Purchases.configure(PurchasesConfiguration(key));
        }
      } else if (Platform.isIOS) {
        final key = const String.fromEnvironment('REVENUECAT_IOS_KEY');
        if (key.isNotEmpty) {
          await Purchases.configure(PurchasesConfiguration(key));
        }
      }
    } catch (e) {
      debugPrint("RevenueCat init failed: $e");
    }
  }

  await AnalyticsService().logEvent(AnalyticsService.appLaunch);
  runApp(const PuzzleCardsApp());
}
