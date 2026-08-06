import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_system/app_typography.dart';

/// A soft, semi-transparent playing card suit that drifts slowly across the
/// screen — for the premium casino-game atmosphere. Multiple instances at
/// different sizes, speeds, and vertical positions create a layered
/// parallax-like effect.
class FloatingSuit extends StatefulWidget {
  const FloatingSuit({
    super.key,
    required this.suit,
    this.size = 120,
    this.color = Colors.white,
    this.opacity = 0.05,
    this.initialX = 0,
    this.initialY = 0,
    this.driftDuration = const Duration(seconds: 30),
    this.driftDistance = 60,
  });

  /// The character to render (e.g. ♠, ♥, ♦, ♣).
  final String suit;

  /// Font size of the suit.
  final double size;

  /// Base tint of the suit (applied with [opacity]).
  final Color color;

  /// Opacity of the suit — keep low for a subtle atmospheric effect.
  final double opacity;

  /// Initial horizontal position (0 = left edge of parent).
  final double initialX;

  /// Initial vertical position (0 = top edge of parent).
  final double initialY;

  /// How long one full drift cycle takes (longer = slower = more serene).
  final Duration driftDuration;

  /// Pixels the suit drifts left and right from its [initialX].
  final double driftDistance;

  @override
  State<FloatingSuit> createState() => _FloatingSuitState();
}

class _FloatingSuitState extends State<FloatingSuit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _drift;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.driftDuration,
    )..repeat(reverse: true);

    // Randomize the starting position so suits don't all move in sync
    final random = math.Random();
    _controller.value = random.nextDouble();

    _drift = Tween<double>(
      begin: -widget.driftDistance,
      end: widget.driftDistance,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        return Positioned(
          left: widget.initialX + _drift.value,
          top: widget.initialY,
          child: IgnorePointer(
            child: Opacity(
              opacity: widget.opacity,
              child: Text(
                widget.suit,
                style: AppTypography.textTheme().displayLarge?.copyWith(
                  fontSize: widget.size,
                  color: widget.color,
                  height: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
