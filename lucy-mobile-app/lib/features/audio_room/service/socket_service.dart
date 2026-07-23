// lib/features/audio_room/service/socket_service.dart
// ============================================================
// Project LUCY — Socket Service (Dev 5)
//
// Abstraction layer over socket_io_client for testability.
// All socket events flow through this service.
//
// FIXED (Audit):
//   ✅ JWT auth token truyền khi connect
//   ✅ Thêm emitLeaveRoom + emitToggleMic
//   ✅ isClosed guard trên StreamController
//   ✅ Reconnection config
//   ✅ connect_error logging
//
// FIXED (Connection Stability — 2026-07-15):
//   ✅ Singleton pattern — 1 socket connection duy nhất
//   ✅ Auto re-join room sau reconnect
//   ✅ JWT refresh on reconnect attempt
//   ✅ Tăng reconnection attempts (5 → ∞ cho mobile)
//   ✅ reconnectionDelayMax = 30s
//   ✅ onReconnectAttempt / onReconnectFailed logging
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as sio;
import '../../../core/constants/app_constants.dart';

/// Abstraction over Socket.IO for audio room real-time events.
///
/// **Singleton:** Use `SocketService()` — all calls return the same instance.
/// This prevents duplicate connections when navigating between routes.
///
/// **Key events emitted:**
/// - `join_room` / `leave_room` → room lifecycle
/// - `raise_hand` → request to speak
/// - `toggle_mic` → mic state change broadcast
///
/// **Key events listened:**
/// - `hand_queue_updated` → server broadcasts updated queue
class SocketService {
  // ── Singleton ────────────────────────────────────────────
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  sio.Socket? _socket;
  final _handQueueController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // ── Room/User state for auto re-join ─────────────────────
  String? _lastRoomId;
  String? _lastUserId;
  String? _jwtToken;

  /// Current JWT token used for socket connection.
  String? get jwtToken => _jwtToken;

  /// Callback to refresh JWT token before reconnect.
  /// Set this from the auth layer to enable token refresh.
  ///
  /// Example:
  /// ```dart
  /// SocketService().onTokenRefresh = () async {
  ///   return await AuthService.refreshToken();
  /// };
  /// ```
  Future<String?> Function()? onTokenRefresh;

  /// Stream of hand queue updates from the server.
  Stream<List<Map<String, dynamic>>> get handQueueStream =>
      _handQueueController.stream;

  /// Stream of connection status changes.
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Whether the socket is currently connected.
  bool get isConnected => _socket?.connected ?? false;

