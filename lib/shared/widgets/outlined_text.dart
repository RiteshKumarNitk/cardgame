import 'package:flutter/material.dart';

import '../../core/design_system/app_colors.dart';

/// Chunky "toy block" text: a solid-color fill with a thick outline behind
/// it, matching the bold cartoon lettering used across the button/card
/// restyle.
///
/// Built as a single `Text` with a ring of hard-edged (zero-blur)
/// `Shadow`s around it, rather than stacking two `Text` widgets — a second
/// widget carrying the same string would double every `find.text(...)`
/// match in existing widget tests (`findsOneWidget`, `tester.tap`, etc.).
class OutlinedText extends StatelessWidget {
  const OutlinedText(
    this.text, {
    super.key,
    required this.style,
    this.outlineColor = AppColors.outline,
    this.outlineWidth = 2,
    this.textAlign,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final Color outlineColor;
  final double outlineWidth;
  final TextAlign? textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      style: style?.copyWith(shadows: _outlineRing()),
    );
  }

  List<Shadow> _outlineRing() => [
    for (final dx in [-1.0, 0.0, 1.0])
      for (final dy in [-1.0, 0.0, 1.0])
        if (dx != 0 || dy != 0)
          Shadow(
            color: outlineColor,
            offset: Offset(dx * outlineWidth, dy * outlineWidth),
          ),
  ];
}
