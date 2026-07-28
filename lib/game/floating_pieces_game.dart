import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';

import 'components/floating_puzzle_piece.dart';

/// Minimal [FlameGame] that renders a handful of slowly drifting puzzle
/// piece silhouettes behind the splash content. Purely decorative — no
/// gameplay, no scoring, no input.
class FloatingPiecesGame extends FlameGame {
  FloatingPiecesGame({required this.pieceColors, this.pieceCount = 10});

  final List<Color> pieceColors;
  final int pieceCount;
  final Random _random = Random();

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (var i = 0; i < pieceCount; i++) {
      add(_createPiece());
    }
  }

  FloatingPuzzlePiece _createPiece() {
    final pieceSize = 20.0 + _random.nextDouble() * 26;
    final color = pieceColors[_random.nextInt(pieceColors.length)];
    return FloatingPuzzlePiece(
      position: Vector2(_random.nextDouble() * size.x, _random.nextDouble() * size.y),
      size: Vector2.all(pieceSize),
      color: color.withValues(alpha: 0.10 + _random.nextDouble() * 0.12),
      velocity: Vector2(
        (_random.nextDouble() - 0.5) * 8,
        -(4 + _random.nextDouble() * 10),
      ),
      rotationSpeed: (_random.nextDouble() - 0.5) * 0.6,
    );
  }
}
