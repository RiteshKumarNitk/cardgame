import 'package:flutter/animation.dart';

/// Durations and curves for every interaction animation — press feedback,
/// entrance pops, page transitions. Widgets reference these instead of
/// inlining raw millisecond values.
abstract final class AppAnimations {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration pageTransition = Duration(milliseconds: 320);

  /// Continuous idle loops (logo bob, CTA glow) — slower and gentler than
  /// any interaction animation so they read as "alive", not distracting.
  static const Duration idleFloat = Duration(milliseconds: 2600);
  static const Duration glowPulse = Duration(milliseconds: 1800);

  static const Curve pressCurve = Curves.easeOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve entranceCurve = Curves.easeOutBack;
  static const Curve fadeCurve = Curves.easeIn;
  static const Curve pageCurve = Curves.easeOut;
  static const Curve idleCurve = Curves.easeInOut;

  static const double pressedScale = 0.94;
}
