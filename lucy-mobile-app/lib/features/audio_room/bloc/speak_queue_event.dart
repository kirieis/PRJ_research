// lib/features/audio_room/bloc/speak_queue_event.dart
// ============================================================
// Project LUCY — SpeakQueue BLoC Events (Dev 5)
//
// FIXED (Audit): Thêm SpeakQueueRoomLeft + SpeakQueueMicToggled
// ============================================================

import 'package:equatable/equatable.dart';

abstract class SpeakQueueEvent extends Equatable {
  const SpeakQueueEvent();
  @override
  List<Object?> get props => [];
}

/// User joined a room — initialize socket connection.
class SpeakQueueRoomJoined extends SpeakQueueEvent {
  final String roomId;
  final String userId;
  final String? jwtToken;
  const SpeakQueueRoomJoined({
    required this.roomId,
    required this.userId,
    this.jwtToken,
  });
  @override
  List<Object?> get props => [roomId, userId, jwtToken];
}

/// User left the room — cleanup socket connection.
class SpeakQueueRoomLeft extends SpeakQueueEvent {
  const SpeakQueueRoomLeft();
}

/// Server sent an updated hand queue.
class SpeakQueueUpdated extends SpeakQueueEvent {
  final List<Map<String, dynamic>> queue;
  const SpeakQueueUpdated({required this.queue});
  @override
  List<Object?> get props => [queue];
}

/// User raised hand to speak.
class SpeakQueueHandRaised extends SpeakQueueEvent {
  const SpeakQueueHandRaised();
}

/// User toggled microphone.
class SpeakQueueMicToggled extends SpeakQueueEvent {
  final bool isMuted;
  const SpeakQueueMicToggled({required this.isMuted});
  @override
  List<Object?> get props => [isMuted];
}

/// Socket connection status changed.
class SpeakQueueConnectionChanged extends SpeakQueueEvent {
  final bool isConnected;
  const SpeakQueueConnectionChanged({required this.isConnected});
  @override
  List<Object?> get props => [isConnected];
}
