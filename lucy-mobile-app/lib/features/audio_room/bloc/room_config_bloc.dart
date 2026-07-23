// lib/features/audio_room/bloc/room_config_bloc.dart
// ============================================================
// Project LUCY — RoomConfig BLoC
//
// Manages room configuration state:
//   ✅ Avatar visibility toggle (ẩn/hiện)
//   ✅ Voice filter selection
//   ✅ Test voice simulation (3-second mock playback)
//   ✅ Settings confirmation
//
// FIX: Sử dụng Timer.periodic + add(event) pattern thay vì
//      emit() ngoài handler scope (gây crash BLoC).
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../service/agora_service.dart';
import 'room_config_event.dart';
import 'room_config_state.dart';

class RoomConfigBloc extends Bloc<RoomConfigEvent, RoomConfigState> {
  Timer? _testVoiceTimer;
  static const _agoraAppId =
      '1234567890abcdef1234567890abcdef'; // Thay bằng App ID thật

  RoomConfigBloc() : super(const RoomConfigState()) {
    // Khởi tạo Agora khi mở cấu hình
    _initAgora();

    on<RoomConfigAvatarToggled>(_onAvatarToggled);
    on<RoomConfigVoiceFilterSelected>(_onVoiceFilterSelected);
    on<RoomConfigTestVoiceStarted>(_onTestVoiceStarted);
    on<RoomConfigTestVoiceProgressUpdated>(_onTestVoiceProgress);
    on<RoomConfigTestVoiceCompleted>(_onTestVoiceCompleted);
    on<RoomConfigConfirmed>(_onConfirmed);
  }

  Future<void> _initAgora() async {
    try {
      await AgoraService.instance.init(_agoraAppId);
      await AgoraService.instance.requestMicPermission();
    } catch (e) {
      developer.log('Failed to init Agora in RoomConfig: $e',
          name: 'RoomConfigBloc');
    }
  }

  void _onAvatarToggled(
    RoomConfigAvatarToggled event,
    Emitter<RoomConfigState> emit,
  ) {
    developer.log(
      '👤 Avatar ${event.isHidden ? "hidden" : "visible"}',
      name: 'RoomConfigBloc',
    );
    emit(state.copyWith(isAvatarHidden: event.isHidden));
  }

  void _onVoiceFilterSelected(
    RoomConfigVoiceFilterSelected event,
    Emitter<RoomConfigState> emit,
  ) {
    developer.log(
      '🎵 Voice filter: ${event.filter.name}',
      name: 'RoomConfigBloc',
    );

    // Áp dụng bộ lọc ngay vào Agora để người dùng nghe thử
    AgoraService.instance.setVoiceFilter(event.filter);

    emit(state.copyWith(selectedFilter: event.filter));
  }

  void _onTestVoiceStarted(
    RoomConfigTestVoiceStarted event,
    Emitter<RoomConfigState> emit,
  ) {
    if (state.isTestingVoice) return;

    developer.log(
      '🔊 Testing voice with filter: ${state.selectedFilter.name}',
      name: 'RoomConfigBloc',
    );

    // Bật In-Ear Monitoring để nghe thử giọng thật
    AgoraService.instance.startTestVoice();

    emit(state.copyWith(isTestingVoice: true, testProgress: 0.0));

    // Simulate 3-second voice test playback using Timer.periodic.
    int tick = 0;
    const totalTicks = 30; // 30 ticks × 100ms = 3 seconds

    _testVoiceTimer?.cancel();
    _testVoiceTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        tick++;
        if (tick >= totalTicks) {
          timer.cancel();
          add(const RoomConfigTestVoiceCompleted());
        } else {
          add(RoomConfigTestVoiceProgressUpdated(
            progress: tick / totalTicks,
          ));
        }
      },
    );
  }

  void _onTestVoiceProgress(
    RoomConfigTestVoiceProgressUpdated event,
    Emitter<RoomConfigState> emit,
  ) {
    if (!state.isTestingVoice) return;
    emit(state.copyWith(testProgress: event.progress));
  }

  void _onTestVoiceCompleted(
    RoomConfigTestVoiceCompleted event,
    Emitter<RoomConfigState> emit,
  ) {
    _testVoiceTimer?.cancel();
    _testVoiceTimer = null;

    // Tắt Test Voice (In-Ear Monitoring)
    AgoraService.instance.stopTestVoice();

    developer.log('✅ Voice test completed', name: 'RoomConfigBloc');
    emit(state.copyWith(isTestingVoice: false, testProgress: 0.0));
  }

  void _onConfirmed(
    RoomConfigConfirmed event,
    Emitter<RoomConfigState> emit,
  ) {
    developer.log(
      '✅ Config confirmed — Avatar hidden: ${state.isAvatarHidden}, '
      'Filter: ${state.selectedFilter.name}',
      name: 'RoomConfigBloc',
    );
  }

  @override
  Future<void> close() {
    _testVoiceTimer?.cancel();
    return super.close();
  }
}
