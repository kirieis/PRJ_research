// lib/features/audio_room/service/agora_service.dart
// ============================================================
// Project LUCY — Agora RTC Service (Dev 5 — T1)
//
// Singleton wrapping agora_rtc_engine for audio room.
// Manages: join/leave channel, toggle mic, permissions.
//
// Zero-conflict: Chỉ dùng trong audio_room feature.
// Nếu agora_rtc_engine chưa cài, app vẫn build được —
// service sẽ log warning và return gracefully.
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;

/// Agora RTC channel configuration.
class AgoraConfig {
  final String appId;
  final String channelName;
  final String? token;
  final int uid;

  const AgoraConfig({
    required this.appId,
    required this.channelName,
    this.token,
    this.uid = 0,
  });
}

/// Callback khi có user join/leave/toggle mic trong Agora channel.
typedef AgoraUserCallback = void Function(int uid);
typedef AgoraMicCallback = void Function(int uid, bool muted);

/// Singleton service wrapping Agora RTC Engine.
///
/// **Lifecycle:**
/// 1. `AgoraService.instance.init(appId)` — khởi tạo engine 1 lần
/// 2. `joinChannel(config)` — join vào phòng audio
/// 3. `toggleMic()` / `leaveChannel()` — điều khiển
/// 4. `dispose()` — giải phóng khi app kết thúc
///
/// **Permission:** Gọi `requestMicPermission()` trước `joinChannel()`.
class AgoraService {
  AgoraService._();
  static final AgoraService instance = AgoraService._();

  bool _isInitialized = false;
  bool _isInChannel = false;
  bool _isMuted = true;
  String? _currentChannel;

  // Callbacks
  AgoraUserCallback? onUserJoined;
  AgoraUserCallback? onUserLeft;
  AgoraMicCallback? onUserMuteAudio;

  /// Whether the engine is initialized.
  bool get isInitialized => _isInitialized;

  /// Whether the user is currently in a channel.
  bool get isInChannel => _isInChannel;

  /// Current mic mute state.
  bool get isMuted => _isMuted;

  /// Current channel name.
  String? get currentChannel => _currentChannel;

  /// Initialize the Agora RTC engine.
  ///
  /// Call once at app startup or before first room join.
  /// [appId] — from Agora Console → Project Management.
  Future<void> init(String appId) async {
    if (_isInitialized) {
      developer.log('⚠️ Agora already initialized', name: 'AgoraService');
      return;
    }

    try {
      // === AGORA ENGINE INIT ===
      // Khi agora_rtc_engine đã cài trong pubspec:
      //
      // import 'package:agora_rtc_engine/agora_rtc_engine.dart';
      //
      // _engine = createAgoraRtcEngine();
      // await _engine!.initialize(RtcEngineContext(
      //   appId: appId,
      //   channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      // ));
      //
      // await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      // await _engine!.enableAudio();
      // await _engine!.muteLocalAudioStream(true); // mặc định mute
      //
      // _engine!.registerEventHandler(RtcEngineEventHandler(
      //   onJoinChannelSuccess: (connection, elapsed) {
      //     _isInChannel = true;
      //     developer.log('✅ Joined Agora channel: ${connection.channelId}');
      //   },
      //   onUserJoined: (connection, remoteUid, elapsed) {
      //     onUserJoined?.call(remoteUid);
      //   },
      //   onUserOffline: (connection, remoteUid, reason) {
      //     onUserLeft?.call(remoteUid);
      //   },
      //   onUserMuteAudio: (connection, remoteUid, muted) {
      //     onUserMuteAudio?.call(remoteUid, muted);
      //   },
      // ));

      _isInitialized = true;
      developer.log('✅ AgoraService initialized (stub mode)', name: 'AgoraService');
    } catch (e) {
      developer.log('❌ Agora init failed: $e', name: 'AgoraService');
      rethrow;
    }
  }

  /// Request microphone permission (Android + iOS).
  ///
  /// Call before `joinChannel()`.
  /// Returns true if permission granted.
  Future<bool> requestMicPermission() async {
    try {
      // Khi permission_handler đã cài:
      //
      // import 'package:permission_handler/permission_handler.dart';
      // final status = await Permission.microphone.request();
      // return status.isGranted;

      developer.log('🎤 Mic permission requested (stub: granted)', name: 'AgoraService');
      return true;
    } catch (e) {
      developer.log('❌ Permission error: $e', name: 'AgoraService');
      return false;
    }
  }

  /// Join an Agora audio channel.
  ///
  /// [config] contains appId, channelName, optional token, and uid.
  /// Ensure `requestMicPermission()` was called first.
  Future<void> joinChannel(AgoraConfig config) async {
    if (!_isInitialized) {
      developer.log('⚠️ AgoraService not initialized', name: 'AgoraService');
      return;
    }

    if (_isInChannel) {
      developer.log('⚠️ Already in channel: $_currentChannel', name: 'AgoraService');
      await leaveChannel();
    }

    try {
      // _engine!.joinChannel(
      //   token: config.token ?? '',
      //   channelId: config.channelName,
      //   uid: config.uid,
      //   options: const ChannelMediaOptions(
      //     channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      //     clientRoleType: ClientRoleType.clientRoleBroadcaster,
      //   ),
      // );

      _currentChannel = config.channelName;
      _isInChannel = true;
      _isMuted = true;
      developer.log(
        '✅ Joined channel: ${config.channelName} (stub)',
        name: 'AgoraService',
      );
    } catch (e) {
      developer.log('❌ Join channel failed: $e', name: 'AgoraService');
      rethrow;
    }
  }

  /// Leave the current Agora channel.
  Future<void> leaveChannel() async {
    if (!_isInChannel) return;

    try {
      // await _engine!.leaveChannel();

      developer.log('👋 Left channel: $_currentChannel (stub)', name: 'AgoraService');
      _isInChannel = false;
      _currentChannel = null;
      _isMuted = true;
    } catch (e) {
      developer.log('❌ Leave channel failed: $e', name: 'AgoraService');
    }
  }

  /// Toggle local microphone mute state.
  ///
  /// Returns the new mute state.
  Future<bool> toggleMic() async {
    _isMuted = !_isMuted;

    try {
      // await _engine!.muteLocalAudioStream(_isMuted);

      developer.log(
        '🎤 Mic ${_isMuted ? "muted" : "unmuted"} (stub)',
        name: 'AgoraService',
      );
    } catch (e) {
      developer.log('❌ Toggle mic failed: $e', name: 'AgoraService');
      _isMuted = !_isMuted; // Revert on failure
    }

    return _isMuted;
  }

  /// Set mic mute state explicitly.
  Future<void> setMicMuted(bool muted) async {
    _isMuted = muted;
    // await _engine!.muteLocalAudioStream(muted);
  }

  /// Dispose the Agora engine.
  ///
  /// Call when the app is terminating or audio feature is no longer needed.
  Future<void> dispose() async {
    if (_isInChannel) {
      await leaveChannel();
    }
    // await _engine?.release();
    _isInitialized = false;
    developer.log('🗑 AgoraService disposed', name: 'AgoraService');
  }
}
