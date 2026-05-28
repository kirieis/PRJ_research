import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';

/// Socket.IO client cho real-time communication.
///
/// Sử dụng cho:
/// - Room: đồng bộ trạng thái phòng học real-time
/// - Chat: tin nhắn trong phòng
/// - Notifications: thông báo push
class SocketService {
  static SocketService? _instance;
  io.Socket? _socket;

  SocketService._();

  /// Lấy singleton instance.
  static SocketService get instance {
    _instance ??= SocketService._();
    return _instance!;
  }

  /// Kết nối đến server Socket.IO với JWT token.
  void connect({required String token}) {
    _socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {
      // ignore: avoid_print
      print('[SocketService] Connected to ${ApiConstants.socketUrl}');
    });

    _socket!.onDisconnect((_) {
      // ignore: avoid_print
      print('[SocketService] Disconnected');
    });

    _socket!.onConnectError((error) {
      // ignore: avoid_print
      print('[SocketService] Connection error: $error');
    });
  }

  /// Ngắt kết nối Socket.IO.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Gửi event đến server.
  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  /// Lắng nghe event từ server.
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  /// Hủy lắng nghe event.
  void off(String event) {
    _socket?.off(event);
  }

  /// Kiểm tra trạng thái kết nối.
  bool get isConnected => _socket?.connected ?? false;
}
