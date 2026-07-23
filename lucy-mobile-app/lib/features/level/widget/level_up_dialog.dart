// lib/features/level/widget/level_up_dialog.dart
// ============================================================
// Project LUCY — Level Up Celebration Dialog
//
// Full-screen celebration overlay with:
//   - Confetti-style particle animation
//   - Level number count-up
//   - New CEFR badge reveal
//   - "Continue" button
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

/// Full-screen level-up celebration dialog.
///
/// Shows a dramatic animation when the user levels up.
/// Call this as a dialog overlay:
/// ```dart
/// showDialog(
///   context: context,
///   barrierDismissible: false,
///   builder: (_) => LevelUpDialog(
///     newLevel: 3,
///     cefrLevel: 'B1',
///     levelTitle: 'Opinion & Discussion',
///     onContinue: () => Navigator.of(context).pop(),
///   ),
/// );
/// ```
class LevelUpDialog extends StatefulWidget {
  final int newLevel;
  final String cefrLevel;
  final String levelTitle;
  final VoidCallback onContinue;

  const LevelUpDialog({
    super.key,
    required this.newLevel,
    required this.cefrLevel,
    required this.levelTitle,
    required this.onContinue,
  });

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _scaleCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _particleCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    // Sequence: scale → fade in details → particles
    _scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _particleCtrl.repeat();
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: Stack(
        children: [
          // Particle effects
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ConfettiPainter(
                  progress: _particleCtrl.value,
                ),
              );
            },
          ),

          // Main content
          Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Star burst emoji
                  const Text(
                    '⭐',
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),

                  // LEVEL UP text
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: AppColors.primaryGradient,
                    ).createShader(bounds),
                    child: const Text(
                      'LEVEL UP!',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // New level badge
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.primaryGradient,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Level ${widget.newLevel}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.cefrLevel,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Level title
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Text(
                      widget.levelTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Continue button
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        widget.onContinue();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Tiếp tục 🚀',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple confetti particle painter.
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final _random = math.Random(42);

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const particleCount = 50;
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.secondary,
      AppColors.warning,
      Colors.white,
    ];

    for (int i = 0; i < particleCount; i++) {
      final seed = _random.nextDouble();
      final x = seed * size.width;
      final startY = -20.0 + (seed * 100);
      final endY = size.height + 20;
      final y = startY + (endY - startY) * ((progress + seed) % 1.0);

      final color = colors[i % colors.length]
          .withValues(alpha: (1.0 - (y / size.height)).clamp(0.0, 0.8));
      final particleSize = 3.0 + seed * 5.0;

      final paint = Paint()..color = color;

      if (i % 3 == 0) {
        // Circle
        canvas.drawCircle(Offset(x, y), particleSize / 2, paint);
      } else {
        // Rectangle
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: particleSize,
            height: particleSize * 0.6,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
