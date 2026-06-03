// test/socket_service_test.dart
// ============================================================
// Project LUCY — SocketService + SpeakQueueBloc Integration Tests
//
// Uses flutter_test + mockito to mock SocketService.
// No real server required — all socket events are simulated.
//
// Test coverage:
//   1. join_room → SpeakQueueBloc state updated correctly
//   2. raise_hand → hand_queue_updated processed, queue +1
//   3. disconnect → state.isConnected = false (UI shows banner)
// ============================================================

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:lucy_app/features/audio_room/service/socket_service.dart';
import 'package:lucy_app/features/audio_room/bloc/speak_queue_bloc.dart';
import 'package:lucy_app/features/audio_room/bloc/speak_queue_event.dart';
import 'package:lucy_app/features/audio_room/bloc/speak_queue_state.dart';

@GenerateMocks([SocketService])
import 'socket_service_test.mocks.dart';

void main() {
  group('SpeakQueueBloc — SocketService Integration Tests', () {
    late MockSocketService mockSocketService;
    late SpeakQueueBloc bloc;
    late StreamController<List<Map<String, dynamic>>> handQueueController;
    late StreamController<bool> connectionController;

    setUp(() {
      mockSocketService = MockSocketService();
      handQueueController = StreamController<List<Map<String, dynamic>>>.broadcast();
      connectionController = StreamController<bool>.broadcast();

      // Stub stream getters.
      when(mockSocketService.handQueueStream).thenAnswer((_) => handQueueController.stream);
      when(mockSocketService.connectionStream).thenAnswer((_) => connectionController.stream);
      when(mockSocketService.connect(url: anyNamed('url'))).thenReturn(null);
      when(mockSocketService.dispose()).thenReturn(null);

      bloc = SpeakQueueBloc(socketService: mockSocketService);
    });

    tearDown(() async {
      await bloc.close();
      await handQueueController.close();
      await connectionController.close();
    });

    // ── TEST 1: join_room → state updated ──────────────────────

    test('join_room → SpeakQueueBloc cập nhật state đúng (roomId, userId)', () async {
      // Arrange: stub emitJoinRoom.
      when(mockSocketService.emitJoinRoom(
        roomId: anyNamed('roomId'),
        userId: anyNamed('userId'),
      )).thenReturn(null);

      // Act: dispatch join event.
      bloc.add(const SpeakQueueRoomJoined(
        roomId: 'test-room-001',
        userId: 'user_001',
      ));

      // Assert: wait for state to update.
      await expectLater(
        bloc.stream,
        emits(isA<SpeakQueueState>()
            .having((s) => s.roomId, 'roomId', 'test-room-001')
            .having((s) => s.userId, 'userId', 'user_001')),
      );

      // Verify the socket calls were made.
      verify(mockSocketService.connect(url: anyNamed('url'))).called(1);
      verify(mockSocketService.emitJoinRoom(
        roomId: 'test-room-001',
        userId: 'user_001',
      )).called(1);
    });

    // ── TEST 2: raise_hand → queue increases by 1 ──────────────

    test('raise_hand → hand_queue_updated xử lý đúng, queue tăng 1', () async {
      // Arrange: join room first.
      when(mockSocketService.emitJoinRoom(
        roomId: anyNamed('roomId'),
        userId: anyNamed('userId'),
      )).thenReturn(null);
      when(mockSocketService.emitRaiseHand(
        roomId: anyNamed('roomId'),
        userId: anyNamed('userId'),
      )).thenReturn(null);

      // Join room to initialize state.
      bloc.add(const SpeakQueueRoomJoined(
        roomId: 'test-room-001',
        userId: 'user_001',
      ));

      // Wait for join state.
      await bloc.stream.firstWhere((s) => s.roomId == 'test-room-001');

      // Act: simulate raise_hand + server response.
      bloc.add(const SpeakQueueHandRaised());

      // Simulate server broadcasting hand_queue_updated.
      handQueueController.add([
        {'userId': 'user_001', 'displayName': 'Tester 1'},
      ]);

      // Assert: queue length is 1.
      await expectLater(
        bloc.stream,
        emits(isA<SpeakQueueState>()
            .having((s) => s.queueLength, 'queueLength', 1)
            .having((s) => s.queue.first['userId'], 'first userId', 'user_001')),
      );

      verify(mockSocketService.emitRaiseHand(
        roomId: 'test-room-001',
        userId: 'user_001',
      )).called(1);
    });

    // ── TEST 3: disconnect → isConnected = false ───────────────

    test('disconnect → kiểm tra UI hiện banner "Mất kết nối"', () async {
      // Arrange: join room.
      when(mockSocketService.emitJoinRoom(
        roomId: anyNamed('roomId'),
        userId: anyNamed('userId'),
      )).thenReturn(null);

      bloc.add(const SpeakQueueRoomJoined(
        roomId: 'test-room-001',
        userId: 'user_001',
      ));
      await bloc.stream.firstWhere((s) => s.roomId != null);

      // Act: simulate connection → then disconnection.
      connectionController.add(true);
      await bloc.stream.firstWhere((s) => s.isConnected == true);

      connectionController.add(false);

      // Assert: isConnected becomes false → UI should show "Mất kết nối" banner.
      await expectLater(
        bloc.stream,
        emits(isA<SpeakQueueState>()
            .having((s) => s.isConnected, 'isConnected', false)),
      );
    });

    // ── TEST 4: multiple queue updates accumulate correctly ────

    test('multiple hand_queue_updated → queue reflects latest state', () async {
      // Arrange.
      when(mockSocketService.emitJoinRoom(
        roomId: anyNamed('roomId'),
        userId: anyNamed('userId'),
      )).thenReturn(null);

      bloc.add(const SpeakQueueRoomJoined(
        roomId: 'test-room-001',
        userId: 'user_001',
      ));
      await bloc.stream.firstWhere((s) => s.roomId != null);

      // Act: simulate two sequential queue updates.
      handQueueController.add([
        {'userId': 'user_001', 'displayName': 'Tester 1'},
      ]);

      await bloc.stream.firstWhere((s) => s.queueLength == 1);

      handQueueController.add([
        {'userId': 'user_001', 'displayName': 'Tester 1'},
        {'userId': 'user_002', 'displayName': 'Tester 2'},
        {'userId': 'user_003', 'displayName': 'Tester 3'},
      ]);

      // Assert: queue length updates to 3.
      await expectLater(
        bloc.stream,
        emits(isA<SpeakQueueState>()
            .having((s) => s.queueLength, 'queueLength', 3)),
      );
    });
  });
}
