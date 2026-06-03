// lib/features/audio_room/bloc/sub_level_timer_event.dart
// ============================================================
// Project LUCY — SubLevelTimer BLoC Events
//
// All events controlling the countdown timer for stage durations.
// Dev 4 (Node.js) sends 'next-sublevel' Socket event when a stage
// ends — client dispatches TimerReset + TimerStarted with new duration.
// ============================================================

import 'package:equatable/equatable.dart';

/// Base class for all sub-level timer events.
sealed class SubLevelTimerEvent extends Equatable {
  const SubLevelTimerEvent();

  @override
  List<Object?> get props => [];
}

/// Starts the countdown timer with a given duration.
///
/// Dispatched when:
/// - Room is joined (initial stage)
/// - Server sends `next-sublevel` (after TimerReset)
///
/// [durationSeconds] is determined by stage:
/// - Stage 1 & 2: 600s (10 minutes)
/// - Stage 3: 1200s (20 minutes)
class TimerStarted extends SubLevelTimerEvent {
  final int durationSeconds;
  final String stageName;

  const TimerStarted({
    required this.durationSeconds,
    required this.stageName,
  });

  @override
  List<Object?> get props => [durationSeconds, stageName];
}

/// Internal tick event — dispatched every second by Stream.periodic.
///
/// This event is ONLY dispatched internally by the BLoC itself.
/// Widget code MUST NOT dispatch this event.
class TimerTicked extends SubLevelTimerEvent {
  const TimerTicked();
}

/// Pauses the running countdown timer.
///
/// The remaining seconds are preserved in state.
/// Dispatch TimerStarted (with current remaining) to resume.
class TimerPaused extends SubLevelTimerEvent {
  const TimerPaused();
}

/// Resets the timer to its initial (idle) state.
///
/// Cancels any running periodic stream.
/// Typically dispatched before TimerStarted when server sends
/// a new `next-sublevel` event.
class TimerReset extends SubLevelTimerEvent {
  const TimerReset();
}
