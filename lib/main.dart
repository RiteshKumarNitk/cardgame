import 'package:flutter/material.dart';

import 'core/app/puzzle_cards_app.dart';
import 'services/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const PuzzleCardsApp());
}
