// lib/features/audio_room/service/socket_service.dart
// ============================================================
// Project LUCY — Socket.io Client Service
// Connects to the Node.js realtime server for room events.
//
// IMPORTANT: Event names MUST match the Node.js server (index.js).
// Server uses kebab-case: 'join-room', 'raise-hand', etc.
// Server emits: 'user-connected', 'user-raised-hand', 'receive-gift'
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;

import 'package:socket_io_client/socket_io_client.dart' as io;

/// Service managing Socket.io connection to the Node.js realtime server.
///
/// Handles:
/// - Connecting/disconnecting with JWT auth
/// - Emitting room events (join, leave, raise hand, toggle mic)
/// - Listening for server broadcasts and exposing them as Dart streams
///
/// **Event name convention**: The Node.js server (`lucy-realtime-service/index.js`)
/// uses **kebab-case** event names. This client MUST match exactly:
/// - Client emits: `join-room`, `raise-hand`, `send-gift`
/// - Server emits: `user-connected`, `user-raised-hand`, `receive-gift`
///
/// Usage:
/// ```dart
/// final socket = SocketService();
/// socket.connect('http://localhost:3001', token: 'jwt-token');
/// socket.emitJoinRoom(roomId: 'room-1', userId: 'usr-1');
/// socket.onUserConnected.listen((userId) => print(userId));
/// ```
class SocketService {
  /// The underlying socket.io client instance.
  io.Socket? _socket;

  /// Whether the socket is currently connected.
  bool get isConnected => _socket?.connected ?? false;

  // ── Stream Controllers (broadcast) ────────────────────────
  // Each server event is exposed as a Dart stream for BLoC consumption.

  final _onUserConnectedController = StreamController<String>.broadcast();
  final _onUserRaisedHandController = StreamController<String>.broadcast();
  final _onUserDisconnectedController = StreamController<String>.broadcast();
  final _onMicToggledController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onErrorController = StreamController<String>.broadcast();

  // Pro Dashboard stream controllers (Dev 4 events).
  final _onNextSublevelController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onRoomStateUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// A remote user joined the room.
  /// Payload: userId (String) — matches server `'user-connected'` event.
  Stream<String> get onUserConnected => _onUserConnectedController.stream;

  /// A remote user raised their hand.
  /// Payload: userId (String) — matches server `'user-raised-hand'` event.
  Stream<String> get onUserRaisedHand => _onUserRaisedHandController.stream;

  /// A remote user disconnected.
  /// Payload: userId (String).
  Stream<String> get onUserDisconnected => _onUserDisconnectedController.stream;

  /// A user toggled their microphone (future server feature).
  /// Payload: {userId, isMuted}.
  Stream<Map<String, dynamic>> get onMicToggled =>
      _onMicToggledController.stream;

  /// Server-side errors.
  Stream<String> get onError => _onErrorController.stream;

  /// Sub-level advanced (auto by timer or forced by moderator).
  /// Payload: {subLevelId, title, index, totalCount}
  /// Source: Dev 4 server event `'next-sublevel'`.
  Stream<Map<String, dynamic>> get onNextSublevel =>
      _onNextSublevelController.stream;

  /// Full room state snapshot (includes current sub-level, users, etc.).
  /// Source: Dev 4 server event `'room-state-updated'`.
  Stream<Map<String, dynamic>> get onRoomStateUpdated =>
      _onRoomStateUpdatedController.stream;

  // ── Connection ────────────────────────────────────────────

  /// Connects to the Socket.io server.
  ///
  /// [serverUrl]: URL of the Node.js realtime server.
  /// [token]: JWT access token for authentication.
  void connect(String serverUrl, {String? token}) {
    developer.log(
      'Connecting to Socket.io server: $serverUrl',
      name: 'SocketService',
    );

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket']) // WebSocket only, skip polling
          .disableAutoConnect() // Manual connect after setup
          .setAuth({'token': token ?? ''}) // JWT in handshake
          .enableReconnection() // Auto-reconnect on disconnect
          .setReconnectionDelay(1000) // 1 second initial delay
          .setReconnectionDelayMax(5000) // Max 5 seconds between retries
          .build(),
    );

