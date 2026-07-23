// lib/features/post_session/bloc/post_session_bloc.dart
// ============================================================
// Project LUCY — Post-Session BLoC
//
// Generates AI-powered session reports:
//   1. Collects engagement metrics from server
//   2. Calculates XP using XpCalculator
//   3. Fetches AI-generated mistakes and summary
//   4. Packages into SessionReport for display
//
// MVP: Uses mock data. Production: calls backend API.
// ============================================================

import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/session_report.dart';
import 'post_session_event.dart';
import 'post_session_state.dart';

class PostSessionBloc extends Bloc<PostSessionEvent, PostSessionState> {
  PostSessionBloc() : super(const PostSessionState()) {
    on<PostSessionReportRequested>(_onReportRequested);
    on<PostSessionReportDismissed>(_onReportDismissed);
  }

  Future<void> _onReportRequested(
    PostSessionReportRequested event,
    Emitter<PostSessionState> emit,
  ) async {
    emit(state.copyWith(status: PostSessionStatus.generating));

    try {
      // MVP: Generate mock report.
      // Production: POST /api/sessions/{id}/report
      await Future.delayed(const Duration(milliseconds: 800));

      final report = SessionReport.mock(
        sessionId: event.sessionId,
        roomId: event.roomId,
        topic: event.topic,
      );

      developer.log(
        '📊 Report generated: +${report.xpResult.totalXp} XP, '
        '${report.confidencePercentage} confidence, '
        '${report.mistakes.length} mistakes',
        name: 'PostSessionBloc',
      );

      emit(state.copyWith(
        status: PostSessionStatus.ready,
        report: report,
      ));
    } catch (e) {
      developer.log('❌ Report generation error: $e',
          name: 'PostSessionBloc');
      emit(state.copyWith(
        status: PostSessionStatus.error,
        errorMessage: 'Không thể tạo báo cáo: $e',
      ));
    }
  }

  void _onReportDismissed(
    PostSessionReportDismissed event,
    Emitter<PostSessionState> emit,
  ) {
    emit(const PostSessionState());
  }
}
