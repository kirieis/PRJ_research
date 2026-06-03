// lib/features/audio_room/bloc/speak_queue_bloc.dart
// ============================================================
// Project LUCY — SpeakQueue BLoC (Dev 5)
//
// FIXED (Audit):
//   ✅ Cancel old subscriptions trước khi tạo mới trong _onRoomJoined
//   ✅ Thêm _onRoomLeft handler (leave_room + cleanup)
//   ✅ Thêm _onMicToggled handler (toggle_mic)
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../service/socket_service.dart';
import 'speak_queue_event.dart';
import 'speak_queue_state.dart';

class SpeakQueueBloc extends Bloc<SpeakQueueEvent, SpeakQueueState> {
  final SocketService _socketService;
  StreamSubscription? _queueSub;
  StreamSubscription? _connSub;

  SpeakQueueBloc({required SocketService socketService})
      : _socketService = socketService,
        super(const SpeakQueueState()) {
    on<SpeakQueueRoomJoined>(_onRoomJoined);
    on<SpeakQueueRoomLeft>(_onRoomLeft);
    on<SpeakQueueUpdated>(_onQueueUpdated);
    on<SpeakQueueHandRaised>(_onHandRaised);
    on<SpeakQueueMicToggled>(_onMicToggled);
    on<SpeakQueueConnectionChanged>(_onConnectionChanged);
  }

  void _onRoomJoined(
    SpeakQueueRoomJoined event,
    Emitter<SpeakQueueState> emit,
  ) {
    // FIX: Cancel old subscriptions trước khi tạo mới — tránh leak.
    _queueSub?.cancel();
    _connSub?.cancel();

    _socketService.connect(jwtToken: event.jwtToken);

    // Listen for queue updates from server.
    _queueSub = _socketService.handQueueStream.listen((queue) {
      add(SpeakQueueUpdated(queue: queue));
    });

    // Listen for connection changes.
    _connSub = _socketService.connectionStream.listen((connected) {
      add(SpeakQueueConnectionChanged(isConnected: connected));
    });

    // Emit join_room.
    _socketService.emitJoinRoom(roomId: event.roomId, userId: event.userId);

    developer.log(
      '🎙 Joined room: ${event.roomId} as ${event.userId}',
      name: 'SpeakQueueBloc',
    );

    emit(state.copyWith(
      roomId: event.roomId,
      userId: event.userId,
      isMuted: true,
    ));
  }

  void _onRoomLeft(
    SpeakQueueRoomLeft event,
    Emitter<SpeakQueueState> emit,
  ) {
    if (state.roomId != null && state.userId != null) {
      _socketService.emitLeaveRoom(
        roomId: state.roomId!,
        userId: state.userId!,
      );
    }

    _queueSub?.cancel();
    _connSub?.cancel();
    _queueSub = null;
    _connSub = null;

    developer.log('👋 Left room: ${state.roomId}', name: 'SpeakQueueBloc');

    emit(const SpeakQueueState());
  }

  void _onQueueUpdated(
    SpeakQueueUpdated event,
    Emitter<SpeakQueueState> emit,
  ) {
    developer.log(
      '🎙 Queue updated: ${event.queue.length} items',
      name: 'SpeakQueueBloc',
    );
    emit(state.copyWith(queue: event.queue));
  }

  void _onHandRaised(
    SpeakQueueHandRaised event,
    Emitter<SpeakQueueState> emit,
  ) {
    if (state.roomId != null && state.userId != null) {
      _socketService.emitRaiseHand(
        roomId: state.roomId!,
        userId: state.userId!,
      );
      developer.log(
        '🙋 Hand raised by ${state.userId}',
        name: 'SpeakQueueBloc',
      );
    }
  }

  void _onMicToggled(
    SpeakQueueMicToggled event,
    Emitter<SpeakQueueState> emit,
  ) {
    if (state.roomId != null && state.userId != null) {
      _socketService.emitToggleMic(
        roomId: state.roomId!,
        userId: state.userId!,
        isMuted: event.isMuted,
      );
      developer.log(
        '🎤 Mic ${event.isMuted ? "muted" : "unmuted"} by ${state.userId}',
        name: 'SpeakQueueBloc',
      );
      emit(state.copyWith(isMuted: event.isMuted));
    }
  }

  void _onConnectionChanged(
    SpeakQueueConnectionChanged event,
    Emitter<SpeakQueueState> emit,
  ) {
    developer.log(
      '🔌 Connection: ${event.isConnected ? "connected" : "disconnected"}',
      name: 'SpeakQueueBloc',
    );
    emit(state.copyWith(isConnected: event.isConnected));
  }

  @override
  Future<void> close() {
    _queueSub?.cancel();
    _connSub?.cancel();
    _socketService.dispose();
    return super.close();
  }
}
