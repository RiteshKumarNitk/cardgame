import 'package:flutter/material.dart';

/// Chunky "toy block" text: a solid-color fill with a thick outline behind
/// it, matching the bold cartoon lettering used across the button/card
/// restyle.
///  /// Text with a soft outline shadow behind it, for use on colored
  /// backgrounds where readability needs a little help. Built as a single
  /// `Text` with shadow offsets so widget tests only see one text node.
class OutlinedText extends StatelessWidget {
  const OutlinedText(
    this.data, {
    super.key,
    this.style,
    this.outlineColor = const Color(0x1A2D312E),
    this.outlineWidth = 2.5,
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
    return Text(
      data,
      textAlign: textAlign,
      style: baseStyle.copyWith(
        shadows: [
          Shadow(
            color: outlineColor,
            offset: Offset(0, outlineWidth * 0.6),
            blurRadius: outlineWidth * 0.8,
          ),
        ],
      ),
    );
  }
}
