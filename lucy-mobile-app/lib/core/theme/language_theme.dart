// lib/core/theme/language_theme.dart
// ============================================================
// Project LUCY — Multilingual & Cultural Design System
//
// Provides theme configurations, certificate mapping (CEFR/JLPT/HSK),
// and animated background painters for English, Japanese, Chinese.
// Matches Web client theme architecture.
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Language configuration for EN, JA, ZH.
class LanguageConfig {
  final String code;
  final String label;
  final String nativeLabel;
  final String flag;
  final String certificateName;
  final List<String> levels;
  final Color accentColor;
  final Color secondaryColor;
  final String heroImage;

  const LanguageConfig({
    required this.code,
    required this.label,
    required this.nativeLabel,
    required this.flag,
    required this.certificateName,
    required this.levels,
    required this.accentColor,
    required this.secondaryColor,
    required this.heroImage,
  });

  static const Map<String, LanguageConfig> configs = {
    'en': LanguageConfig(
      code: 'en',
      label: 'ENGLISH',
      nativeLabel: 'English',
      flag: '🇬🇧',
      certificateName: 'CEFR Certificate',
      levels: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'],
      accentColor: AppColors.primary,
      secondaryColor: AppColors.accent,
      heroImage: 'https://picsum.photos/seed/english-studio/600/400',
    ),
    'ja': LanguageConfig(
      code: 'ja',
      label: 'JAPANESE',
      nativeLabel: '日本語',
      flag: '🇯🇵',
      certificateName: 'JLPT Certificate',
      levels: ['N5', 'N4', 'N3', 'N2', 'N1'],
      accentColor: Color(0xFFDB8A9C), // Sakura Pink
      secondaryColor: Color(0xFFFFB7C5),
      heroImage: 'https://picsum.photos/seed/kyoto-garden/600/400',
    ),
    'zh': LanguageConfig(
      code: 'zh',
      label: 'CHINESE',
      nativeLabel: '中文',
      flag: '🇨🇳',
      certificateName: 'HSK Certificate',
      levels: ['HSK 1', 'HSK 2', 'HSK 3', 'HSK 4', 'HSK 5', 'HSK 6'],
      accentColor: Color(0xFFD4AF37), // Imperial Gold
      secondaryColor: Color(0xFF8B0000), // Crimson Red
      heroImage: 'https://picsum.photos/seed/forbidden-city/600/400',
    ),
  };

  static LanguageConfig get(String code) => configs[code] ?? configs['en']!;
}

// ============================================================
// ANIMATED BACKGROUND PAINTERS (Sakura & Lanterns)
// ============================================================

/// Sakura falling petals painter for Japanese (JA) theme.
class SakuraBackgroundPainter extends CustomPainter {
  final double animationValue;
  final List<_SakuraPetal> _petals;

  SakuraBackgroundPainter({
    required this.animationValue,
  }) : _petals = _generatePetals();

  static List<_SakuraPetal> _generatePetals() {
    final rand = math.Random(12345);
    return List.generate(40, (i) {
      return _SakuraPetal(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        size: rand.nextDouble() * 8 + 6,
        speedY: rand.nextDouble() * 0.4 + 0.3,
        speedX: rand.nextDouble() * 0.2 - 0.1,
        rotation: rand.nextDouble() * math.pi * 2,
        opacity: rand.nextDouble() * 0.5 + 0.3,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _petals) {
      final y = (p.y + animationValue * p.speedY) % 1.0 * size.height;
      final x = (p.x +
              math.sin(animationValue * 3 + p.y * 10) * 0.05 +
              p.speedX * animationValue) %
          1.0 *
          size.width;

      final paint = Paint()
        ..color = const Color(0xFFFFB7C5).withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + animationValue);

      // Heart-shaped petal
      final path = Path();
      final r = p.size;
      path.moveTo(0, 0);
      path.cubicTo(-r * 0.5, -r * 0.5, -r * 0.2, -r * 1.0, 0, -r * 0.85);
      path.cubicTo(r * 0.2, -r * 1.0, r * 0.5, -r * 0.5, 0, 0);
      canvas.drawPath(path, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant SakuraBackgroundPainter oldDelegate) => true;
}

class _SakuraPetal {
  final double x;
  final double y;
  final double size;
  final double speedY;
  final double speedX;
  final double rotation;
  final double opacity;

  _SakuraPetal({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.rotation,
    required this.opacity,
  });
}

/// Red lanterns floating painter for Chinese (ZH) theme.
class LanternBackgroundPainter extends CustomPainter {
  final double animationValue;
  final List<_Lantern> _lanterns;

  LanternBackgroundPainter({
    required this.animationValue,
  }) : _lanterns = _generateLanterns();

  static List<_Lantern> _generateLanterns() {
    final rand = math.Random(67890);
    return List.generate(15, (i) {
      return _Lantern(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        radius: rand.nextDouble() * 6 + 8,
        speedY: rand.nextDouble() * 0.2 + 0.1,
        opacity: rand.nextDouble() * 0.4 + 0.2,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final l in _lanterns) {
      final y = (1.0 - ((l.y + animationValue * l.speedY) % 1.0)) * size.height;
      final x =
          (l.x + math.sin(animationValue * 2 + l.y * 5) * 0.03) * size.width;

      // Glow paint
      final glowPaint = Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: l.opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(x, y), l.radius * 1.5, glowPaint);

      // Lantern body (red oval)
      final bodyPaint = Paint()
        ..color = const Color(0xFF8B0000).withValues(alpha: l.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(x, y), width: l.radius * 1.6, height: l.radius * 2),
        bodyPaint,
      );

      // Gold accent lines
      final goldPaint = Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: l.opacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(x - l.radius * 0.6, y - l.radius),
        Offset(x + l.radius * 0.6, y - l.radius),
        goldPaint,
      );
      canvas.drawLine(
        Offset(x - l.radius * 0.6, y + l.radius),
        Offset(x + l.radius * 0.6, y + l.radius),
        goldPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LanternBackgroundPainter oldDelegate) => true;
}

class _Lantern {
  final double x;
  final double y;
  final double radius;
  final double speedY;
  final double opacity;

  _Lantern({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedY,
    required this.opacity,
  });
}
