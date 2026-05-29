// lib/features/splash/bloc/splash_state.dart
// ============================================================
// Project LUCY — Splash BLoC States
// ============================================================

import 'package:equatable/equatable.dart';

/// Represents the possible states of the splash screen.
enum SplashStatus { initial, loading, success, failure }

/// Immutable state for the Splash BLoC.
class SplashState extends Equatable {
  /// Current status of the splash initialization flow.
  final SplashStatus status;

  /// Loaded level data (null until [status] is [SplashStatus.success]).
  final Map<String, dynamic>? levelData;

  /// Error message if [status] is [SplashStatus.failure].
  final String? errorMessage;

  const SplashState({
    this.status = SplashStatus.initial,
    this.levelData,
    this.errorMessage,
  });

  /// Creates a copy of this state with optional field overrides.
  SplashState copyWith({
    SplashStatus? status,
    Map<String, dynamic>? levelData,
    String? errorMessage,
  }) {
    return SplashState(
      status: status ?? this.status,
      levelData: levelData ?? this.levelData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, levelData, errorMessage];
}
