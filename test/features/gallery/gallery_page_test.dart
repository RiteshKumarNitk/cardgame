// Verifies the Gallery screen's back button never dead-ends: the page is
// reached via goNamed (which replaces the navigation stack), so when there
// is nothing to pop the arrow must fall back to navigating Home itself.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import 'package:puzzle_cards/core/constants/app_constants.dart';
import 'package:puzzle_cards/core/router/route_paths.dart';
import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/gallery/presentation/pages/gallery_page.dart';
import 'package:puzzle_cards/features/levels/data/models/level_model.dart';

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // GalleryPage builds its own Hive-backed LevelService internally, so
    // initialize Hive against a throwaway temp dir (same approach as
    // widget_test.dart).
    hiveDir = Directory.systemTemp.createTempSync('hive_gallery_test_');
    Hive.init(hiveDir.path);
    Hive.registerAdapter(LevelModelAdapter());
    await Hive.openBox<LevelModel>(AppConstants.levelsBoxName);
  });

  tearDownAll(() {
    try {
      Hive.close();
    } catch (_) {}
    try {
      hiveDir.deleteSync(recursive: true);
    } on FileSystemException {
      // File still locked by Hive - harmless.
    }
  });

  testWidgets('back button navigates home when nothing to pop', (
    tester,
  ) async {
    // Mirrors production: Gallery is reached via goNamed (stack replaced),
    // so tapping back must not throw "There is nothing to pop".
    final router = GoRouter(
      initialLocation: RoutePaths.gallery,
      routes: [
        GoRoute(
          path: RoutePaths.gallery,
          name: RouteNames.gallery,
          pageBuilder: (context, state) => const MaterialPage(
            child: GalleryPage(),
          ),
        ),
        GoRoute(
          path: RoutePaths.home,
          name: RouteNames.home,
          pageBuilder: (context, state) => const MaterialPage(
            child: Scaffold(body: Center(child: Text('Home Page'))),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.game, routerConfig: router),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(GalleryPage), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(GalleryPage), findsNothing);
    expect(find.text('Home Page'), findsOneWidget);
  });
}