// test/level_bloc_test.dart
// ============================================================
// Project LUCY — Level BLoC & XpCalculator Unit Tests
//
// Tests:
//   ✅ Initial state
//   ✅ Load level progress
//   ✅ XP earned updates state
//   ✅ Level up triggered when criteria met
//   ✅ Level up NOT triggered when confidence too low
//   ✅ Excess XP carried over after level up
//   ✅ Progress reset
//   ✅ XpCalculator formula tests
// ============================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:lucy_app/core/models/level.dart';
import 'package:lucy_app/features/level/bloc/level_bloc.dart';
import 'package:lucy_app/features/level/bloc/level_event.dart';
import 'package:lucy_app/features/level/bloc/level_state.dart';

void main() {
  group('LevelBloc', () {
    late LevelBloc bloc;

    setUp(() {
      bloc = LevelBloc();
    });

    tearDown(() async {
      await bloc.close();
    });

    test('initial state is correct', () {
      expect(bloc.state.status, LevelStatus.initial);
      expect(bloc.state.currentLevel, 1);
      expect(bloc.state.currentXp, 0);
      expect(bloc.state.progress, 0.0);
    });

    test('LevelProgressLoaded loads config for current level', () async {
      bloc.add(const LevelProgressLoaded());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state.status, LevelStatus.loaded);
      expect(bloc.state.cefrLevel, 'A1');
      expect(bloc.state.levelTitle, 'Daily Greetings');
      expect(bloc.state.requiredXp, 300);
    });

    test('LevelXpEarned updates XP correctly', () async {
      // Seed with loaded state
      bloc.add(const LevelProgressLoaded());
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const LevelXpEarned(
        xpResult: XpResult(
          totalXp: 85,
          baseXp: 100,
          engagementMultiplier: 0.85,
          durationRatio: 1.0,
          completedFullSession: true,
          confidenceScore: 0.30, // Low confidence — no level up
        ),
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state.currentXp, 85);
      expect(bloc.state.sessionsCompleted, 1);
      expect(bloc.state.status, LevelStatus.loaded);
    });

    test('LevelXpEarned triggers level up when XP + confidence met', () async {
      bloc.add(const LevelProgressLoaded());
      await Future.delayed(const Duration(milliseconds: 100));

      // Add enough XP across multiple sessions with high confidence
      const xpResult = XpResult(
        totalXp: 150,
        baseXp: 100,
        engagementMultiplier: 0.85,
        durationRatio: 1.0,
        completedFullSession: true,
        confidenceScore: 0.65,
      );

      // Session 1: 150 XP
      bloc.add(const LevelXpEarned(xpResult: xpResult));
      await Future.delayed(const Duration(milliseconds: 100));
      expect(bloc.state.currentXp, 150);
      expect(bloc.state.status, LevelStatus.loaded);

      // Session 2: +150 XP = 300 (meets 300 required)
      bloc.add(const LevelXpEarned(xpResult: xpResult));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state.currentXp, 300);
      expect(bloc.state.status, LevelStatus.levelingUp);
      expect(bloc.state.newLevel, 2);
    });

    test('LevelXpEarned does NOT level up when confidence too low', () async {
      bloc.add(const LevelProgressLoaded());
      await Future.delayed(const Duration(milliseconds: 100));

      // Add enough XP but with very low confidence
      const xpResult = XpResult(
        totalXp: 150,
        baseXp: 100,
        engagementMultiplier: 0.85,
        durationRatio: 1.0,
        completedFullSession: true,
        confidenceScore: 0.10, // Very low!
      );

      bloc.add(const LevelXpEarned(xpResult: xpResult));
      await Future.delayed(const Duration(milliseconds: 100));
      bloc.add(const LevelXpEarned(xpResult: xpResult));
      await Future.delayed(const Duration(milliseconds: 100));

      // XP is enough (300) but confidence is too low (0.10 < 0.40)
      expect(bloc.state.currentXp, 300);
      expect(bloc.state.status, LevelStatus.loaded); // NOT levelingUp!
    });

    test('LevelUpConfirmed transitions to next level with excess XP', () async {
      bloc.add(const LevelProgressLoaded());
      await Future.delayed(const Duration(milliseconds: 100));

      // Trigger level up
      const xpResult = XpResult(
        totalXp: 200,
        baseXp: 100,
        engagementMultiplier: 0.90,
        durationRatio: 1.0,
        completedFullSession: true,
        confidenceScore: 0.70,
      );

      bloc.add(const LevelXpEarned(xpResult: xpResult));
      await Future.delayed(const Duration(milliseconds: 100));
      bloc.add(const LevelXpEarned(xpResult: xpResult));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state.status, LevelStatus.levelingUp);
      final excessXp = bloc.state.currentXp - bloc.state.requiredXp;

      // Confirm level up
      bloc.add(const LevelUpConfirmed());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state.status, LevelStatus.loaded);
      expect(bloc.state.currentLevel, 2);
      expect(bloc.state.currentXp, excessXp > 0 ? excessXp : 0);
      expect(bloc.state.cefrLevel, 'A2');
      expect(bloc.state.requiredXp, 500);
      expect(bloc.state.sessionsCompleted, 0); // Reset
    });

    test('LevelProgressReset resets to initial loaded state', () async {
      bloc.add(const LevelProgressLoaded());
      await Future.delayed(const Duration(milliseconds: 100));
      bloc.add(const LevelXpEarned(
        xpResult: XpResult(
          totalXp: 50,
          baseXp: 100,
          engagementMultiplier: 0.50,
          durationRatio: 1.0,
          completedFullSession: true,
          confidenceScore: 0.50,
        ),
      ));
      await Future.delayed(const Duration(milliseconds: 100));
      expect(bloc.state.currentXp, 50);

      bloc.add(const LevelProgressReset());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state.currentLevel, 1);
      expect(bloc.state.currentXp, 0);
      expect(bloc.state.status, LevelStatus.loaded);
    });
  });

  group('XpCalculator', () {
    test('full session with high engagement gives good XP', () {
      const metrics = EngagementMetrics(
        speakingRatio: 0.80,
        averageResponseTime: 1.5,
        vocabularyUsed: 5,
        vocabularySuggested: 6,
        peerInteractions: 5,
        unmutedDurationSeconds: 1000,
        totalDurationSeconds: 1200,
        confidenceScore: 0.85,
      );

      final result = XpCalculator.calculate(metrics: metrics);

      expect(result.totalXp, greaterThan(50));
      expect(result.engagementMultiplier, greaterThan(0.7));
      expect(result.completedFullSession, isTrue);
    });

    test('early leave applies 30% penalty', () {
      const metrics = EngagementMetrics(
        speakingRatio: 0.50,
        averageResponseTime: 3.0,
        vocabularyUsed: 2,
        vocabularySuggested: 4,
        peerInteractions: 2,
        unmutedDurationSeconds: 400,
        totalDurationSeconds: 1200,
        confidenceScore: 0.50,
      );

      final fullResult = XpCalculator.calculate(metrics: metrics);
      final earlyResult = XpCalculator.calculate(
        metrics: metrics,
        completedFullSession: false,
      );

      expect(earlyResult.totalXp, lessThan(fullResult.totalXp));
      expect(earlyResult.completedFullSession, isFalse);
    });

    test('zero speaking gives zero XP', () {
      const metrics = EngagementMetrics(
        speakingRatio: 0.0,
        averageResponseTime: 10.0,
        vocabularyUsed: 0,
        vocabularySuggested: 0,
        peerInteractions: 0,
        unmutedDurationSeconds: 0,
        totalDurationSeconds: 1200,
        confidenceScore: 0.0,
      );

      final result = XpCalculator.calculate(metrics: metrics);
      expect(result.totalXp, 0);
    });

    test('minimum 1 XP if user spoke at all', () {
      const metrics = EngagementMetrics(
        speakingRatio: 0.01,
        averageResponseTime: 9.0,
        vocabularyUsed: 0,
        vocabularySuggested: 0,
        peerInteractions: 0,
        unmutedDurationSeconds: 10,
        totalDurationSeconds: 1200,
        confidenceScore: 0.1,
      );

      final result = XpCalculator.calculate(metrics: metrics);
      expect(result.totalXp, greaterThanOrEqualTo(1));
    });

    test('engagement multiplier components are weighted correctly', () {
      // Only speaking, no other engagement
      const speakingOnly = EngagementMetrics(
        speakingRatio: 1.0,
        averageResponseTime: 10.0, // slow
        vocabularyUsed: 0,
        vocabularySuggested: 5,
        peerInteractions: 0,
        unmutedDurationSeconds: 1200,
        totalDurationSeconds: 1200,
        confidenceScore: 0.5,
      );

      final result = XpCalculator.calculate(metrics: speakingOnly);

      // Speaking weight is 40%, so engagement ≈ 0.40
      expect(result.engagementMultiplier, closeTo(0.40, 0.05));
    });
  });
}
