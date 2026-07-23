// lib/features/audio_room/widget/particle_background.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Simplified themed particle overlay (Task 8).
/// Uses RepaintBoundary and reduces particle count to ~15 to optimize performance
/// and battery life on mobile devices.
class ParticleBackground extends StatefulWidget {
  final Color particleColor;
  
  const ParticleBackground({
    super.key,
    this.particleColor = const Color(0xFF00B89C), // AppColors.accent / Trust Teal
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final int _particleCount = 15; // Performance limit as per design doc

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    final rand = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_Particle(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        speedY: 0.1 + rand.nextDouble() * 0.2,
        speedX: -0.1 + rand.nextDouble() * 0.2,
        size: 20 + rand.nextDouble() * 40,
        opacity: 0.05 + rand.nextDouble() * 0.15,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Update particle positions
            for (var p in _particles) {
              p.y -= p.speedY * 0.005;
              p.x += p.speedX * 0.005;

              if (p.y < -0.2) p.y = 1.2;
              if (p.x < -0.2) p.x = 1.2;
              if (p.x > 1.2) p.x = -0.2;
            }

            return CustomPaint(
              painter: _ParticlePainter(
                particles: _particles,
                color: widget.particleColor,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  double x, y;
  final double speedX, speedY;
  final double size;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;

  _ParticlePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final center = Offset(p.x * size.width, p.y * size.height);
      final paint = Paint()
        ..color = color.withValues(alpha: p.opacity * 0.5)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(center, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
