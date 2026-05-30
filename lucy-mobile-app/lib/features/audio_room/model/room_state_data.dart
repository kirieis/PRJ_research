// lib/features/audio_room/model/room_state_data.dart
// ============================================================
// Project LUCY — Aggregated Room State Model
// Full snapshot of room state received from Socket.io server.
// ============================================================

import 'package:equatable/equatable.dart';
import 'room_user.dart';

/// Aggregated room state data from the Socket.io `room_state_updated` event.
///
/// This represents a full snapshot of the room, including all participants
/// and the current hand-raise queue. The BLoC uses this to reconcile
/// its local state with the server's authoritative state.
class RoomStateData extends Equatable {
  /// Unique room identifier.
  final String roomId;

  /// Agora channel name for audio streaming.
  final String channelName;

  /// List of all current participants.
  final List<RoomUser> users;

  /// Ordered list of user IDs in the hand-raise queue.
  /// First item = next to speak.
  final List<String> handQueue;

  /// User ID of the room host (teacher/moderator).
  final String hostId;

  const RoomStateData({
    required this.roomId,
    required this.channelName,
    this.users = const [],
    this.handQueue = const [],
    this.hostId = '',
  });

  /// Constructs from a JSON map (Socket.io payload).
  factory RoomStateData.fromJson(Map<String, dynamic> json) {
    return RoomStateData(
      roomId: json['roomId'] as String? ?? '',
      channelName: json['channelName'] as String? ?? '',
      users: (json['users'] as List<dynamic>?)
              ?.map((u) => RoomUser.fromJson(u as Map<String, dynamic>))
              .toList() ??
          [],
      handQueue: (json['handQueue'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      hostId: json['hostId'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [roomId, channelName, users, handQueue, hostId];
}
