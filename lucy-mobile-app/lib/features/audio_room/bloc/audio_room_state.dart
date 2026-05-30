// lib/features/audio_room/bloc/audio_room_state.dart
// ============================================================
// Project LUCY — AudioRoom BLoC State
// Immutable state representing the audio room's current status.
// ============================================================

import 'package:equatable/equatable.dart';
import '../model/room_user.dart';

/// Connection status of the audio room.
enum AudioRoomStatus {
  /// Initial state before any action.
  initial,

  /// Requesting permissions, initializing Agora, connecting Socket.
  connecting,

  /// Successfully joined the room. Audio active.
  connected,

  /// Intentionally disconnected (user left).
  disconnected,

  /// An error occurred during connection or in-room operation.
  error,
}

/// Immutable state for the [AudioRoomBloc].
///
/// Uses [Equatable] for efficient state comparison in BlocBuilder.
class AudioRoomState extends Equatable {
  /// Current connection status.
  final AudioRoomStatus status;

  /// Room identifier.
  final String roomId;

  /// Agora channel name.
  final String channelName;

  /// All participants currently in the room.
  final List<RoomUser> users;

  /// Ordered list of user IDs who have raised their hand.
  /// First element = next in queue to speak.
  final List<String> handQueue;

  /// Whether the current user's microphone is on.
  final bool isMicOn;

  /// Whether the current user has raised their hand.
  final bool isHandRaised;

  /// Current user's ID.
  final String currentUserId;

  /// Current user's display name.
  final String currentDisplayName;

  /// Error message (non-null only when [status] == error).
  final String? errorMessage;

  const AudioRoomState({
    this.status = AudioRoomStatus.initial,
    this.roomId = '',
    this.channelName = '',
    this.users = const [],
    this.handQueue = const [],
    this.isMicOn = false,
    this.isHandRaised = false,
    this.currentUserId = '',
    this.currentDisplayName = '',
    this.errorMessage,
  });

  /// Creates a copy with the specified fields replaced.
  AudioRoomState copyWith({
    AudioRoomStatus? status,
    String? roomId,
    String? channelName,
    List<RoomUser>? users,
    List<String>? handQueue,
    bool? isMicOn,
    bool? isHandRaised,
    String? currentUserId,
    String? currentDisplayName,
    String? errorMessage,
  }) {
    return AudioRoomState(
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      channelName: channelName ?? this.channelName,
      users: users ?? this.users,
      handQueue: handQueue ?? this.handQueue,
      isMicOn: isMicOn ?? this.isMicOn,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      currentUserId: currentUserId ?? this.currentUserId,
      currentDisplayName: currentDisplayName ?? this.currentDisplayName,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        roomId,
        channelName,
        users,
        handQueue,
        isMicOn,
        isHandRaised,
        currentUserId,
        currentDisplayName,
        errorMessage,
      ];
}
