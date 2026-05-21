import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/socket_service.dart';
import '../models/room_model.dart';

/// Repository xử lý API calls liên quan đến Room (phòng học real-time).
///
/// Kết hợp:
/// - REST API (Dio) cho CRUD operations
/// - Socket.IO cho real-time events (join/leave room, sync sub-level)
class RoomRepository {
  final Dio _dio = DioClient.instance.dio;
  final SocketService _socket = SocketService.instance;

  /// Lấy danh sách phòng đang hoạt động.
  Future<List<RoomModel>> getActiveRooms() async {
    final response = await _dio.get('/api/rooms', queryParameters: {
      'status': 'ACTIVE',
    });

    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((json) => RoomModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Tham gia phòng (qua Socket.IO).
  void joinRoom(int roomId) {
    _socket.emit('join_room', {'roomId': roomId});
  }

  /// Rời phòng (qua Socket.IO).
  void leaveRoom(int roomId) {
    _socket.emit('leave_room', {'roomId': roomId});
  }

  /// Lắng nghe sự kiện đổi sub-level trong phòng.
  void onSubLevelChanged(Function(dynamic) callback) {
    _socket.on('sub_level_changed', callback);
  }

  /// Hủy lắng nghe.
  void dispose() {
    _socket.off('sub_level_changed');
  }
}
