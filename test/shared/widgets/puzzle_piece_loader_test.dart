// Smoke test for the branded loader: renders the six tiles and pumps
// through several full animation loops. No timers are involved (pure
// AnimationController), so nothing leaks at teardown.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/shared/widgets/puzzle_piece_loader.dart';

void main() {
  testWidgets('renders six puzzle tiles and loops without errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: PuzzlePieceLoader())),
    );

    expect(find.byType(PuzzlePieceLoader), findsOneWidget);
    expect(find.byIcon(Icons.extension_rounded), findsNWidgets(6));

    // Advance through several complete loops (duration is 2600ms).
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump(const Duration(milliseconds: 2600));

    expect(find.byIcon(Icons.extension_rounded), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });
}