    // Register listeners before connecting.
    _registerListeners();

    // Initiate connection.
    _socket!.connect();
  }

  /// Disconnects from the Socket.io server.
  void disconnect() {
    developer.log('Disconnecting from Socket.io server.',
        name: 'SocketService');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ── Emit Events (Client → Server) ────────────────────────
  // Event names MUST match Node.js server (kebab-case).
  //
  // Server signature: socket.on('join-room', (roomId, userId) => { ... })
  // → We emit TWO separate arguments, NOT a single object.

  /// Emits `join-room` event to enter an audio room.
  ///
  /// Matches server: `socket.on('join-room', (roomId, userId) => { ... })`
  /// Note: Server expects 2 positional arguments, not a JSON object.
  void emitJoinRoom({
    required String roomId,
    required String userId,
  }) {
    if (_socket == null || !isConnected) {
      developer.log(
        '⚠️ Cannot emit "join-room": socket not connected.',
        name: 'SocketService',
      );
      return;
    }
    developer.log(
      '📤 Emit "join-room": roomId=$roomId, userId=$userId',
      name: 'SocketService',
    );
    // Server expects: socket.on('join-room', (roomId, userId) => {...})
    // socket_io_client emits multiple args via list.
    _socket!.emit('join-room', [roomId, userId]);
  }

  /// Emits `raise-hand` event to join the speaking queue.
  ///
  /// Matches server: `socket.on('raise-hand', (roomId, userId) => { ... })`
  void emitRaiseHand({required String roomId, required String userId}) {
    if (_socket == null || !isConnected) {
      developer.log(
        '⚠️ Cannot emit "raise-hand": socket not connected.',
        name: 'SocketService',
      );
      return;
    }
    developer.log(
      '📤 Emit "raise-hand": roomId=$roomId, userId=$userId',
      name: 'SocketService',
    );
    _socket!.emit('raise-hand', [roomId, userId]);
  }

  /// Emits `send-gift` event.
  ///
  /// Matches server: `socket.on('send-gift', (roomId, data) => { ... })`
  void emitSendGift({
    required String roomId,
    required Map<String, dynamic> giftData,
  }) {
    if (_socket == null || !isConnected) {
      developer.log(
        '⚠️ Cannot emit "send-gift": socket not connected.',
        name: 'SocketService',
      );
      return;
    }
    developer.log(
      '📤 Emit "send-gift": roomId=$roomId',
      name: 'SocketService',
    );
    _socket!.emit('send-gift', [roomId, giftData]);
  }

  // ── Events NOT yet implemented on server ──────────────────
  // These are prepared for future server endpoints.
  // They will work once the Node.js team adds the matching handlers.

  /// Emits `leave-room` event to exit the audio room.
  /// NOTE: Server does not handle this yet — disconnect is auto-detected.
  void emitLeaveRoom({required String roomId, required String userId}) {
    _emitOrLog('leave-room', [roomId, userId]);
  }

  /// Emits `toggle-mic` event to notify others of mic state change.
  /// NOTE: Server does not handle this yet — prepared for future use.
  void emitToggleMic({
    required String roomId,
    required String userId,
    required bool isMuted,
  }) {
    _emitOrLog('toggle-mic', [
      roomId,
      {'userId': userId, 'isMuted': isMuted},
    ]);
  }

  // ── Pro Dashboard Events (Dev 4 server handlers) ──────────

  /// Emits `force-next-sublevel` — moderator forces sub-level advance.
  /// Server handler: Dev 4 — broadcasts `next-sublevel` to all in room.
  void emitForceNextSublevel(String roomId) {
    _emitOrLog('force-next-sublevel', [roomId]);
  }

  /// Emits `approve-speaker` — moderator approves a queued speaker.
  /// Server handler: Dev 4 — unmutes the user and broadcasts update.
  void emitApproveSpeaker({required String roomId, required String userId}) {
    _emitOrLog('approve-speaker', [roomId, userId]);
  }

  /// Emits `skip-speaker` — moderator skips a queued speaker.
  /// Server handler: Dev 4 — removes user from queue and broadcasts.
  void emitSkipSpeaker({required String roomId, required String userId}) {
    _emitOrLog('skip-speaker', [roomId, userId]);
  }

  // ── Private: Register Listeners (Server → Client) ────────
  // Event names MUST match what the Node.js server emits.

  void _registerListeners() {
    final socket = _socket;
    if (socket == null) return;

    // Connection lifecycle events.
    socket.onConnect((_) {
      developer.log('✅ Socket connected: ${socket.id}',
          name: 'SocketService');
    });

    socket.onDisconnect((_) {
      developer.log('⚠️ Socket disconnected.', name: 'SocketService');
    });

    socket.onConnectError((error) {
      developer.log('❌ Socket connect error: $error', name: 'SocketService');
      _onErrorController.add('Connection error: $error');
    });

    socket.onReconnect((_) {
      developer.log('🔄 Socket reconnected.', name: 'SocketService');
    });

    // ── Room Events (matching server emit names) ──────────

    // Server: socket.to(roomId).emit('user-connected', userId)
    socket.on('user-connected', (data) {
      developer.log('👤 user-connected: $data', name: 'SocketService');
      if (data is String) {
        _onUserConnectedController.add(data);
      }
    });

    // Server: io.to(roomId).emit('user-raised-hand', userId)
    socket.on('user-raised-hand', (data) {
      developer.log('✋ user-raised-hand: $data', name: 'SocketService');
      if (data is String) {
        _onUserRaisedHandController.add(data);
      }
    });

    // Server: Currently only uses socket disconnect event.
    // Prepared for explicit 'user-disconnected' if server adds it.
    socket.on('user-disconnected', (data) {
      developer.log('👤 user-disconnected: $data', name: 'SocketService');
      if (data is String) {
        _onUserDisconnectedController.add(data);
      }
    });

    // Future server events — prepared for when Node.js team adds them.
    socket.on('mic-toggled', (data) {
      developer.log('🎤 mic-toggled: $data', name: 'SocketService');
      if (data is Map<String, dynamic>) {
        _onMicToggledController.add(data);
      }
    });

    socket.on('error', (data) {
      developer.log('❌ Server error: $data', name: 'SocketService');
      _onErrorController.add(data.toString());
    });

    // ── Pro Dashboard Events (Dev 4) ────────────────────────

    // Server: Dev 4 emits 'next-sublevel' when timer or moderator advances.
    socket.on('next-sublevel', (data) {
      developer.log('📚 next-sublevel: $data', name: 'SocketService');
      if (data is Map<String, dynamic>) {
        _onNextSublevelController.add(data);
      }
    });

    // Server: Dev 4 emits 'room-state-updated' with full room snapshot.
    socket.on('room-state-updated', (data) {
      developer.log('📦 room-state-updated: $data', name: 'SocketService');
      if (data is Map<String, dynamic>) {
        _onRoomStateUpdatedController.add(data);
      }
    });
  }

  // ── Private: Safe Emit (with list args) ───────────────────

  /// Emits an event with list arguments if connected, or logs a warning.
  void _emitOrLog(String event, List<dynamic> args) {
    if (_socket == null || !isConnected) {
      developer.log(
        '⚠️ Cannot emit "$event": socket not connected.',
        name: 'SocketService',
      );
      return;
    }
    developer.log('📤 Emit "$event": $args', name: 'SocketService');
    _socket!.emit(event, args);
  }

  /// Disposes all stream controllers.
  ///
  /// Call when the service is no longer needed (app shutdown).
  void disposeStreams() {
    _onUserConnectedController.close();
    _onUserRaisedHandController.close();
    _onUserDisconnectedController.close();
    _onMicToggledController.close();
    _onErrorController.close();
    _onNextSublevelController.close();
    _onRoomStateUpdatedController.close();
  }
}
