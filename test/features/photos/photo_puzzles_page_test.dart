// Verifies the Photo Puzzles grid: it lists every photo from the injected
// loader with its best-star badge, shows the how-to-add empty state when
// the manifest is empty, and tapping a card opens that photo's puzzle.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/router/route_paths.dart';
import 'package:puzzle_cards/game/wallet_cubit.dart';
import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/photos/domain/photo_puzzle.dart';
import 'package:puzzle_cards/features/photos/presentation/pages/photo_puzzle_page.dart';
import 'package:puzzle_cards/features/photos/presentation/pages/photo_puzzles_page.dart';

import '../../helpers/fake_photo_progress_service.dart';
import '../../helpers/fake_wallet_service.dart';

const _photos = [
  PhotoPuzzle(
    id: 'beach',
    title: 'Beach',
    imagePath: 'assets/images/photos/beach.jpg',
  ),
  PhotoPuzzle(
    id: 'sunset',
    title: 'Sunset',
    imageUrl: 'https://example.com/sunset.jpg',
  ),
];

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders a card per photo with its best-star badge', (
    tester,
  ) async {
    final progress = FakePhotoProgressService()..bestStars['beach'] = 3;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.game,
        home: PhotoPuzzlesPage(
          loadPhotos: () async => _photos,
          progressService: progress,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Photo Puzzles'), findsOneWidget);
    expect(find.text('Beach'), findsOneWidget);
    expect(find.text('Sunset'), findsOneWidget);
    // Best-star badge: 3 for the solved photo, 'New' for the unsolved one.
    expect(find.text('3'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
  });

  testWidgets('shows the how-to-add empty state with no photos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.game,
        home: PhotoPuzzlesPage(
          loadPhotos: () async => const [],
          progressService: FakePhotoProgressService(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Add your first photo'), findsOneWidget);
    expect(find.textContaining('manifest.json'), findsOneWidget);
  });

  testWidgets('tapping a card opens its photo puzzle', (tester) async {
    final router = GoRouter(
      initialLocation: RoutePaths.photoPuzzles,
      routes: [
        GoRoute(
          path: RoutePaths.photoPuzzles,
          name: RouteNames.photoPuzzles,
          pageBuilder: (context, state) => MaterialPage(
            child: PhotoPuzzlesPage(
              loadPhotos: () async => _photos,
              progressService: FakePhotoProgressService(),
            ),
          ),
        ),
        GoRoute(
          path: RoutePaths.photoPuzzle,
          name: RouteNames.photoPuzzle,
          pageBuilder: (context, state) => MaterialPage(
            child: PhotoPuzzlePage(
              photo: state.extra as PhotoPuzzle?,
              progressService: FakePhotoProgressService(),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      BlocProvider<WalletCubit>(
        create: (_) => WalletCubit(FakeWalletService()),
        child: MaterialApp.router(theme: AppTheme.game, routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.text('Beach'));
    await tester.pump();
    await tester.tap(find.text('Beach'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PhotoPuzzlePage), findsOneWidget);
    expect(find.text('Beach'), findsWidgets);

    // Unmount so the page-created cubit (1s timer) is disposed.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
