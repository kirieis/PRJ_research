// lib/features/audio_room/widget/ripple_painter.dart
// ============================================================
// Project LUCY — Audio Ripple Effect (CustomPainter)
// Draws expanding concentric circles around an avatar to
// indicate active speaking. Driven by AnimationController.
// ============================================================

import 'package:flutter/material.dart';

/// CustomPainter that draws 3 concentric ripple rings.
///
/// Each ring expands outward from the center with decreasing opacity,
/// creating a "sound wave" effect around the speaker's avatar.
///
/// The [progress] value (0.0 → 1.0) from an [AnimationController]
/// drives the ring expansion. The animation should repeat continuously
/// while the user is speaking.
///
/// Visual design:
/// ```
///   ╭── ring 3 (opacity 0.08) ──╮
///   │  ╭── ring 2 (0.15) ──╮   │
///   │  │  ╭── ring 1 (0.25)│   │
///   │  │  │   [Avatar]     │   │
///   │  │  ╰────────────────╯   │
///   │  ╰───────────────────────╯
///   ╰──────────────────────────╯
/// ```
class RipplePainter extends CustomPainter {
  /// Animation progress (0.0 → 1.0).
  final double progress;

  /// Base color for the ripple rings (typically [AppColors.accent]).
  final Color color;

  /// Number of concentric rings to draw.
  final int ringCount;

  RipplePainter({
    required this.progress,
    required this.color,
    this.ringCount = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < ringCount; i++) {
      // Stagger each ring's progress so they appear sequentially.
      // Ring 0 leads, ring 1 follows, ring 2 trails.
      final staggeredProgress = (progress - (i * 0.15)).clamp(0.0, 1.0);

      // Ring expands from 60% to 120% of the avatar radius.
      final radius = maxRadius * (0.6 + staggeredProgress * 0.6);

      // Opacity decreases as the ring expands and for outer rings.
      final baseOpacity = 0.25 - (i * 0.08);
      final opacity = (baseOpacity * (1.0 - staggeredProgress)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 - (i * 0.5); // Thinner outer rings

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
