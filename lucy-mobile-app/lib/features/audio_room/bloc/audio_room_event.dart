// lib/features/audio_room/bloc/audio_room_event.dart
// ============================================================
// Project LUCY — AudioRoom BLoC Events
// All events that can be dispatched to AudioRoomBloc.
// ============================================================

import 'package:equatable/equatable.dart';
import '../model/room_user.dart';

/// Base class for all audio room events.
sealed class AudioRoomEvent extends Equatable {
  const AudioRoomEvent();

  @override
  List<Object?> get props => [];
}

// ── User-initiated Events ──────────────────────────────────

/// User wants to join the audio room.
/// Triggers: permission request → Agora init → Socket connect → join channel.
class AudioRoomJoinRequested extends AudioRoomEvent {
  final String roomId;
  final String channelName;
  final String userId;
  final String displayName;
  final String? agoraToken;

  const AudioRoomJoinRequested({
    required this.roomId,
    required this.channelName,
    required this.userId,
    required this.displayName,
    this.agoraToken,
  });

  @override
  List<Object?> get props => [roomId, channelName, userId, displayName, agoraToken];
}

/// User wants to leave the audio room.
class AudioRoomLeaveRequested extends AudioRoomEvent {
  const AudioRoomLeaveRequested();
}

/// User taps the microphone toggle button.
class AudioRoomMicToggled extends AudioRoomEvent {
  const AudioRoomMicToggled();
}

/// User taps the raise/lower hand button.
class AudioRoomHandToggled extends AudioRoomEvent {
  const AudioRoomHandToggled();
}

// ── Socket-driven Events (Server → Client) ─────────────────
// Event names correspond to Node.js server emissions (kebab-case).
// Server: 'user-connected' → AudioRoomRemoteUserJoined
// Server: 'user-raised-hand' → AudioRoomHandQueueUpdated

/// A remote user joined the room (Socket.io event).
class AudioRoomRemoteUserJoined extends AudioRoomEvent {
  final RoomUser user;

  const AudioRoomRemoteUserJoined(this.user);

  @override
  List<Object?> get props => [user];
}

/// A remote user left the room (Socket.io event).
class AudioRoomRemoteUserLeft extends AudioRoomEvent {
  final String userId;

  const AudioRoomRemoteUserLeft(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// The hand-raise queue was updated (Socket.io event).
class AudioRoomHandQueueUpdated extends AudioRoomEvent {
  final List<String> handQueue;

  const AudioRoomHandQueueUpdated(this.handQueue);

  @override
  List<Object?> get props => [handQueue];
}

/// A remote user toggled their mic (Socket.io event).
class AudioRoomRemoteMicToggled extends AudioRoomEvent {
  final String userId;
  final bool isMuted;

  const AudioRoomRemoteMicToggled({
    required this.userId,
    required this.isMuted,
  });

  @override
  List<Object?> get props => [userId, isMuted];
}

// ── Agora-driven Events ────────────────────────────────────

/// Audio volume indication: a user's speaking state changed.
/// Triggered by Agora's onAudioVolumeIndication callback.
class AudioRoomSpeakingChanged extends AudioRoomEvent {
  final int agoraUid;
  final bool isSpeaking;

  const AudioRoomSpeakingChanged({
    required this.agoraUid,
    required this.isSpeaking,
  });

  @override
  List<Object?> get props => [agoraUid, isSpeaking];
}
