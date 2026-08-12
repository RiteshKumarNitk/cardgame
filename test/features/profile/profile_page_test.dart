// Verifies the Profile screen: shows the equipped-avatar page with the
// player's name and lifetime stats, and the edit-name dialog persists
// through the injected ProfileService.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:puzzle_cards/core/theme/app_theme.dart';
import 'package:puzzle_cards/features/profile/presentation/pages/profile_page.dart';
import 'package:puzzle_cards/game/wallet_cubit.dart';

import '../../helpers/fake_profile_service.dart';
import '../../helpers/fake_wallet_service.dart';

const _stats = ProfileStats(
  levelsCompleted: 5,
  totalLevels: 10,
  totalStars: 12,
  photosCollected: 2,
  bestStreak: 3,
);

Widget _wrap({
  required FakeProfileService profileService,
  Future<ProfileStats> Function()? loadStats,
}) {
  return BlocProvider<WalletCubit>(
    create: (_) => WalletCubit(FakeWalletService()),
    child: MaterialApp(
      theme: AppTheme.game,
      home: ProfilePage(
        profileService: profileService,
        loadStats: loadStats ?? () async => _stats,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows the player name and lifetime stats', (tester) async {
    final profileService = FakeProfileService('Ada');

    await tester.pumpWidget(_wrap(profileService: profileService));
    await tester.pump();
    await tester.pump();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('5/10'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Customize Avatar'), findsOneWidget);
  });

  testWidgets('shows a prompt when no name is set', (tester) async {
    await tester.pumpWidget(_wrap(profileService: FakeProfileService()));
    await tester.pump();
    await tester.pump();

    expect(find.text('Tap to set a name'), findsOneWidget);
  });

  testWidgets('editing the name persists through the profile service', (
    tester,
  ) async {
    final profileService = FakeProfileService('Ada');

    await tester.pumpWidget(_wrap(profileService: profileService));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField), 'Buffy');
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Buffy'), findsOneWidget);
    expect(profileService.name, 'Buffy');
  });
}
