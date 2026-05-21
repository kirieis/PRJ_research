import 'package:flutter/material.dart';

/// Màn hình phòng học – placeholder.
///
/// TODO: Tích hợp Agora SDK cho voice/video call
/// TODO: Hiển thị nội dung sub-level đồng bộ real-time
class RoomScreen extends StatelessWidget {
  final int roomId;

  const RoomScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phòng học #$roomId'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room, size: 80, color: Color(0xFF6C63FF)),
            SizedBox(height: 16),
            Text(
              'Phòng học Real-time',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tính năng đang được phát triển...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
