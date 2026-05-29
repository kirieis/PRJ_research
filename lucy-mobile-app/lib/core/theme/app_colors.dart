// lib/core/theme/app_colors.dart
// ============================================================
// Project LUCY — Brand Color Palette
// All colors are defined here as the single source of truth.
// Usage: AppColors.primary, AppColors.backgroundDark, etc.
// ============================================================

import 'dart:ui';

/// Centralized color definitions for the LUCY design system.
///
/// Colors are organized by function:
/// - **Brand**: Primary, secondary, accent for key UI elements.
/// - **Neutral**: Backgrounds, surfaces, and text colors.
/// - **Semantic**: Success, warning, error states.
class AppColors {
  AppColors._(); // Prevent instantiation

  // ──────────────────────────────────────────────────────────
  // BRAND COLORS
  // ──────────────────────────────────────────────────────────

  /// Deep indigo — primary brand color used for app bars, FABs, and CTAs.
  static const Color primary = Color(0xFF6C63FF);

  /// Lighter indigo variant — for hover states and secondary actions.
  static const Color primaryLight = Color(0xFF9D97FF);

  /// Darker indigo — for pressed states and emphasis.
  static const Color primaryDark = Color(0xFF4A42DB);

  /// Coral pink — secondary accent for highlights and badges.
  static const Color secondary = Color(0xFFFF6B6B);

  /// Vibrant teal — used for AI-related elements and prompts.
  static const Color accent = Color(0xFF2ECEC9);

  // ──────────────────────────────────────────────────────────
  // NEUTRAL / BACKGROUND
  // ──────────────────────────────────────────────────────────

  /// Dark background — main scaffold color in dark mode.
  static const Color backgroundDark = Color(0xFF0F0F1A);

  /// Slightly lighter dark — for cards and elevated surfaces.
  static const Color surfaceDark = Color(0xFF1A1A2E);

  /// Card background with subtle transparency for glassmorphism.
  static const Color cardDark = Color(0xFF16213E);

  /// Light background — main scaffold color in light mode.
  static const Color backgroundLight = Color(0xFFF8F9FE);

  /// Light surface — for cards in light mode.
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // ──────────────────────────────────────────────────────────
  // TEXT
  // ──────────────────────────────────────────────────────────

  /// High-emphasis text on dark backgrounds.
  static const Color textPrimary = Color(0xFFF0F0F5);

  /// Medium-emphasis text — subtitles, captions.
  static const Color textSecondary = Color(0xFFA0A0B8);

  /// Disabled / hint text.
  static const Color textHint = Color(0xFF5A5A72);

  /// Text on light backgrounds.
  static const Color textDark = Color(0xFF1A1A2E);

  // ──────────────────────────────────────────────────────────
  // SEMANTIC
  // ──────────────────────────────────────────────────────────

  /// Success state — completed lessons, correct answers.
  static const Color success = Color(0xFF4CAF50);

  /// Warning state — expiring sessions, low connectivity.
  static const Color warning = Color(0xFFFFC107);

  /// Error state — failed operations, validation errors.
  static const Color error = Color(0xFFEF5350);

  // ──────────────────────────────────────────────────────────
  // GRADIENTS (as list of colors for LinearGradient)
  // ──────────────────────────────────────────────────────────

  /// Primary brand gradient — splash screens, hero sections.
  static const List<Color> primaryGradient = [
    Color(0xFF6C63FF),
    Color(0xFF2ECEC9),
  ];

  /// Warm accent gradient — CTAs, progress indicators.
  static const List<Color> accentGradient = [
    Color(0xFFFF6B6B),
    Color(0xFFFFB347),
  ];
}
