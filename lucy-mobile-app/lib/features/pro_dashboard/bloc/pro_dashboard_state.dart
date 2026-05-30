// lib/features/pro_dashboard/bloc/pro_dashboard_state.dart
// ============================================================
// Project LUCY — Pro Dashboard BLoC State
// ============================================================

import 'package:equatable/equatable.dart';

import '../model/auth_state.dart';
import '../model/pinned_resource.dart';
import '../model/sub_level_info.dart';

/// Connection/loading status for the Pro Dashboard.
enum ProDashboardStatus {
  /// Initial state before initialization.
  initial,

  /// Loading moderator hints and connecting streams.
  loading,

  /// Dashboard is active and ready.
  ready,

  /// An error occurred.
  error,
}

/// Immutable state for the [ProDashboardBloc].
class ProDashboardState extends Equatable {
  /// Dashboard loading/connection status.
  final ProDashboardStatus status;

  /// Room identifier.
  final String roomId;

  /// Current user's auth state (userId, displayName, role).
  final AuthState? authState;

  /// Current sub-level information (Zone 1).
  final SubLevelInfo? currentSublevel;

  /// Ordered list of user IDs in the speaking queue (Zone 2).
  final List<String> speakQueue;

  /// List of pinned resources (Zone 3).
  final List<PinnedResource> pinnedResources;

  /// Whether the user has moderator privileges.
  bool get canModerate => authState?.canModerate ?? false;

  /// Whether "Next Sub-level" button is in cooldown (3s after press).
  final bool isNextCooldown;

  /// Whether a pin-resource API call is in progress.
  final bool isPinning;

  /// Error message (non-null only when [status] == error).
  final String? errorMessage;

  const ProDashboardState({
    this.status = ProDashboardStatus.initial,
    this.roomId = '',
    this.authState,
    this.currentSublevel,
    this.speakQueue = const [],
    this.pinnedResources = const [],
    this.isNextCooldown = false,
    this.isPinning = false,
    this.errorMessage,
  });

  ProDashboardState copyWith({
    ProDashboardStatus? status,
    String? roomId,
    AuthState? authState,
    SubLevelInfo? currentSublevel,
    List<String>? speakQueue,
    List<PinnedResource>? pinnedResources,
    bool? isNextCooldown,
    bool? isPinning,
    String? errorMessage,
  }) {
    return ProDashboardState(
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      authState: authState ?? this.authState,
      currentSublevel: currentSublevel ?? this.currentSublevel,
      speakQueue: speakQueue ?? this.speakQueue,
      pinnedResources: pinnedResources ?? this.pinnedResources,
      isNextCooldown: isNextCooldown ?? this.isNextCooldown,
      isPinning: isPinning ?? this.isPinning,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        roomId,
        authState,
        currentSublevel,
        speakQueue,
        pinnedResources,
        isNextCooldown,
        isPinning,
        errorMessage,
      ];
}
