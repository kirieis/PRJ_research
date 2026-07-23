// test/sub_level_timer_bloc_test.dart
// ============================================================
// Project LUCY — SubLevelTimerBloc Unit Tests (Dev 5 — T10)
//
// Covers: start, tick, pause, resume, reset, expire
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:lucy_app/features/audio_room/bloc/sub_level_timer_bloc.dart';
import 'package:lucy_app/features/audio_room/bloc/sub_level_timer_event.dart';
import 'package:lucy_app/features/audio_room/bloc/sub_level_timer_state.dart';

void main() {
  group('SubLevelTimerBloc', () {
    late SubLevelTimerBloc bloc;

    setUp(() {
      bloc = SubLevelTimerBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is correct', () {
      expect(bloc.state.remainingSeconds, 0);
      expect(bloc.state.isRunning, false);
      expect(bloc.state.stageName, '');
    });

    blocTest<SubLevelTimerBloc, SubLevelTimerState>(
      'emits running state when TimerStarted is added',
      build: () => SubLevelTimerBloc(),
      act: (bloc) => bloc.add(
        const TimerStarted(durationSeconds: 600, stageName: 'Stage 1'),
      ),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.isRunning, true);
        expect(bloc.state.stageName, 'Stage 1');
        expect(bloc.state.remainingSeconds, lessThanOrEqualTo(600));
        expect(bloc.state.remainingSeconds, greaterThan(0));
      },
    );

    blocTest<SubLevelTimerBloc, SubLevelTimerState>(
      'emits ticking states with decreasing remainingSeconds',
      build: () => SubLevelTimerBloc(),
      act: (bloc) {
        bloc.add(
          const TimerStarted(durationSeconds: 5, stageName: 'Short'),
        );
      },
      wait: const Duration(seconds: 3),
      verify: (bloc) {
        expect(bloc.state.remainingSeconds, lessThan(5));
        expect(bloc.state.isRunning, true);
      },
    );

    blocTest<SubLevelTimerBloc, SubLevelTimerState>(
      'pauses timer when TimerPaused is added',
      build: () => SubLevelTimerBloc(),
      act: (bloc) async {
        bloc.add(
          const TimerStarted(durationSeconds: 600, stageName: 'Stage 1'),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        bloc.add(const TimerPaused());
      },
      wait: const Duration(milliseconds: 800),
      verify: (bloc) {
        expect(bloc.state.isRunning, false);
        expect(bloc.state.remainingSeconds, greaterThan(0));
      },
    );

    blocTest<SubLevelTimerBloc, SubLevelTimerState>(
      'resumes timer when TimerStarted is added after pause',
      build: () => SubLevelTimerBloc(),
      act: (bloc) async {
        bloc.add(
          const TimerStarted(durationSeconds: 600, stageName: 'Stage 1'),
        );
        await Future.delayed(const Duration(milliseconds: 300));
        bloc.add(const TimerPaused());
        await Future.delayed(const Duration(milliseconds: 300));
        bloc.add(TimerStarted(
          durationSeconds: bloc.state.remainingSeconds,
          stageName: bloc.state.stageName,
        ));
      },
      wait: const Duration(milliseconds: 800),
      verify: (bloc) {
        expect(bloc.state.isRunning, true);
      },
    );

    blocTest<SubLevelTimerBloc, SubLevelTimerState>(
      'resets timer to initial state when TimerReset is added',
      build: () => SubLevelTimerBloc(),
      act: (bloc) async {
        bloc.add(
          const TimerStarted(durationSeconds: 600, stageName: 'Stage 1'),
        );
        await Future.delayed(const Duration(milliseconds: 300));
        bloc.add(const TimerReset());
      },
      wait: const Duration(milliseconds: 500),
      verify: (bloc) {
        expect(bloc.state.isRunning, false);
        expect(bloc.state.remainingSeconds, 0);
        expect(bloc.state.stageName, '');
      },
    );

    blocTest<SubLevelTimerBloc, SubLevelTimerState>(
      'timer expires when remainingSeconds reaches 0',
      build: () => SubLevelTimerBloc(),
      act: (bloc) {
        bloc.add(
          const TimerStarted(durationSeconds: 2, stageName: 'Quick'),
        );
      },
      wait: const Duration(seconds: 3),
      verify: (bloc) {
        expect(bloc.state.remainingSeconds, 0);
        expect(bloc.state.isRunning, false);
      },
    );

    test('formattedTime formats correctly', () {
      // Test the state's computed properties
      const state1 = SubLevelTimerState(
        remainingSeconds: 125,
        isRunning: true,
        stageName: 'Test',
      );
      expect(state1.formattedTime, '02:05');

      const state2 = SubLevelTimerState(
        remainingSeconds: 0,
        isRunning: false,
        stageName: '',
      );
      expect(state2.formattedTime, '00:00');

      const state3 = SubLevelTimerState(
        remainingSeconds: 3600,
        isRunning: true,
        stageName: 'Long',
      );
      expect(state3.formattedTime, '60:00');
    });

    test('isWarning is true when <= 60 seconds', () {
      const state = SubLevelTimerState(
        remainingSeconds: 45,
        isRunning: true,
        stageName: 'Test',
      );
      expect(state.isWarning, true);
    });

    test('isCritical is true when <= 10 seconds', () {
      const state = SubLevelTimerState(
        remainingSeconds: 8,
        isRunning: true,
        stageName: 'Test',
      );
      expect(state.isCritical, true);
    });
  });
}
