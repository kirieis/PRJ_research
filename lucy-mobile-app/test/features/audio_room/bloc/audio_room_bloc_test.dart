// test/features/audio_room/bloc/audio_room_bloc_test.dart
// ============================================================
// Project LUCY — AudioRoomBloc Unit Tests
// Tests BLoC event handlers and state transitions.
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:lucy_app/features/audio_room/bloc/audio_room_bloc.dart';
import 'package:lucy_app/features/audio_room/bloc/audio_room_event.dart';
import 'package:lucy_app/features/audio_room/bloc/audio_room_state.dart';
import 'package:lucy_app/features/audio_room/model/room_user.dart';

void main() {
  group('AudioRoomState', () {
    test('initial state has correct defaults', () {
      const state = AudioRoomState();
      expect(state.status, AudioRoomStatus.initial);
      expect(state.roomId, '');
      expect(state.channelName, '');
      expect(state.users, isEmpty);
      expect(state.handQueue, isEmpty);
      expect(state.isMicOn, isFalse);
      expect(state.isHandRaised, isFalse);
      expect(state.currentUserId, '');
      expect(state.errorMessage, isNull);
    });

    test('copyWith replaces only specified fields', () {
      const state = AudioRoomState();
      final updated = state.copyWith(
        status: AudioRoomStatus.connected,
        roomId: 'room-123',
        isMicOn: true,
      );

      expect(updated.status, AudioRoomStatus.connected);
      expect(updated.roomId, 'room-123');
      expect(updated.isMicOn, isTrue);
      // Unchanged fields retain original values.
      expect(updated.channelName, '');
      expect(updated.users, isEmpty);
      expect(updated.isHandRaised, isFalse);
    });

    test('Equatable: same values are equal', () {
      const state1 = AudioRoomState(roomId: 'room-1');
      const state2 = AudioRoomState(roomId: 'room-1');
      expect(state1, equals(state2));
    });

    test('Equatable: different values are not equal', () {
      const state1 = AudioRoomState(roomId: 'room-1');
      const state2 = AudioRoomState(roomId: 'room-2');
      expect(state1, isNot(equals(state2)));
    });
  });

  group('RoomUser', () {
    test('fromJson creates correct instance', () {
      final json = {
        'userId': 'usr-001',
        'displayName': 'Anonymous Fox',
        'personaIndex': 0,
        'isMuted': false,
        'isHandRaised': true,
        'agoraUid': 12345,
      };

      final user = RoomUser.fromJson(json);
      expect(user.userId, 'usr-001');
      expect(user.displayName, 'Anonymous Fox');
      expect(user.personaIndex, 0);
      expect(user.isMuted, isFalse);
      expect(user.isSpeaking, isFalse); // Always false from JSON
      expect(user.isHandRaised, isTrue);
      expect(user.agoraUid, 12345);
    });

    test('fromJson handles missing fields with defaults', () {
      final user = RoomUser.fromJson({});
      expect(user.userId, '');
      expect(user.displayName, 'Anonymous');
      expect(user.personaIndex, 0);
      expect(user.isMuted, isTrue);
    });

    test('toJson round-trips correctly', () {
      const user = RoomUser(
        userId: 'usr-002',
        displayName: 'Anonymous Cat',
        personaIndex: 1,
        isMuted: false,
        agoraUid: 99,
      );

      final json = user.toJson();
      final restored = RoomUser.fromJson(json);

      expect(restored.userId, user.userId);
      expect(restored.displayName, user.displayName);
      expect(restored.personaIndex, user.personaIndex);
      expect(restored.agoraUid, user.agoraUid);
    });

    test('copyWith creates new instance with updated fields', () {
      const user = RoomUser(
        userId: 'usr-003',
        displayName: 'Anonymous Bear',
        isMuted: true,
        isSpeaking: false,
      );

      final speaking = user.copyWith(isSpeaking: true, isMuted: false);
      expect(speaking.isSpeaking, isTrue);
      expect(speaking.isMuted, isFalse);
      expect(speaking.userId, 'usr-003'); // Unchanged
    });
  });

  group('AudioRoomEvent', () {
    test('AudioRoomJoinRequested has correct props', () {
      const event = AudioRoomJoinRequested(
        roomId: 'room-1',
        channelName: 'channel-1',
        userId: 'usr-1',
        displayName: 'Fox',
      );
      expect(event.props, ['room-1', 'channel-1', 'usr-1', 'Fox', null]);
    });

    test('AudioRoomMicToggled is singleton-like', () {
      const e1 = AudioRoomMicToggled();
      const e2 = AudioRoomMicToggled();
      expect(e1, equals(e2));
    });

    test('AudioRoomHandQueueUpdated carries queue', () {
      const event = AudioRoomHandQueueUpdated(['usr-1', 'usr-2']);
      expect(event.handQueue, ['usr-1', 'usr-2']);
    });

    test('AudioRoomSpeakingChanged carries uid and state', () {
      const event = AudioRoomSpeakingChanged(
        agoraUid: 123,
        isSpeaking: true,
      );
      expect(event.agoraUid, 123);
      expect(event.isSpeaking, isTrue);
    });
  });
}
