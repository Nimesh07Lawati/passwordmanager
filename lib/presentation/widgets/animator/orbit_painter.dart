import 'dart:math' as math;
import 'package:flutter/material.dart';

class OrbitPainter extends CustomPainter {
  const OrbitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1565C0).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final dotPaint = Paint()
      ..color = const Color(0xFF1565C0).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    canvas.drawCircle(center, radius, paint);

    // Small dots on the ring
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * math.pi;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
