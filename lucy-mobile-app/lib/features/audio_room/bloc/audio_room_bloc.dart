// lib/features/audio_room/bloc/audio_room_bloc.dart
// ============================================================
// Project LUCY — AudioRoom BLoC
// Orchestrates Agora RTC + Socket.io + UI state for audio rooms.
//
// IMPORTANT: Socket event names match Node.js server (kebab-case).
// See lucy-realtime-service/index.js for server-side handlers.
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../model/room_user.dart';
import '../service/agora_service.dart';
import '../service/socket_service.dart';
import 'audio_room_event.dart';
import 'audio_room_state.dart';

/// BLoC that orchestrates the audio room's lifecycle.
///
/// Connects three systems:
/// 1. **Agora RTC** — audio streaming (join/leave channel, mic toggle)
/// 2. **Socket.io** — realtime room events (user connect, hand raise)
/// 3. **Flutter UI** — reactive state via BlocBuilder/BlocListener
///
/// Data flow:
/// ```
/// User Action → Event → BLoC → Service call → State update → UI rebuild
/// Socket Event → Stream → BLoC Event → State update → UI rebuild
/// Agora Callback → Stream → BLoC Event → State update → UI rebuild
/// ```
class AudioRoomBloc extends Bloc<AudioRoomEvent, AudioRoomState> {
  final AgoraService _agoraService;
  final SocketService _socketService;

  // Stream subscriptions for cleanup.
  final List<StreamSubscription> _subscriptions = [];

  AudioRoomBloc({
    required AgoraService agoraService,
    required SocketService socketService,
  })  : _agoraService = agoraService,
        _socketService = socketService,
        super(const AudioRoomState()) {
    // Register event handlers.
    on<AudioRoomJoinRequested>(_onJoinRequested);
    on<AudioRoomLeaveRequested>(_onLeaveRequested);
    on<AudioRoomMicToggled>(_onMicToggled);
    on<AudioRoomHandToggled>(_onHandToggled);
    on<AudioRoomRemoteUserJoined>(_onRemoteUserJoined);
    on<AudioRoomRemoteUserLeft>(_onRemoteUserLeft);
    on<AudioRoomHandQueueUpdated>(_onHandQueueUpdated);
    on<AudioRoomRemoteMicToggled>(_onRemoteMicToggled);
    on<AudioRoomSpeakingChanged>(_onSpeakingChanged);
  }

  // ── JOIN FLOW ─────────────────────────────────────────────

  Future<void> _onJoinRequested(
    AudioRoomJoinRequested event,
    Emitter<AudioRoomState> emit,
  ) async {
    emit(state.copyWith(
      status: AudioRoomStatus.connecting,
      roomId: event.roomId,
      channelName: event.channelName,
      currentUserId: event.userId,
      currentDisplayName: event.displayName,
    ));

    try {
      // Step 1: Request microphone permission.
      final hasPermission = await _agoraService.requestMicrophonePermission();
      if (!hasPermission) {
        emit(state.copyWith(
          status: AudioRoomStatus.error,
          errorMessage: 'Microphone permission denied. '
              'Please enable it in Settings.',
        ));
        return;
      }

      // Step 2: Initialize Agora engine.
      await _agoraService.initialize(AppConfig.agoraAppId);

      // Step 3: Connect to Socket.io server.
      _socketService.connect(AppConfig.socketServerUrl);

      // Step 4: Subscribe to Socket.io streams.
      _subscribeToSocketEvents();

      // Step 5: Subscribe to Agora volume indication.
      _subscribeToAgoraEvents();

      // Step 6: Emit join-room via Socket.io.
      // Matches: socket.on('join-room', (roomId, userId) => {...})
      _socketService.emitJoinRoom(
        roomId: event.roomId,
        userId: event.userId,
      );

      // Step 7: Join Agora voice channel.
      await _agoraService.joinChannel(
        channelName: event.channelName,
        token: event.agoraToken,
        uid: AppConfig.agoraDefaultUid,
      );

      // Start with mic OFF (muted by default).
      await _agoraService.toggleMic(false);

      emit(state.copyWith(
        status: AudioRoomStatus.connected,
        isMicOn: false,
      ));

      developer.log(
        '✅ Joined room: ${event.roomId}, channel: ${event.channelName}',
        name: 'AudioRoomBloc',
      );
    } catch (e) {
      developer.log(
        '❌ Join failed: $e',
        name: 'AudioRoomBloc',
        error: e,
      );
      emit(state.copyWith(
        status: AudioRoomStatus.error,
        errorMessage: 'Failed to join room: $e',
      ));
    }
  }

  // ── LEAVE FLOW ────────────────────────────────────────────

  Future<void> _onLeaveRequested(
    AudioRoomLeaveRequested event,
    Emitter<AudioRoomState> emit,
  ) async {
    developer.log('Leaving room: ${state.roomId}', name: 'AudioRoomBloc');

    try {
      // Notify server (server auto-handles disconnect too).
      _socketService.emitLeaveRoom(
        roomId: state.roomId,
        userId: state.currentUserId,
      );

      // Leave Agora channel.
      await _agoraService.leaveChannel();

      // Disconnect socket.
      _socketService.disconnect();

      // Cancel all stream subscriptions.
      _cancelSubscriptions();

      emit(state.copyWith(
        status: AudioRoomStatus.disconnected,
        users: [],
        handQueue: [],
        isMicOn: false,
        isHandRaised: false,
      ));
    } catch (e) {
      developer.log('Leave error: $e', name: 'AudioRoomBloc', error: e);
      emit(state.copyWith(status: AudioRoomStatus.disconnected));
    }
  }

