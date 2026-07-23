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

import '../service/agora_service.dart';
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

  Future<void> _onRoomJoined(
    SpeakQueueRoomJoined event,
    Emitter<SpeakQueueState> emit,
  ) async {
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

    // Bật Mic thời gian thực qua Agora SDK
    try {
      if (!AgoraService.instance.isInitialized) {
        // Đảm bảo khởi tạo nếu chưa qua màn cấu hình
        await AgoraService.instance.init('1234567890abcdef1234567890abcdef');
      }
      await AgoraService.instance.requestMicPermission();
      await AgoraService.instance.joinChannel(AgoraConfig(
        appId: '1234567890abcdef1234567890abcdef',
        channelName: event.roomId,
        uid: int.tryParse(event.userId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      ));

      // Mở mic ngay khi vào phòng
      await AgoraService.instance.setMicMuted(false);
    } catch (e) {
      developer.log('⚠️ Agora setup failed (non-fatal): $e',
          name: 'SpeakQueueBloc');
    }

    developer.log(
      '🎙 Joined room: ${event.roomId} as ${event.userId} (Agora connected, Mic ON)',
      name: 'SpeakQueueBloc',
    );

    emit(state.copyWith(
      roomId: event.roomId,
      userId: event.userId,
      isMuted: false,
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
    
    // Rời kênh Agora
    AgoraService.instance.leaveChannel();

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

  Future<void> _onMicToggled(
    SpeakQueueMicToggled event,
    Emitter<SpeakQueueState> emit,
  ) async {
    if (state.roomId != null && state.userId != null) {
      _socketService.emitToggleMic(
        roomId: state.roomId!,
        userId: state.userId!,
        isMuted: event.isMuted,
      );
      
      // Đồng bộ mic thật với Agora
      await AgoraService.instance.setMicMuted(event.isMuted);

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
    // NOTE: Do NOT dispose SocketService here — it's a singleton shared
    // across routes. Disposing it would break other BLoCs using the same
    // service. SocketService lifecycle is managed at app level.
    return super.close();
  }
}
