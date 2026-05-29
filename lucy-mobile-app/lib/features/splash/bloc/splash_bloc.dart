// lib/features/splash/bloc/splash_bloc.dart
// ============================================================
// Project LUCY — Splash BLoC
// Orchestrates the splash screen initialization flow:
//   1. Wait 2 seconds (branding delay)
//   2. Load mock JSON data via MockRepository
//   3. Emit success → navigate, or failure → show retry
// ============================================================

import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../mock/mock_repository.dart';
import 'splash_event.dart';
import 'splash_state.dart';

/// BLoC handling the splash screen initialization sequence.
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final MockRepository _mockRepository;

  SplashBloc({required MockRepository mockRepository})
      : _mockRepository = mockRepository,
        super(const SplashState()) {
    on<SplashStarted>(_onSplashStarted);
    on<SplashRetryRequested>(_onRetryRequested);
  }

  /// Handles the initial splash sequence.
  Future<void> _onSplashStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(state.copyWith(status: SplashStatus.loading));

    // Step 1: Enforce minimum splash display time (branding).
    await Future.delayed(AppConstants.splashDelay);

    // Step 2: Load mock data from local JSON asset.
    try {
      final levelData = await _mockRepository.loadLevel();

      // Log success to console for verification.
      developer.log(
        '✅ MockRepository loaded successfully: '
        'levelId=${levelData['levelId']}, '
        'title="${levelData['title']}", '
        'subLevels=${(levelData['subLevels'] as List).length}',
        name: 'SplashBloc',
      );

      emit(state.copyWith(
        status: SplashStatus.success,
        levelData: levelData,
      ));
    } catch (e) {
      developer.log(
        '❌ MockRepository failed: $e',
        name: 'SplashBloc',
        error: e,
      );

      emit(state.copyWith(
        status: SplashStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Handles retry requests — re-runs the full initialization.
  Future<void> _onRetryRequested(
    SplashRetryRequested event,
    Emitter<SplashState> emit,
  ) async {
    add(const SplashStarted());
  }
}
