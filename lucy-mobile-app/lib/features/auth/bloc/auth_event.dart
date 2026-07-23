// lib/features/auth/bloc/auth_event.dart
// ============================================================
// Project LUCY — Auth BLoC Events
// ============================================================

import 'package:equatable/equatable.dart';

/// Base class for all authentication events.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// User submitted the login form with [email] and [password].
class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginSubmitted({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// User submitted the register form.
class AuthRegisterSubmitted extends AuthEvent {
  final String displayName;
  final String email;
  final String password;

  const AuthRegisterSubmitted({
    required this.displayName,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [displayName, email, password];
}

/// User requested to log out.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
