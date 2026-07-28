import 'package:flutter/material.dart';

import '../../core/design_system/app_animations.dart';
import '../../core/design_system/app_radius.dart';

/// Wraps [child] in a soft, continuously breathing glow — draws the eye to
/// the primary call-to-action (the Play button) without any user input.
class PulsingGlow extends StatefulWidget {
  const PulsingGlow({
    super.key,
    required this.child,
    required this.color,
    this.borderRadius,
    this.minOpacity = 0.25,
    this.maxOpacity = 0.6,
    this.blurRadius = 28,
  });

  final Widget child;
  final Color color;
  final BorderRadius? borderRadius;
  final double minOpacity;
  final double maxOpacity;
  final double blurRadius;

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: AppAnimations.glowPulse)
          ..repeat(reverse: true);
    _opacity = Tween<double>(begin: widget.minOpacity, end: widget.maxOpacity)
        .animate(
          CurvedAnimation(parent: _controller, curve: AppAnimations.idleCurve),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      child: widget.child,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? AppRadius.pillRadius,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _opacity.value),
              blurRadius: widget.blurRadius,
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
