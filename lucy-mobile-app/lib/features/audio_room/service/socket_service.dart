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
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as sio;
import '../../../core/constants/app_constants.dart';

/// Abstraction over Socket.IO for audio room real-time events.
///
/// **Key events emitted:**
/// - `join_room` / `leave_room` → room lifecycle
/// - `raise_hand` → request to speak
/// - `toggle_mic` → mic state change broadcast
///
/// **Key events listened:**
/// - `hand_queue_updated` → server broadcasts updated queue
class SocketService {
  sio.Socket? _socket;
  final _handQueueController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

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
  void connect({String? url, String? jwtToken}) {
    // Disconnect existing socket to prevent duplicate connections.
    _socket?.disconnect();
    _socket?.dispose();

    final options = sio.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(5)
        .setReconnectionDelay(2000);

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

    _socket!.onReconnect((_) {
      developer.log('🔄 Socket reconnected', name: 'SocketService');
    });

    _socket!.on('hand_queue_updated', (data) {
      if (data is List && !_handQueueController.isClosed) {
        _handQueueController.add(List<Map<String, dynamic>>.from(data));
      }
    });
  }

  /// Emits join_room event.
  void emitJoinRoom({required String roomId, required String userId}) {
    _socket?.emit('join_room', {'roomId': roomId, 'userId': userId});
  }

  /// Emits leave_room event — thông báo server user rời phòng.
  void emitLeaveRoom({required String roomId, required String userId}) {
    _socket?.emit('leave_room', {'roomId': roomId, 'userId': userId});
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
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Disposes all stream controllers.
  void dispose() {
    disconnect();
    if (!_handQueueController.isClosed) _handQueueController.close();
    if (!_connectionController.isClosed) _connectionController.close();
  }
}