  // ── MIC TOGGLE ────────────────────────────────────────────

  Future<void> _onMicToggled(
    AudioRoomMicToggled event,
    Emitter<AudioRoomState> emit,
  ) async {
    final newMicState = !state.isMicOn;

    // Toggle local audio via Agora.
    await _agoraService.toggleMic(newMicState);

    // Notify server via Socket.io (future server feature).
    _socketService.emitToggleMic(
      roomId: state.roomId,
      userId: state.currentUserId,
      isMuted: !newMicState,
    );

    emit(state.copyWith(isMicOn: newMicState));
  }

  // ── HAND TOGGLE ───────────────────────────────────────────

  Future<void> _onHandToggled(
    AudioRoomHandToggled event,
    Emitter<AudioRoomState> emit,
  ) async {
    final newHandState = !state.isHandRaised;

    if (newHandState) {
      // Matches: socket.on('raise-hand', (roomId, userId) => {...})
      _socketService.emitRaiseHand(
        roomId: state.roomId,
        userId: state.currentUserId,
      );
    }
    // Note: Server doesn't have 'lower-hand' yet — tracked locally only.

    emit(state.copyWith(isHandRaised: newHandState));
  }

  // ── SOCKET EVENT HANDLERS ────────────────────────────────

  void _onRemoteUserJoined(
    AudioRoomRemoteUserJoined event,
    Emitter<AudioRoomState> emit,
  ) {
    // Add user if not already present.
    final exists = state.users.any((u) => u.userId == event.user.userId);
    if (!exists) {
      emit(state.copyWith(users: [...state.users, event.user]));
    }
  }

  void _onRemoteUserLeft(
    AudioRoomRemoteUserLeft event,
    Emitter<AudioRoomState> emit,
  ) {
    final updated = state.users
        .where((u) => u.userId != event.userId)
        .toList();
    final updatedQueue = state.handQueue
        .where((id) => id != event.userId)
        .toList();
    emit(state.copyWith(users: updated, handQueue: updatedQueue));
  }

  void _onHandQueueUpdated(
    AudioRoomHandQueueUpdated event,
    Emitter<AudioRoomState> emit,
  ) {
    // Server emits 'user-raised-hand' with a single userId.
    // We add it to the local queue.
    final updatedQueue = [...state.handQueue];
    for (final userId in event.handQueue) {
      if (!updatedQueue.contains(userId)) {
        updatedQueue.add(userId);
      }
    }

    final isInQueue = updatedQueue.contains(state.currentUserId);
    emit(state.copyWith(
      handQueue: updatedQueue,
      isHandRaised: isInQueue,
    ));
  }

  void _onRemoteMicToggled(
    AudioRoomRemoteMicToggled event,
    Emitter<AudioRoomState> emit,
  ) {
    final updatedUsers = state.users.map((user) {
      if (user.userId == event.userId) {
        return user.copyWith(isMuted: event.isMuted);
      }
      return user;
    }).toList();

    emit(state.copyWith(users: updatedUsers));
  }

  // ── AGORA EVENT HANDLERS ─────────────────────────────────

  void _onSpeakingChanged(
    AudioRoomSpeakingChanged event,
    Emitter<AudioRoomState> emit,
  ) {
    final updatedUsers = state.users.map((user) {
      if (user.agoraUid == event.agoraUid) {
        return user.copyWith(isSpeaking: event.isSpeaking);
      }
      return user;
    }).toList();

    emit(state.copyWith(users: updatedUsers));
  }

  // ── STREAM SUBSCRIPTIONS ─────────────────────────────────

  /// Subscribes to Socket.io event streams and maps them to BLoC events.
  ///
  /// Stream names match the updated SocketService which uses
  /// kebab-case event names from the Node.js server.
  void _subscribeToSocketEvents() {
    _subscriptions.addAll([
      // Server: socket.to(roomId).emit('user-connected', userId)
      _socketService.onUserConnected.listen((userId) {
        // Server only sends userId string, create a minimal RoomUser.
        final user = RoomUser(
          userId: userId,
          displayName: 'Anonymous User',
          personaIndex: userId.hashCode % 10,
        );
        add(AudioRoomRemoteUserJoined(user));
      }),

      // Server: io.to(roomId).emit('user-raised-hand', userId)
      _socketService.onUserRaisedHand.listen((userId) {
        add(AudioRoomHandQueueUpdated([userId]));
      }),

      // Server: auto-detected on disconnect
      _socketService.onUserDisconnected.listen((userId) {
        add(AudioRoomRemoteUserLeft(userId));
      }),

      // Future: server mic-toggled event
      _socketService.onMicToggled.listen((data) {
        add(AudioRoomRemoteMicToggled(
          userId: data['userId'] as String? ?? '',
          isMuted: data['isMuted'] as bool? ?? true,
        ));
      }),
    ]);
  }

  /// Subscribes to Agora volume indication and maps to speaking events.
  void _subscribeToAgoraEvents() {
    _subscriptions.add(
      _agoraService.onVolumeIndication.listen((speakers) {
        for (final speaker in speakers) {
          final isSpeaking =
              (speaker.volume ?? 0) > AppConfig.agoraSpeakingThreshold;
          add(AudioRoomSpeakingChanged(
            agoraUid: speaker.uid ?? 0,
            isSpeaking: isSpeaking,
          ));
        }
      }),
    );
  }

  /// Cancels all active stream subscriptions.
  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  // ── CLEANUP ───────────────────────────────────────────────

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
