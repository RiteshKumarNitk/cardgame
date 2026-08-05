import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'core/app/puzzle_cards_app.dart';
import 'services/ad_service.dart';
import 'services/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await HiveService.init();

  // Initialize Ads
  await MobileAds.instance.initialize();
  AdService().loadRewardedAd();

  // Initialize RevenueCat (Using a test API key; replace before launch)
  await Purchases.setLogLevel(LogLevel.debug);
  // Example dummy key for Android
  if (Platform.isAndroid) {
    await Purchases.configure(PurchasesConfiguration("goog_test_api_key_replace_me"));
  }

  runApp(const PuzzleCardsApp());
}
