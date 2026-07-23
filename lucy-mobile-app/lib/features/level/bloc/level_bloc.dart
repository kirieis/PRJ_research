// lib/features/level/bloc/level_bloc.dart
// ============================================================
// Project LUCY — Level BLoC
//
// Manages user level progression:
//   - Load current progress (from server or local mock)
//   - Add XP after sessions
//   - Trigger level-up when criteria met
//   - Persist progress
//
// Level Up Criteria (both must be met):
//   1. currentXp >= requiredXp
//   2. averageConfidence >= requiredConfidence
// ============================================================

import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/level.dart';
import 'level_event.dart';
import 'level_state.dart';

class LevelBloc extends Bloc<LevelEvent, LevelState> {
  LevelBloc() : super(const LevelState()) {
    on<LevelProgressLoaded>(_onProgressLoaded);
    on<LevelXpEarned>(_onXpEarned);
    on<LevelUpConfirmed>(_onLevelUpConfirmed);
    on<LevelProgressReset>(_onProgressReset);
  }

  // ── LOAD PROGRESS ───────────────────────────────────────────

  Future<void> _onProgressLoaded(
    LevelProgressLoaded event,
    Emitter<LevelState> emit,
  ) async {
    emit(state.copyWith(status: LevelStatus.loading));

    try {
      // MVP: Load mock progress. Production: fetch from API.
      final config = LevelConfig.forLevel(state.currentLevel);

      emit(state.copyWith(
        status: LevelStatus.loaded,
        cefrLevel: config.cefrLevel,
        levelTitle: config.title,
        requiredXp: config.requiredXp,
        sessionsRequired: config.requiredSessions,
        requiredConfidence: config.minConfidenceScore,
      ));

      developer.log(
        '📊 Level loaded: Lv.${state.currentLevel} ${config.cefrLevel} '
        '(${state.currentXp}/${config.requiredXp} XP)',
        name: 'LevelBloc',
      );
    } catch (e) {
      developer.log('❌ Level load error: $e', name: 'LevelBloc');
      emit(state.copyWith(
        status: LevelStatus.error,
        errorMessage: 'Không thể tải dữ liệu level: $e',
      ));
    }
  }

  // ── XP EARNED ───────────────────────────────────────────────

  void _onXpEarned(
    LevelXpEarned event,
    Emitter<LevelState> emit,
  ) {
    final newXp = state.currentXp + event.xpResult.totalXp;
    final newSessions = state.sessionsCompleted + 1;

    // Recalculate average confidence
    final totalConfidence =
        state.averageConfidence * state.sessionsCompleted +
            event.xpResult.confidenceScore;
    final newAvgConfidence =
        newSessions > 0 ? totalConfidence / newSessions : 0.0;

    developer.log(
      '⭐ XP earned: +${event.xpResult.totalXp} → $newXp/${state.requiredXp} '
      '(confidence: ${(newAvgConfidence * 100).round()}%)',
      name: 'LevelBloc',
    );

    // Check level-up criteria
    final meetsXp = newXp >= state.requiredXp;
    final meetsConfidence = newAvgConfidence >= state.requiredConfidence;

    if (meetsXp && meetsConfidence) {
      // LEVEL UP!
      final nextLevel = state.currentLevel + 1;
      final maxLevel = LevelConfig.allLevels.length;

      if (nextLevel <= maxLevel) {
        developer.log(
          '🎉 LEVEL UP! Lv.${state.currentLevel} → Lv.$nextLevel',
          name: 'LevelBloc',
        );

        emit(state.copyWith(
          status: LevelStatus.levelingUp,
          currentXp: newXp,
          sessionsCompleted: newSessions,
          averageConfidence: newAvgConfidence,
          lastXpResult: event.xpResult,
          newLevel: nextLevel,
        ));
      } else {
        // Already at max level
        emit(state.copyWith(
          status: LevelStatus.loaded,
          currentXp: newXp,
          sessionsCompleted: newSessions,
          averageConfidence: newAvgConfidence,
          lastXpResult: event.xpResult,
        ));
      }
    } else {
      emit(state.copyWith(
        status: LevelStatus.loaded,
        currentXp: newXp,
        sessionsCompleted: newSessions,
        averageConfidence: newAvgConfidence,
        lastXpResult: event.xpResult,
      ));
    }
  }

  // ── LEVEL UP CONFIRMED ─────────────────────────────────────

  void _onLevelUpConfirmed(
    LevelUpConfirmed event,
    Emitter<LevelState> emit,
  ) {
    if (state.newLevel == null) return;

    final newLevel = state.newLevel!;
    final config = LevelConfig.forLevel(newLevel);

    // Carry over excess XP
    final excessXp = state.currentXp - state.requiredXp;

    developer.log(
      '✅ Level up confirmed: Lv.$newLevel ${config.cefrLevel} '
      '(excess XP: $excessXp)',
      name: 'LevelBloc',
    );

    emit(LevelState(
      status: LevelStatus.loaded,
      currentLevel: newLevel,
      currentXp: excessXp > 0 ? excessXp : 0,
      requiredXp: config.requiredXp,
      cefrLevel: config.cefrLevel,
      levelTitle: config.title,
      sessionsCompleted: 0,
      sessionsRequired: config.requiredSessions,
      averageConfidence: 0.0,
      requiredConfidence: config.minConfidenceScore,
    ));
  }

  // ── RESET ───────────────────────────────────────────────────

  void _onProgressReset(
    LevelProgressReset event,
    Emitter<LevelState> emit,
  ) {
    developer.log('🔄 Level progress reset', name: 'LevelBloc');
    emit(const LevelState(status: LevelStatus.loaded));
  }
}
