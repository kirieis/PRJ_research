// lib/features/post_session/bloc/post_session_event.dart
// ============================================================
// Project LUCY — Post-Session BLoC Events
// ============================================================

import 'package:equatable/equatable.dart';

/// Base event for the Post-Session BLoC.
sealed class PostSessionEvent extends Equatable {
  const PostSessionEvent();

  @override
  List<Object?> get props => [];
}

/// Generate report after session ends.
class PostSessionReportRequested extends PostSessionEvent {
  final String sessionId;
  final String roomId;
  final String topic;
  final int durationSeconds;
  final bool completedFullSession;

  const PostSessionReportRequested({
    required this.sessionId,
    required this.roomId,
    required this.topic,
    required this.durationSeconds,
    this.completedFullSession = true,
  });

  @override
  List<Object?> get props => [
        sessionId,
        roomId,
        topic,
        durationSeconds,
        completedFullSession,
      ];
}

/// User acknowledged the report — navigate to lobby.
class PostSessionReportDismissed extends PostSessionEvent {
  const PostSessionReportDismissed();
}
