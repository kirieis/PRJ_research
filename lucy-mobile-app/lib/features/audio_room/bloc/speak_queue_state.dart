// lib/features/audio_room/bloc/speak_queue_state.dart
// ============================================================
// Project LUCY — SpeakQueue BLoC State (Dev 5)
//
// FIXED (Audit): Thêm isMuted field
// ============================================================

import 'package:equatable/equatable.dart';

class SpeakQueueState extends Equatable {
  final List<Map<String, dynamic>> queue;
  final bool isConnected;
  final bool isMuted;
  final String? roomId;
  final String? userId;

  const SpeakQueueState({
    this.queue = const [],
    this.isConnected = false,
    this.isMuted = true,
    this.roomId,
    this.userId,
  });

  int get queueLength => queue.length;

  SpeakQueueState copyWith({
    List<Map<String, dynamic>>? queue,
    bool? isConnected,
    bool? isMuted,
    String? roomId,
    String? userId,
  }) {
    return SpeakQueueState(
      queue: queue ?? this.queue,
      isConnected: isConnected ?? this.isConnected,
      isMuted: isMuted ?? this.isMuted,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [queue, isConnected, isMuted, roomId, userId];
}
