// lib/features/level/widget/level_progress_bar.dart
// ============================================================
// Project LUCY — Level Progress Bar Widget
//
// Animated progress bar showing:
//   - Level badge (Lv.1 A1)
//   - XP progress bar with gradient
//   - XP text (120 / 300 XP)
//   - Pulse animation when near level-up
//
// Used in Room Lobby header and Post-session screen.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/level_bloc.dart';
import '../bloc/level_state.dart';

/// Compact level progress bar widget.
///
/// Shows current level, XP progress, and animates smoothly
/// when XP changes. Pulses when close to leveling up (>80%).
class LevelProgressBar extends StatelessWidget {
  /// Whether to show the level badge on the left.
  final bool showBadge;

  /// Whether to show XP text below the bar.
  final bool showXpText;

  const LevelProgressBar({
    super.key,
    this.showBadge = true,
    this.showXpText = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LevelBloc, LevelState>(
      buildWhen: (prev, curr) =>
          prev.currentXp != curr.currentXp ||
          prev.currentLevel != curr.currentLevel ||
          prev.status != curr.status,
      builder: (context, state) {
        if (state.status == LevelStatus.initial) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (showBadge) ...[
                  _LevelBadge(
                    level: state.currentLevel,
                    cefrLevel: state.cefrLevel,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _AnimatedProgressBar(
                    progress: state.progress,
                    isNearLevelUp: state.progress > 0.8,
                  ),
                ),
              ],
            ),
            if (showXpText) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    state.levelTitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                  ),
                  Text(
                    state.xpDisplayText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Level badge chip (e.g. "Lv.3 B1").
class _LevelBadge extends StatelessWidget {
  final int level;
  final String cefrLevel;

  const _LevelBadge({
    required this.level,
    required this.cefrLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Lv.$level $cefrLevel',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Animated gradient progress bar with pulse effect near level-up.
class _AnimatedProgressBar extends StatefulWidget {
  final double progress;
  final bool isNearLevelUp;

  const _AnimatedProgressBar({
    required this.progress,
    required this.isNearLevelUp,
  });

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    if (widget.isNearLevelUp) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNearLevelUp && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isNearLevelUp && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final glowOpacity =
            widget.isNearLevelUp ? 0.3 + (_pulseCtrl.value * 0.3) : 0.0;

        return Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: AppColors.surfaceDark,
            boxShadow: widget.isNearLevelUp
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: glowOpacity),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: widget.progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryGradient,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
