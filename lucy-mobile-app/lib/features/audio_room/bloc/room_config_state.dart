// lib/features/audio_room/bloc/room_config_state.dart
// ============================================================
// Project LUCY — RoomConfig BLoC State
//
// Immutable state holding:
//   - isAvatarHidden: whether the user's avatar is masked
//   - selectedFilter: current voice filter preset
//   - isTestingVoice: whether a voice test is in progress
//   - testProgress: 0.0 → 1.0 playback progress
// ============================================================

import 'package:equatable/equatable.dart';
import 'room_config_event.dart';

class RoomConfigState extends Equatable {
  final bool isAvatarHidden;
  final VoiceFilterType selectedFilter;
  final bool isTestingVoice;
  final double testProgress;

  const RoomConfigState({
    this.isAvatarHidden = false,
    this.selectedFilter = VoiceFilterType.normal,
    this.isTestingVoice = false,
    this.testProgress = 0.0,
  });

  RoomConfigState copyWith({
    bool? isAvatarHidden,
    VoiceFilterType? selectedFilter,
    bool? isTestingVoice,
    double? testProgress,
  }) {
    return RoomConfigState(
      isAvatarHidden: isAvatarHidden ?? this.isAvatarHidden,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isTestingVoice: isTestingVoice ?? this.isTestingVoice,
      testProgress: testProgress ?? this.testProgress,
    );
  }

  @override
  List<Object?> get props => [
        isAvatarHidden,
        selectedFilter,
        isTestingVoice,
        testProgress,
      ];
}
