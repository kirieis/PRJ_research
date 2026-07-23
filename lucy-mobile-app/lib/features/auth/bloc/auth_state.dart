// lib/features/auth/bloc/auth_state.dart
// ============================================================
// Project LUCY — Auth BLoC State
// ============================================================

import 'package:equatable/equatable.dart';
import '../model/auth_user.dart';

/// Represents the possible statuses of the auth flow.
enum AuthStatus { initial, loading, authenticated, failure }

/// Immutable state for the Auth BLoC.
class AuthState extends Equatable {
  /// Current authentication status.
  final AuthStatus status;

  /// The authenticated user (available when [status] is [AuthStatus.authenticated]).
  final AuthUser? user;

  /// JWT access token (available when [status] is [AuthStatus.authenticated]).
  final String? accessToken;

  /// Error message if [status] is [AuthStatus.failure].
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.accessToken,
    this.errorMessage,
  });

  /// Creates a copy with optional field overrides.
  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? accessToken,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, accessToken, errorMessage];
}
