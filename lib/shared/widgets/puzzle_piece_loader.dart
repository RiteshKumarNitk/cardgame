import 'package:flutter/material.dart';

import '../../core/design_system/app_animations.dart';
import '../../core/design_system/app_colors.dart';

/// Branded loading animation: six puzzle tiles fly in one-by-one with an
/// elastic pop, snap together into a 2×3 grid, pulse with a glow + shine
/// sweep, then scatter out — looping forever.
///
/// Pure `AnimationController` with `Interval` curves — no timers, so it is
/// widget-test friendly (tests just avoid `pumpAndSettle`).
class PuzzlePieceLoader extends StatefulWidget {
  const PuzzlePieceLoader({
    super.key,
    this.pieceSize = 30,
    this.gap = 8,
    this.duration = AppAnimations.idleFloat,
  });

  final double pieceSize;
  final double gap;
  final Duration duration;

  @override
  State<PuzzlePieceLoader> createState() => _PuzzlePieceLoaderState();
}

class _PuzzlePieceLoaderState extends State<PuzzlePieceLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Six-piece palette — one tile per brand color.
  static const List<List<Color>> _palette = [
    [Color(0xFFF44336), Color(0xFFB71C1C)], // red
    [Color(0xFFFFC107), Color(0xFFF57F17)], // gold
    [Color(0xFF4CAF50), Color(0xFF1B5E20)], // green
    [Color(0xFF7B1FA2), Color(0xFF4A148C)], // royal purple
    [Color(0xFF607D8B), Color(0xFF263238)], // blue grey
    [Color(0xFFFF9800), Color(0xFFE65100)], // orange
  ];

  /// Direction each tile travels while flying in (from the grid center).
  static const List<Offset> _approach = [
    Offset(-1.1, -1.0),
    Offset(1.1, -1.0),
    Offset(1.2, 0.3),
    Offset(-1.2, 0.4),
    Offset(0.0, 1.2),
    Offset(1.1, 1.0),
  ];

  late final double _cols = 3;
  late final double _rows = 2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.pieceSize;
    final gap = widget.gap;
    final gridWidth = _cols * size + (_cols - 1) * gap;
    final gridHeight = _rows * size + (_rows - 1) * gap;

    return SizedBox(
      width: gridWidth + size, // headroom for the fly-in overshoot
      height: gridHeight + size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _buildGlow(t, gridWidth, gridHeight),
              ClipRect(
                child: SizedBox(
                  width: gridWidth,
                  height: gridHeight,
                  child: Stack(
                    children: [
                      for (var i = 0; i < 6; i++)
                        _buildPiece(i, t, gridWidth, gridHeight),
                      _buildShine(t, gridWidth, gridHeight),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Soft brand-colored glow that swells while the grid is assembled.
  Widget _buildGlow(double t, double width, double height) {
    final pulse = Interval(0.5, 0.76, curve: Curves.easeInOut).transform(t);
    final opacity = 0.55 * pulse.clamp(0.0, 1.0);

    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: width + widget.pieceSize * 1.4,
          height: height + widget.pieceSize * 1.4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.55),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A diagonal shine sweeping across the assembled tiles.
  Widget _buildShine(double t, double width, double height) {
    final sweep = Interval(0.52, 0.74, curve: Curves.easeInOut).transform(t);
    final x = -60.0 + sweep * (width + 120.0);
    final opacity = (0.9 * (sweep < 0.5 ? sweep * 2 : (1 - sweep) * 2))
        .clamp(0.0, 1.0);

    return Positioned(
      left: x,
      top: -20,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Transform.rotate(
            angle: 0.35,
            child: Container(
              width: 46,
              height: height + 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0x66FFFFFF),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPiece(int i, double t, double width, double height) {
    final size = widget.pieceSize;
    final gap = widget.gap;

    // Staggered entrance window per tile.
    final entranceStart = 0.06 + i * 0.045;
    final entrance = Interval(
      entranceStart,
      entranceStart + 0.22,
      curve: Curves.elasticOut,
    ).transform(t);
    final appear = Interval(
      entranceStart,
      entranceStart + 0.08,
      curve: Curves.easeOut,
    ).transform(t);

    // Row-wise scatter exit.
    final exit = Interval(
      0.80 + (i ~/ 3) * 0.06,
      0.96,
      curve: Curves.easeIn,
    ).transform(t);

    final col = (i % 3).toDouble();
    final row = (i ~/ 3).toDouble();
    final left = col * (size + gap);
    final top = row * (size + gap);

    final approach = _approach[i] * (size * 1.15);
    final offset = Offset.lerp(approach, Offset.zero, entrance)!;
    final exitDrift = Offset(0, 14) * exit;

    final scale = (0.001 + entrance) * (1 - 0.55 * exit);
    final opacity = appear * (1 - exit);

    return Positioned(
      left: left,
      top: top,
      child: Transform.translate(
        offset: offset + exitDrift,
        child: Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: _tile(i)),
        ),
      ),
    );
  }

  Widget _tile(int i) {
    final colors = _palette[i % _palette.length];
    final size = widget.pieceSize;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(color: Colors.white, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.extension_rounded,
          size: size * 0.52,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
