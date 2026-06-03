// lib/features/audio_room/bloc/sub_level_timer_state.dart
// ============================================================
// Project LUCY — SubLevelTimer BLoC State
//
// Immutable state for the countdown timer.
// Widget reads this to display MM:SS, color changes, and pulse.
// ============================================================

import 'package:equatable/equatable.dart';

/// Immutable state of the sub-level countdown timer.
///
/// Used by [CountdownDisplay] widget to show:
/// - MM:SS remaining time
/// - Red text when < 60 seconds
/// - Pulse animation when < 30 seconds
/// - "Expired" overlay when remainingSeconds == 0
class SubLevelTimerState extends Equatable {
  /// Seconds remaining in the current stage.
  ///
  /// When this reaches 0, the timer is considered "expired".
  /// The BLoC does NOT auto-advance — it waits for server confirmation
  /// via the `next-sublevel` Socket event.
  final int remainingSeconds;

  /// Name of the current stage (e.g., "Stage 1", "Warm-up").
  ///
  /// Displayed alongside the countdown for context.
  final String stageName;

  /// Whether the timer is actively counting down.
  ///
  /// False when:
  /// - Timer has not been started yet (initial state)
  /// - Timer has been paused
  /// - Timer has expired (remainingSeconds == 0)
  /// - Timer has been reset
  final bool isRunning;

  const SubLevelTimerState({
    this.remainingSeconds = 0,
    this.stageName = '',
    this.isRunning = false,
  });

  /// Whether the timer has expired (reached zero while it was running).
  bool get isExpired => remainingSeconds == 0 && stageName.isNotEmpty;

  /// Whether the countdown is in the warning zone (< 60 seconds).
  /// Used to change text color to red.
  bool get isWarning => isRunning && remainingSeconds < 60;

  /// Whether the countdown is in the critical zone (< 30 seconds).
  /// Used to trigger pulse animation.
  bool get isCritical => isRunning && remainingSeconds < 30;

  /// Formats remaining seconds as MM:SS string.
  ///
  /// Examples: "10:00", "09:59", "00:30", "00:00"
  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  SubLevelTimerState copyWith({
    int? remainingSeconds,
    String? stageName,
    bool? isRunning,
  }) {
    return SubLevelTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      stageName: stageName ?? this.stageName,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  @override
  List<Object?> get props => [remainingSeconds, stageName, isRunning];
}
