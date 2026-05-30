// lib/features/pro_dashboard/bloc/pro_dashboard_event.dart
// ============================================================
// Project LUCY — Pro Dashboard BLoC Events
// ============================================================

import 'package:equatable/equatable.dart';

import '../model/auth_state.dart';
import '../model/sub_level_info.dart';

/// Base class for all Pro Dashboard events.
sealed class ProDashboardEvent extends Equatable {
  const ProDashboardEvent();

  @override
  List<Object?> get props => [];
}

// ── Lifecycle ───────────────────────────────────────────────

/// Initialize the dashboard — load hints, subscribe to streams.
class ProDashboardStarted extends ProDashboardEvent {
  final String roomId;
  final AuthState authState;

  const ProDashboardStarted({
    required this.roomId,
    required this.authState,
  });

  @override
  List<Object?> get props => [roomId, authState];
}

// ── Zone 1: Sub-level Control ───────────────────────────────

/// Moderator pressed "Next Sub-level" button.
class ProDashboardNextSublevelPressed extends ProDashboardEvent {
  const ProDashboardNextSublevelPressed();
}

/// Server notified sub-level changed (via 'next-sublevel' socket event).
class ProDashboardSublevelChanged extends ProDashboardEvent {
  final SubLevelInfo sublevel;

  const ProDashboardSublevelChanged(this.sublevel);

  @override
  List<Object?> get props => [sublevel];
}

/// 3-second cooldown expired — re-enable the button.
class ProDashboardCooldownExpired extends ProDashboardEvent {
  const ProDashboardCooldownExpired();
}

// ── Zone 2: Speaking Queue ──────────────────────────────────

/// Moderator approved a speaker from the queue.
class ProDashboardSpeakerApproved extends ProDashboardEvent {
  final String userId;

  const ProDashboardSpeakerApproved(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Moderator skipped a speaker from the queue.
class ProDashboardSpeakerSkipped extends ProDashboardEvent {
  final String userId;

  const ProDashboardSpeakerSkipped(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// A user raised their hand (via 'user-raised-hand' socket event).
class ProDashboardSpeakQueueUpdated extends ProDashboardEvent {
  final String userId;

  const ProDashboardSpeakQueueUpdated(this.userId);

  @override
  List<Object?> get props => [userId];
}

// ── Zone 3: Pin Resources ───────────────────────────────────

/// Moderator pinned a new resource (URL or image).
class ProDashboardResourcePinned extends ProDashboardEvent {
  final String resourceUrl;
  final String type; // "image" or "url"

  const ProDashboardResourcePinned({
    required this.resourceUrl,
    required this.type,
  });

  @override
  List<Object?> get props => [resourceUrl, type];
}

// ── Room State ──────────────────────────────────────────────

/// Full room state received from server (via 'room-state-updated').
class ProDashboardRoomStateReceived extends ProDashboardEvent {
  final Map<String, dynamic> data;

  const ProDashboardRoomStateReceived(this.data);

  @override
  List<Object?> get props => [data];
}
