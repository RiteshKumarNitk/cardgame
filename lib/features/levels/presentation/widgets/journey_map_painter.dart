import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';

/// A custom painter that draws a curved path (journey map) connecting
/// the different level nodes, similar to Candy Crush or Royal Match.
class JourneyMapPainter extends CustomPainter {
  const JourneyMapPainter({
    required this.nodePositions,
    required this.currentLevelIndex,
  });

  /// The positions of each node on the screen/scroll area.
  final List<Offset> nodePositions;
  
  /// The index of the highest unlocked level to determine path coloring.
  final int currentLevelIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.isEmpty) return;

    final paintCompleted = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final paintLocked = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Draw curved segments between nodes
    for (int i = 0; i < nodePositions.length - 1; i++) {
      final start = nodePositions[i];
      final end = nodePositions[i + 1];

      final isCompleted = i < currentLevelIndex;
      final paint = isCompleted ? paintCompleted : paintLocked;

      final path = Path();
      path.moveTo(start.dx, start.dy);
      
      // Create a gentle bezier curve instead of a straight line
      final controlPoint1 = Offset(start.dx, start.dy + (end.dy - start.dy) / 2);
      final controlPoint2 = Offset(end.dx, end.dy - (end.dy - start.dy) / 2);
      
      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        end.dx, end.dy,
      );

      canvas.drawPath(path, paint);
      
      // Draw inner dashed line for premium feel
      final paintDashed = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
        
      canvas.drawPath(path, paintDashed);
    }
  }

  @override
  bool shouldRepaint(covariant JourneyMapPainter oldDelegate) {
    return oldDelegate.currentLevelIndex != currentLevelIndex ||
           oldDelegate.nodePositions != nodePositions;
  }
}
