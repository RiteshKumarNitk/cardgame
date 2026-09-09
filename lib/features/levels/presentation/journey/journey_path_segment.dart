import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'journey_level_node.dart';

/// A short curved connector drawn between two consecutive level nodes on
/// the Journey Map, from [fromLevelId]'s wave position to [toLevelId]'s —
/// both computed independently via [journeyWavePosition], so this needs no
/// shared layout state with its neighbors.
///
/// "Warm Tactile Serenity": a soft **dashed** winding trail in a muted
/// sage tint, rather than a solid painted line.
class JourneyPathSegment extends StatelessWidget {
  const JourneyPathSegment({
    super.key,
    required this.fromLevelId,
    required this.toLevelId,
    required this.color,
  });

  final int fromLevelId;
  final int toLevelId;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: CustomPaint(
        size: Size.infinite,
        painter: _PathSegmentPainter(
          from: journeyWavePosition(fromLevelId),
          to: journeyWavePosition(toLevelId),
          color: color,
        ),
      ),
    );
  }
}

class _PathSegmentPainter extends CustomPainter {
  _PathSegmentPainter({
    required this.from,
    required this.to,
    required this.color,
  });

  final double from;
  final double to;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final usableHalfWidth = size.width / 2 - 40;
    final fromX = size.width / 2 + from * usableHalfWidth;
    final toX = size.width / 2 + to * usableHalfWidth;

    final path = Path()
      ..moveTo(fromX, 0)
      ..cubicTo(
        fromX,
        size.height * 0.55,
        toX,
        size.height * 0.45,
        toX,
        size.height,
      );

    // Walk the path and stamp short dashes so the trail reads as a soft
    // guide rather than a hard rail.
    const dash = 6.0;
    const gap = 6.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathSegmentPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.color != color;
}
