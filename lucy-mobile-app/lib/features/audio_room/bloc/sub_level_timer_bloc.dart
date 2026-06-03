// lib/features/audio_room/bloc/sub_level_timer_bloc.dart
// ============================================================
// Project LUCY — SubLevelTimer BLoC
//
// Client-side countdown timer for stage durations.
// Uses Stream.periodic(Duration(seconds: 1)) for internal ticks.
// Does NOT depend on server ticking every second — saves bandwidth.
//
// When receiving Socket event 'next-sublevel':
//   1. Dispatch TimerReset
//   2. Dispatch TimerStarted(durationSeconds, stageName)
//
// When remainingSeconds == 0:
//   - Emits expired state (isRunning = false)
//   - Does NOT auto-advance sub-level — waits for server confirmation
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'sub_level_timer_event.dart';
import 'sub_level_timer_state.dart';

/// BLoC managing the sub-level countdown timer.
///
/// **Design decisions:**
/// - Timer logic lives entirely in BLoC, NOT in widgets (as per requirements).
/// - Uses [Stream.periodic] instead of [Timer] for consistent, cancellable ticks.
/// - Expired state is passive — the BLoC stops counting but does NOT trigger
///   navigation or sub-level advancement. Server confirms via `next-sublevel`.
///
/// **Usage flow:**
/// ```dart
/// // When Socket receives 'next-sublevel':
/// timerBloc.add(const TimerReset());
/// timerBloc.add(TimerStarted(
///   durationSeconds: 600,  // 10 min for Stage 1&2
///   stageName: 'Stage 1',
/// ));
/// ```
class SubLevelTimerBloc extends Bloc<SubLevelTimerEvent, SubLevelTimerState> {
  /// Subscription to the periodic tick stream.
  /// Cancelled on pause, reset, or close.
  StreamSubscription<int>? _tickSubscription;

  SubLevelTimerBloc() : super(const SubLevelTimerState()) {
    on<TimerStarted>(_onTimerStarted);
    on<TimerTicked>(_onTimerTicked);
    on<TimerPaused>(_onTimerPaused);
    on<TimerReset>(_onTimerReset);
  }

  // ── TIMER STARTED ──────────────────────────────────────────

  /// Starts (or restarts) the countdown timer.
  ///
  /// Cancels any existing tick stream and creates a new one.
  /// Emits the initial state with full duration, then ticks
  /// every second via [Stream.periodic].
  void _onTimerStarted(
    TimerStarted event,
    Emitter<SubLevelTimerState> emit,
  ) {
    // Cancel any existing ticker.
    _tickSubscription?.cancel();

    developer.log(
      '⏱ Timer started: ${event.stageName} — ${event.durationSeconds}s',
      name: 'SubLevelTimerBloc',
    );

    // Emit initial state with full duration.
    emit(SubLevelTimerState(
      remainingSeconds: event.durationSeconds,
      stageName: event.stageName,
      isRunning: true,
    ));

    // Create periodic stream that ticks every 1 second.
    // Stream.periodic emits an ascending count (0, 1, 2, ...).
    // We don't use the count — we just dispatch TimerTicked on each emit.
    _tickSubscription = Stream.periodic(
      const Duration(seconds: 1),
      (tick) => tick,
    ).listen((_) {
      add(const TimerTicked());
    });
  }

  // ── TIMER TICKED ───────────────────────────────────────────

  /// Decrements remaining seconds by 1.
  ///
  /// When reaching 0:
  /// - Cancels the tick stream.
  /// - Emits expired state (isRunning = false).
  /// - Does NOT auto-advance — waits for server `next-sublevel`.
  void _onTimerTicked(
    TimerTicked event,
    Emitter<SubLevelTimerState> emit,
  ) {
    final newRemaining = state.remainingSeconds - 1;

    if (newRemaining <= 0) {
      // Timer expired — stop ticking.
      _tickSubscription?.cancel();
      _tickSubscription = null;

      developer.log(
        '⏱ Timer expired: ${state.stageName} — waiting for server confirmation',
        name: 'SubLevelTimerBloc',
      );

      emit(state.copyWith(
        remainingSeconds: 0,
        isRunning: false,
      ));
    } else {
      emit(state.copyWith(remainingSeconds: newRemaining));
    }
  }

  // ── TIMER PAUSED ───────────────────────────────────────────

  /// Pauses the timer — preserves remaining seconds.
  ///
  /// To resume, dispatch [TimerStarted] with the current
  /// `state.remainingSeconds` and `state.stageName`.
  void _onTimerPaused(
    TimerPaused event,
    Emitter<SubLevelTimerState> emit,
  ) {
    _tickSubscription?.cancel();
    _tickSubscription = null;

    developer.log(
      '⏱ Timer paused: ${state.stageName} — ${state.remainingSeconds}s remaining',
      name: 'SubLevelTimerBloc',
    );

    emit(state.copyWith(isRunning: false));
  }

  // ── TIMER RESET ────────────────────────────────────────────

  /// Resets the timer to its initial (idle) state.
  ///
  /// Cancels the tick stream and clears all state.
  /// Typically called before [TimerStarted] when a new sub-level begins.
  void _onTimerReset(
    TimerReset event,
    Emitter<SubLevelTimerState> emit,
  ) {
    _tickSubscription?.cancel();
    _tickSubscription = null;

    developer.log(
      '⏱ Timer reset',
      name: 'SubLevelTimerBloc',
    );

    emit(const SubLevelTimerState());
  }

  // ── CLEANUP ────────────────────────────────────────────────

  @override
  Future<void> close() {
    _tickSubscription?.cancel();
    _tickSubscription = null;
    return super.close();
  }
}
