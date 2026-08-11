import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';
import '../../services/audio_service.dart';

class CoinFlightOverlay {
  /// Spawns a burst of flying coins from [startKey] to [endKey].
  static void show({
    required BuildContext context,
    GlobalKey? startKey,
    GlobalKey? endKey,
    int count = 10,
    Offset? startOffset,
    Offset? endOffset,
  }) {
    Offset start = startOffset ?? Offset.zero;
    if (startKey != null && startKey.currentContext != null) {
      final box = startKey.currentContext!.findRenderObject() as RenderBox;
      start = box.localToGlobal(box.size.center(Offset.zero));
    } else if (startOffset == null) {
      final size = MediaQuery.of(context).size;
      start = Offset(size.width / 2, size.height / 2);
    }

    Offset end = endOffset ?? Offset.zero;
    if (endKey != null && endKey.currentContext != null) {
      final box = endKey.currentContext!.findRenderObject() as RenderBox;
      end = box.localToGlobal(box.size.center(Offset.zero));
    } else if (endOffset == null) {
      end = const Offset(40, 40); // fallback top left
    }

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _CoinFlightWidget(
        start: start,
        end: end,
        count: count,
        onComplete: () {
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _CoinFlightWidget extends StatefulWidget {
  const _CoinFlightWidget({
    required this.start,
    required this.end,
    required this.count,
    required this.onComplete,
  });

  final Offset start;
  final Offset end;
  final int count;
  final VoidCallback onComplete;

  @override
  State<_CoinFlightWidget> createState() => _CoinFlightWidgetState();
}

class _CoinFlightWidgetState extends State<_CoinFlightWidget> with TickerProviderStateMixin {
  late final List<_CoinAnimation> _coins;
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    final random = math.Random();

    _coins = List.generate(widget.count, (index) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600 + random.nextInt(400)),
      );

      final delay = random.nextInt(300);
      
      // Explosion phase offset
      final explodeAngle = random.nextDouble() * math.pi * 2;
      final explodeDist = 40.0 + random.nextDouble() * 80.0;
      final explodeOffset = Offset(
        math.cos(explodeAngle) * explodeDist,
        math.sin(explodeAngle) * explodeDist,
      );

      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) {
          controller.forward();
          if (index % 3 == 0) AudioService().playTick(); // tick sounds during flight
        }
      });

      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _completedCount++;
          AudioService().playCoinReward(); // play a small coin sound
          if (_completedCount == widget.count) {
            widget.onComplete();
          }
        }
      });

      return _CoinAnimation(
        controller: controller,
        start: widget.start,
        explodeOffset: explodeOffset,
        end: widget.end,
      );
    });
  }

  @override
  void dispose() {
    for (var c in _coins) {
      c.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _coins.map((coin) {
        return AnimatedBuilder(
          animation: coin.controller,
          builder: (context, child) {
            if (!coin.controller.isAnimating && coin.controller.value == 0) {
              return const SizedBox.shrink();
            }
            if (coin.controller.isCompleted) {
              return const SizedBox.shrink();
            }

            final t = coin.controller.value;

            // Path: Start -> Explode (t: 0-0.3) -> End (t: 0.3-1.0)
            Offset currentPos;
            if (t < 0.3) {
              final explodeT = Curves.easeOut.transform(t / 0.3);
              currentPos = Offset.lerp(coin.start, coin.start + coin.explodeOffset, explodeT)!;
            } else {
              final flightT = Curves.easeInOut.transform((t - 0.3) / 0.7);
              // Add a bezier curve to the flight
              final p0 = coin.start + coin.explodeOffset;
              final p1 = Offset(p0.dx + (coin.end.dx - p0.dx) / 2, p0.dy - 100); // control point
              final p2 = coin.end;
              currentPos = _bezier(p0, p1, p2, flightT);
            }

            final scale = t < 0.1 ? (t / 0.1) : (t > 0.8 ? (1.0 - t) / 0.2 : 1.0);

            return Positioned(
              left: currentPos.dx - 15,
              top: currentPos.dy - 15,
              child: Transform.scale(
                scale: scale,
                child: const Icon(
                  Icons.monetization_on_rounded,
                  color: AppColors.accent,
                  size: 30,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Offset _bezier(Offset p0, Offset p1, Offset p2, double t) {
    final x = math.pow(1 - t, 2) * p0.dx + 2 * (1 - t) * t * p1.dx + math.pow(t, 2) * p2.dx;
    final y = math.pow(1 - t, 2) * p0.dy + 2 * (1 - t) * t * p1.dy + math.pow(t, 2) * p2.dy;
    return Offset(x, y);
  }
}

class _CoinAnimation {
  _CoinAnimation({
    required this.controller,
    required this.start,
    required this.explodeOffset,
    required this.end,
  });

  final AnimationController controller;
  final Offset start;
  final Offset explodeOffset;
  final Offset end;
}
