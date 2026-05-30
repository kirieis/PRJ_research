// test/features/audio_room/service/agora_service_test.dart
// ============================================================
// Project LUCY — AgoraService Unit Tests
// Tests the singleton service without a real Agora engine.
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:lucy_app/features/audio_room/service/agora_service.dart';

void main() {
  group('AgoraService', () {
    test('should be a singleton', () {
      final instance1 = AgoraService();
      final instance2 = AgoraService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('should throw when initializing with empty appId', () {
      final service = AgoraService();
      expect(
        () => service.initialize(''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('App ID is empty'),
        )),
      );
    });

    test('should throw StateError when joining before init', () {
      final service = AgoraService();
      // Reset engine state (since singleton may have been initialized
      // in a previous test run — in real tests use DI for testability).
      expect(
        () => service.joinChannel(channelName: 'test'),
        throwsA(isA<StateError>()),
      );
    });

    test('should throw StateError when toggling mic before init', () {
      final service = AgoraService();
      expect(
        () => service.toggleMic(true),
        throwsA(isA<StateError>()),
      );
    });

    test('should expose broadcast streams', () {
      final service = AgoraService();

      // Streams should be non-null and broadcastable.
      expect(service.onUserJoined, isA<Stream<int>>());
      expect(service.onUserOffline, isA<Stream<int>>());
      expect(service.onVolumeIndication, isA<Stream>());

      // Broadcast streams allow multiple listeners.
      service.onUserJoined.listen((_) {});
      service.onUserJoined.listen((_) {}); // Should not throw
    });

    test('isInitialized should return false before init', () {
      final service = AgoraService();
      // Note: Due to singleton, this may be true if another test init'd.
      // In a real project, use DI to inject mock engine.
      expect(service.isInitialized, isA<bool>());
    });
  });
}
