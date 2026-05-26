// lib/features/splash/bloc/splash_event.dart
// ============================================================
// Project LUCY — Splash BLoC Events
// ============================================================

import 'package:equatable/equatable.dart';

/// Base class for all Splash-related events.
sealed class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when the splash screen is first displayed.
/// Triggers the 2-second delay + mock data load sequence.
class SplashStarted extends SplashEvent {
  const SplashStarted();
}

/// Fired when the user taps the retry button after a failure.
class SplashRetryRequested extends SplashEvent {
  const SplashRetryRequested();
}
