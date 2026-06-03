// lib/features/audio_room/widget/countdown_display.dart
// ============================================================
// Project LUCY — Countdown Display Widget
//
// Displays remaining time in MM:SS format.
// Visual feedback:
//   - Default: white text
//   - < 60 seconds: red text
//   - < 30 seconds: red text + pulse animation
//
// IMPORTANT: No Timer/periodic logic here. All countdown logic
// lives in SubLevelTimerBloc. This widget only reads state.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/sub_level_timer_bloc.dart';
import '../bloc/sub_level_timer_state.dart';

/// Countdown timer display for the audio room top bar.
///
/// Reads from [SubLevelTimerBloc] and renders:
/// - Stage name label
/// - MM:SS countdown
/// - Color transitions (white → red at < 60s)
/// - Pulse animation at < 30s
///
/// **Zero timer logic in widget** — all countdown management
/// happens in [SubLevelTimerBloc] via Stream.periodic.
///
/// Place this widget in the AppBar or top bar of [AudioRoomScreen].
class CountdownDisplay extends StatefulWidget {
  const CountdownDisplay({super.key});

  @override
  State<CountdownDisplay> createState() => _CountdownDisplayState();
}

class _CountdownDisplayState extends State<CountdownDisplay>
    with SingleTickerProviderStateMixin {
  /// Animation controller for the pulse effect.
  /// Only active when remainingSeconds < 30.
  late AnimationController _pulseController;

  /// Scale animation driven by the pulse controller.
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation: gentle scale from 1.0 to 1.15 and back.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubLevelTimerBloc, SubLevelTimerState>(
      listenWhen: (prev, curr) => prev.isCritical != curr.isCritical,
      listener: (context, state) {
        // Start or stop pulse animation based on critical threshold.
        if (state.isCritical) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      },
      buildWhen: (prev, curr) =>
          prev.remainingSeconds != curr.remainingSeconds ||
          prev.isRunning != curr.isRunning ||
          prev.stageName != curr.stageName,
      builder: (context, state) {
        // Don't show anything if timer hasn't been started.
        if (state.stageName.isEmpty && !state.isRunning) {
          return const SizedBox.shrink();
        }

        // Determine text color based on time remaining.
        final Color timerColor;
        if (state.isExpired) {
          timerColor = AppColors.error;
        } else if (state.isWarning) {
          timerColor = AppColors.error;
        } else {
          timerColor = AppColors.textPrimary;
        }

        // Determine background color.
        final Color bgColor;
        if (state.isExpired) {
          bgColor = AppColors.error.withValues(alpha: 0.2);
        } else if (state.isWarning) {
          bgColor = AppColors.error.withValues(alpha: 0.1);
        } else {
          bgColor = AppColors.primary.withValues(alpha: 0.1);
        }

        final timerWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state.isWarning || state.isExpired
                  ? AppColors.error.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stage icon.
              Icon(
                state.isExpired
                    ? Icons.timer_off_rounded
                    : Icons.timer_rounded,
                size: 14,
                color: timerColor,
              ),
              const SizedBox(width: 4),

              // Stage name (abbreviated).
              if (state.stageName.isNotEmpty) ...[
                Text(
                  state.stageName,
                  style: TextStyle(
                    color: timerColor.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
              ],

              // MM:SS countdown.
              Text(
                state.isExpired ? 'EXPIRED' : state.formattedTime,
                style: TextStyle(
                  color: timerColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [
                    // Monospaced numbers for stable width during countdown.
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        );

        // Wrap with pulse animation when in critical zone.
        if (state.isCritical) {
          return AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: timerWidget,
          );
        }

        return timerWidget;
      },
    );
  }
}
