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
    this.data, {
    super.key,
    this.style,
    this.outlineColor = const Color(0x33000000),
    this.outlineWidth = 2.0,
    this.textAlign,
  });

  final String data;
  final TextStyle? style;
  final Color outlineColor;
  final double outlineWidth;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle();
    
    // Replace the heavy stroke with a soft double-shadow for a clean bubble aesthetic
    return Text(
      data,
      textAlign: textAlign,
      style: baseStyle.copyWith(
        shadows: [
          Shadow(
            color: outlineColor,
            offset: const Offset(0, 1.5),
            blurRadius: outlineWidth,
          ),
          Shadow(
            color: outlineColor,
            offset: const Offset(0, 3),
            blurRadius: outlineWidth * 2,
          ),
        ],
      ),
    );
  }
}
