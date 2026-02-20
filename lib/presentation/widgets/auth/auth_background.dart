import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:passwordmanager/presentation/widgets/animator/orbit_painter.dart';

class AuthBackground extends StatelessWidget {
  final Animation<double> shieldRotate;
  final bool isDark;

  const AuthBackground({
    super.key,
    required this.shieldRotate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ambient background glows
        Positioned(
          top: -100,
          left: -60,
          child: _Glow(
            color: const Color(0xFF1565C0).withOpacity(isDark ? 0.30 : 0.12),
            size: 320,
          ),
        ),
        Positioned(
          bottom: -80,
          right: -60,
          child: _Glow(
            color: const Color(0xFF6A1B9A).withOpacity(isDark ? 0.22 : 0.09),
            size: 260,
          ),
        ),

        // Orbiting ring decoration
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: shieldRotate,
              builder: (_, child) {
                return Transform.rotate(
                  angle: shieldRotate.value,
                  child: child,
                );
              },
              child: const SizedBox(
                width: 150,
                height: 150,
                child: CustomPaint(painter: OrbitPainter()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Ambient Glow
class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}
