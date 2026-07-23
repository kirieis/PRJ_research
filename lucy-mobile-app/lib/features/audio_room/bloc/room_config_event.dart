// lib/features/audio_room/bloc/room_config_event.dart
// ============================================================
// Project LUCY — RoomConfig BLoC Events
//
// Events for room configuration:
//   - Toggle avatar visibility (hide/show)
//   - Select voice filter preset
//   - Test voice with current filter
//   - Confirm settings and enter room
// ============================================================

import 'package:equatable/equatable.dart';

abstract class RoomConfigEvent extends Equatable {
  const RoomConfigEvent();
  @override
  List<Object?> get props => [];
}

/// User toggled the "Hide Avatar" switch.
class RoomConfigAvatarToggled extends RoomConfigEvent {
  final bool isHidden;
  const RoomConfigAvatarToggled({required this.isHidden});
  @override
  List<Object?> get props => [isHidden];
}

/// User selected a voice filter preset.
class RoomConfigVoiceFilterSelected extends RoomConfigEvent {
  final VoiceFilterType filter;
  const RoomConfigVoiceFilterSelected({required this.filter});
  @override
  List<Object?> get props => [filter];
}

/// User pressed the "Test Voice" button.
class RoomConfigTestVoiceStarted extends RoomConfigEvent {
  const RoomConfigTestVoiceStarted();
}

/// Progress tick during voice test playback.
class RoomConfigTestVoiceProgressUpdated extends RoomConfigEvent {
  final double progress;
  const RoomConfigTestVoiceProgressUpdated({required this.progress});
  @override
  List<Object?> get props => [progress];
}

/// Test voice playback completed.
class RoomConfigTestVoiceCompleted extends RoomConfigEvent {
  const RoomConfigTestVoiceCompleted();
}

/// User confirmed settings — ready to enter room.
class RoomConfigConfirmed extends RoomConfigEvent {
  const RoomConfigConfirmed();
}

/// Voice filter preset types.
enum VoiceFilterType {
  normal,
  warm,
  robot,
  cartoon,
  deep,
  echo,
}
