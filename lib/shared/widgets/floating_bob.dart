import 'package:flutter/material.dart';

import '../../core/design_system/app_animations.dart';

/// Wraps [child] in a gentle, continuous up/down float — makes hero
/// elements (the logo, a featured card icon) read as "alive" while idle,
/// instead of a static image.
class FloatingBob extends StatefulWidget {
  const FloatingBob({
    super.key,
    required this.child,
    this.range = 8,
    this.duration = AppAnimations.idleFloat,
  });

  final Widget child;
  final double range;
  final Duration duration;

  @override
  State<FloatingBob> createState() => _FloatingBobState();
}

class _FloatingBobState extends State<FloatingBob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _offset = Tween<double>(begin: -widget.range, end: widget.range).animate(
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
      animation: _offset,
      child: widget.child,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, _offset.value), child: child),
    );
  }
}