  /// Connects to the Socket.IO server.
  ///
  /// [jwtToken] — JWT token from Auth service for authentication.
  /// Staging đã bật JWT → bắt buộc truyền token.
  ///
  /// **Connection stability features:**
  /// - Auto reconnect with exponential backoff (2s → 30s max)
  /// - Unlimited reconnection attempts (mobile networks are unreliable)
  /// - Auto re-join last room after reconnect
  /// - JWT token refresh before reconnect attempt
  void connect({String? url, String? jwtToken}) {
    // Store JWT for reconnect refresh.
    _jwtToken = jwtToken;

    // Disconnect existing socket to prevent duplicate connections.
    _socket?.disconnect();
    _socket?.dispose();

    final options = sio.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .enableReconnection()
        // Mobile-optimized reconnection:
        // - Unlimited attempts (mobile networks can drop for 60s+)
        // - Exponential backoff: 2s → 4s → 8s → ... → 30s max
        .setReconnectionAttempts(double.maxFinite.toInt())
        .setReconnectionDelay(2000)
        .setReconnectionDelayMax(30000);

    // Gửi JWT auth token — required cho staging/production.
    if (jwtToken != null && jwtToken.isNotEmpty) {
      options.setAuth({'token': jwtToken});
    }

    _socket = sio.io(url ?? AppConstants.socketUrl, options.build());

    _socket!.onConnect((_) {
      developer.log('🔌 Socket connected', name: 'SocketService');
      if (!_connectionController.isClosed) {
        _connectionController.add(true);
      }
    });

    _socket!.onDisconnect((_) {
      developer.log('🔌 Socket disconnected', name: 'SocketService');
      if (!_connectionController.isClosed) {
        _connectionController.add(false);
      }
    });

    _socket!.onConnectError((data) {
      developer.log('❌ Socket connect error: $data', name: 'SocketService');
    });

    // ── Reconnect handling ──────────────────────────────────
    // FIX: Auto re-join room after reconnect to restore session.
    // Without this, the socket reconnects but the user is NOT in any room,
    // so they won't receive hand_queue_updated events.
    _socket!.onReconnect((_) {
      developer.log('🔄 Socket reconnected', name: 'SocketService');
      // Auto re-join the last room after reconnection.
      if (_lastRoomId != null && _lastUserId != null) {
        _socket?.emit('join_room', {
          'roomId': _lastRoomId,
          'userId': _lastUserId,
        });
        developer.log(
          '🔄 Auto re-joined room: $_lastRoomId as $_lastUserId',
          name: 'SocketService',
        );
      }
    });

    _socket!.onReconnectAttempt((attemptNumber) async {
      developer.log(
        '🔄 Reconnect attempt #$attemptNumber',
        name: 'SocketService',
      );
      // FIX: Refresh JWT token before reconnect attempt.
      // If the token expired during disconnect, reconnect would fail
      // with auth error without this refresh.
      if (onTokenRefresh != null) {
        try {
          final newToken = await onTokenRefresh!();
          if (newToken != null && newToken.isNotEmpty) {
            _jwtToken = newToken;
            _socket?.io.options?['auth'] = {'token': newToken};
            developer.log(
              '🔑 JWT refreshed for reconnect',
              name: 'SocketService',
            );
          }
        } catch (e) {
          developer.log(
            '⚠️ JWT refresh failed: $e',
            name: 'SocketService',
          );
        }
      }
    });

    _socket!.onReconnectFailed((_) {
      developer.log(
        '❌ All reconnection attempts exhausted',
        name: 'SocketService',
      );
    });

    _socket!.on('hand_queue_updated', (data) {
      if (data is List && !_handQueueController.isClosed) {
        _handQueueController.add(List<Map<String, dynamic>>.from(data));
      }
    });
  }

  /// Emits join_room event.
  ///
  /// Also stores roomId/userId for auto re-join on reconnect.
  void emitJoinRoom({required String roomId, required String userId}) {
    _lastRoomId = roomId;
    _lastUserId = userId;
    _socket?.emit('join_room', {'roomId': roomId, 'userId': userId});
  }

  /// Emits leave_room event — thông báo server user rời phòng.
  void emitLeaveRoom({required String roomId, required String userId}) {
    _socket?.emit('leave_room', {'roomId': roomId, 'userId': userId});
    // Clear stored room so reconnect doesn't auto-rejoin a left room.
    _lastRoomId = null;
    _lastUserId = null;
    developer.log('👋 Left room: $roomId', name: 'SocketService');
  }

  /// Emits raise_hand event.
  void emitRaiseHand({required String roomId, required String userId}) {
    _socket?.emit('raise_hand', {'roomId': roomId, 'userId': userId});
  }

  /// Emits toggle_mic event — broadcast mic state to other users.
  void emitToggleMic({
    required String roomId,
    required String userId,
    required bool isMuted,
  }) {
    _socket?.emit('toggle_mic', {
      'roomId': roomId,
      'userId': userId,
      'isMuted': isMuted,
    });
  }

  /// Disconnects from the server.
  ///
  /// Does NOT clear stored room/user — call [emitLeaveRoom] first
  /// if the user intentionally left the room.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Disposes all stream controllers.
  ///
  /// Call only when the socket service is permanently no longer needed
  /// (e.g. app termination). Since this is a singleton, avoid calling
  /// this from individual screen dispose methods.
  void dispose() {
    disconnect();
    _lastRoomId = null;
    _lastUserId = null;
    if (!_handQueueController.isClosed) _handQueueController.close();
    if (!_connectionController.isClosed) _connectionController.close();
  }
}
