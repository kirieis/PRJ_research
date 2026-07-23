// lib/features/auth/bloc/auth_bloc.dart
// ============================================================
// Project LUCY — Auth BLoC
// Handles login, register, and logout flows.
// ============================================================

import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../service/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC managing authentication state.
///
/// Processes:
/// - [AuthLoginSubmitted] → calls AuthService.login
/// - [AuthRegisterSubmitted] → calls AuthService.register
/// - [AuthLogoutRequested] → clears stored token
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(const AuthState()) {
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  /// Handles login form submission.
  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final response = await _authService.login(
        email: event.email,
        password: event.password,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
        accessToken: response.accessToken,
      ));
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      developer.log('❌ Unexpected login error: $e', name: 'AuthBloc');
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'An unexpected error occurred.',
      ));
    }
  }

  /// Handles register form submission.
  Future<void> _onRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final response = await _authService.register(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
        accessToken: response.accessToken,
      ));
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      developer.log('❌ Unexpected register error: $e', name: 'AuthBloc');
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'An unexpected error occurred.',
      ));
    }
  }

  /// Handles logout — clears stored token and resets state.
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.logout();
    emit(const AuthState());
  }
}
