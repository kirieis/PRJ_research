// lib/features/pro_dashboard/widget/sublevel_control_panel.dart
// ============================================================
// Project LUCY — Zone 1: Sub-level Control Panel
// "Next Sub-level" button + current sub-level badge.
// Only visible if user role == mentor or host.
// ============================================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/sub_level_info.dart';

/// Zone 1 — Sub-level control panel for moderators.
///
/// Layout:
/// ```
/// ┌─────────────────────────────────────┐
/// │ 📚 Current Sub-level                │
/// │ ┌─ Sub-level 2/6: Topic ──────────┐ │
/// │ └────────────────────────────────────┘ │
/// │ [▶ Next Sub-level]  (3s cooldown)   │
/// └─────────────────────────────────────┘
/// ```
class SublevelControlPanel extends StatelessWidget {
  /// Current sub-level info (null before first server event).
  final SubLevelInfo? currentSublevel;

  /// Whether the "Next" button is in 3-second cooldown.
  final bool isCooldown;

  /// Whether the current sub-level is the last one.
  final bool isLastSublevel;

  /// Called when moderator taps "Next Sub-level".
  final VoidCallback onNextPressed;

  const SublevelControlPanel({
    super.key,
    this.currentSublevel,
    required this.isCooldown,
    this.isLastSublevel = false,
    required this.onNextPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Sub-level Control',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Current Sub-level Badge ─────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.accent.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              currentSublevel?.displayLabel ?? 'Waiting for sub-level info...',
              style: TextStyle(
                color: currentSublevel != null
                    ? AppColors.textPrimary
                    : AppColors.textHint,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontStyle: currentSublevel == null
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Next Sub-level Button ──────────────────────
          SizedBox(
            width: double.infinity,
            height: 44,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              child: ElevatedButton.icon(
                onPressed: _canPress ? onNextPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canPress
                      ? AppColors.primary
                      : AppColors.textHint.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.textHint.withValues(alpha: 0.15),
                  disabledForegroundColor:
                      AppColors.textHint.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _canPress ? 2 : 0,
                ),
                icon: Icon(
                  isCooldown
                      ? Icons.hourglass_top_rounded
                      : isLastSublevel
                          ? Icons.check_circle_outline_rounded
                          : Icons.skip_next_rounded,
                  size: 18,
                ),
                label: Text(
                  _buttonLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canPress => !isCooldown && !isLastSublevel;

  String get _buttonLabel {
    if (isCooldown) return 'Cooldown...';
    if (isLastSublevel) return 'Last Sub-level';
    return 'Next Sub-level';
  }
}
