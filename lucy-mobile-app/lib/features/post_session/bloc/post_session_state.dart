// lib/features/post_session/bloc/post_session_state.dart
// ============================================================
// Project LUCY — Post-Session BLoC State
// ============================================================

import 'package:equatable/equatable.dart';

import '../model/session_report.dart';

/// Status of report generation.
enum PostSessionStatus {
  /// Waiting for session to end.
  idle,

  /// Generating report (calling AI + calculating XP).
  generating,

  /// Report ready to display.
  ready,

  /// Error generating report.
  error,
}

/// State for the Post-Session BLoC.
class PostSessionState extends Equatable {
  final PostSessionStatus status;
  final SessionReport? report;
  final String? errorMessage;

  const PostSessionState({
    this.status = PostSessionStatus.idle,
    this.report,
    this.errorMessage,
  });

  PostSessionState copyWith({
    PostSessionStatus? status,
    SessionReport? report,
    String? errorMessage,
  }) {
    return PostSessionState(
      status: status ?? this.status,
      report: report ?? this.report,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, report, errorMessage];
}
