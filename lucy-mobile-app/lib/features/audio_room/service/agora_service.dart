// lib/features/audio_room/service/agora_service.dart
// ============================================================
// Project LUCY — Agora RTC Service (Real Implementation)
//
// Singleton wrapping agora_rtc_engine for audio room.
// Manages: join/leave channel, toggle mic, permissions,
// voice effects, and in-ear monitoring for voice testing.
//
// STABILITY FIX:
//   - All Agora native calls wrapped in try-catch to prevent
//     app crash on emulator / unsupported hardware.
//   - enableInEarMonitoring guarded — emulators lack audio
//     hardware and the native call crashes the process.
//   - Graceful degradation: if a feature fails, log warning
//     and continue without killing the app.
// ============================================================

import 'dart:developer' as developer;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bloc/room_config_event.dart';

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

class AgoraService {
  AgoraService._();
  static final AgoraService instance = AgoraService._();

  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isInChannel = false;
  bool _isMuted = true;
  bool _isTestingVoice = false; // tracks test voice state
  String? _currentChannel;

  // Callbacks
  AgoraUserCallback? onUserJoined;
  AgoraUserCallback? onUserLeft;
  AgoraMicCallback? onUserMuteAudio;

  bool get isInitialized => _isInitialized;
  bool get isInChannel => _isInChannel;
  bool get isMuted => _isMuted;
  bool get isTestingVoice => _isTestingVoice;
  String? get currentChannel => _currentChannel;

  /// Khởi tạo Agora engine
  Future<void> init(String appId) async {
    if (_isInitialized) return;

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.enableAudio();

      // Default to muted
      await _engine!.muteLocalAudioStream(true);

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _isInChannel = true;
          developer.log('✅ Joined Agora channel: ${connection.channelId}',
              name: 'AgoraService');
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          onUserJoined?.call(remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          onUserLeft?.call(remoteUid);
        },
        onUserMuteAudio: (connection, remoteUid, muted) {
          onUserMuteAudio?.call(remoteUid, muted);
        },
      ));

      _isInitialized = true;
      developer.log('✅ AgoraService initialized', name: 'AgoraService');
    } catch (e) {
      developer.log('❌ Agora init failed: $e', name: 'AgoraService');
      // Don't rethrow — allow app to continue without Agora
      _isInitialized = false;
    }
  }

  /// Request microphone permission
  Future<bool> requestMicPermission() async {
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        developer.log('🎤 Mic permission granted', name: 'AgoraService');
        return true;
      }
      developer.log('🎤 Mic permission denied', name: 'AgoraService');
      return false;
    } catch (e) {
      developer.log('❌ Permission error: $e', name: 'AgoraService');
      return false;
    }
  }

  /// Bật chế độ "Thử giọng" (In-ear monitoring)
  ///
  /// On emulators or devices without earphone hardware, in-ear monitoring
  /// will be skipped to prevent native crashes. The mic is still unmuted
  /// so the voice filter can be tested in a real channel.
  Future<void> startTestVoice() async {
    if (!_isInitialized || _engine == null) {
      developer.log('⚠️ Agora not ready, skipping test voice',
          name: 'AgoraService');
      return;
    }

    _isTestingVoice = true;

    try {
      // Unmute to allow testing
      await _engine!.muteLocalAudioStream(false);
    } catch (e) {
      developer.log('⚠️ Failed to unmute for test: $e',
          name: 'AgoraService');
    }

    // In-ear monitoring: wrap in try-catch because it crashes on
    // emulators and devices without wired headphones.
    try {
      await _engine!.enableInEarMonitoring(
        enabled: true,
        includeAudioFilters:
            EarMonitoringFilterType.earMonitoringFilterBuiltInAudioFilters,
      );
      await _engine!.setInEarMonitoringVolume(100);
      developer.log('🔊 In-ear monitoring enabled for voice test',
          name: 'AgoraService');
    } catch (e) {
      // This is expected to fail on emulators — not a critical error.
      developer.log(
        '⚠️ In-ear monitoring unavailable (emulator/no headphones): $e',
        name: 'AgoraService',
      );
    }
  }

  /// Tắt chế độ "Thử giọng"
  Future<void> stopTestVoice() async {
    if (!_isInitialized || _engine == null) return;

    _isTestingVoice = false;

    try {
      await _engine!.enableInEarMonitoring(
        enabled: false,
        includeAudioFilters: EarMonitoringFilterType.earMonitoringFilterNone,
      );
    } catch (e) {
      // Safe to ignore — monitoring may not have been started
      developer.log('⚠️ Disable in-ear monitoring skipped: $e',
          name: 'AgoraService');
    }

    // Re-mute if not in channel or if was muted
    try {
      if (!_isInChannel) {
        await _engine!.muteLocalAudioStream(true);
      } else {
        await _engine!.muteLocalAudioStream(_isMuted);
      }
    } catch (e) {
      developer.log('⚠️ Failed to re-mute after test: $e',
          name: 'AgoraService');
    }

    developer.log('🔇 Voice test stopped', name: 'AgoraService');
  }

  /// Cài đặt bộ lọc giọng nói (Voice Filter)
  Future<void> setVoiceFilter(VoiceFilterType filterType) async {
    if (!_isInitialized || _engine == null) return;

    try {
      // Map domain enum to Agora constants
      switch (filterType) {
        case VoiceFilterType.normal:
          await _engine!
              .setAudioEffectPreset(AudioEffectPreset.audioEffectOff);
          await _engine!.setVoiceBeautifierPreset(
              VoiceBeautifierPreset.voiceBeautifierOff);
          break;
        case VoiceFilterType.warm:
          await _engine!.setVoiceBeautifierPreset(
              VoiceBeautifierPreset.chatBeautifierMagnetic);
          break;
        case VoiceFilterType.robot:
          await _engine!
              .setAudioEffectPreset(AudioEffectPreset.pitchCorrection);
          break;
        case VoiceFilterType.cartoon:
          await _engine!.setAudioEffectPreset(
              AudioEffectPreset.voiceChangerEffectBoy);
          break;
        case VoiceFilterType.deep:
          await _engine!.setAudioEffectPreset(
              AudioEffectPreset.voiceChangerEffectUncle);
          break;
        case VoiceFilterType.echo:
          await _engine!
              .setAudioEffectPreset(AudioEffectPreset.roomAcousticsKtv);
          break;
      }
      developer.log('🎵 Applied voice filter: ${filterType.name}',
          name: 'AgoraService');
    } catch (e) {
      developer.log('⚠️ Failed to apply voice filter: $e',
          name: 'AgoraService');
    }
  }

  /// Join channel
  Future<void> joinChannel(AgoraConfig config) async {
    if (!_isInitialized || _engine == null) {
      developer.log('⚠️ Agora not initialized, skip joinChannel',
          name: 'AgoraService');
      return;
    }

    if (_isInChannel) {
      await leaveChannel();
    }

    try {
      await _engine!.joinChannel(
        token: config.token ?? '',
        channelId: config.channelName,
        uid: config.uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );

      _currentChannel = config.channelName;
      await _engine!.muteLocalAudioStream(_isMuted);
      developer.log('✅ Joined channel: ${config.channelName}',
          name: 'AgoraService');
    } catch (e) {
      developer.log('❌ Join channel failed: $e', name: 'AgoraService');
      // Don't rethrow — allow app to continue
    }
  }

  /// Leave channel
  Future<void> leaveChannel() async {
    if (_engine == null) return;
    if (!_isInChannel) return;

    try {
      await _engine!.leaveChannel();
      developer.log('👋 Left channel: $_currentChannel',
          name: 'AgoraService');
    } catch (e) {
      developer.log('⚠️ Leave channel error: $e', name: 'AgoraService');
    } finally {
      _isInChannel = false;
      _currentChannel = null;
      _isMuted = true;
    }
  }

  /// Bật/Tắt mic
  Future<bool> toggleMic() async {
    if (_engine == null) return _isMuted;

    _isMuted = !_isMuted;

    try {
      await _engine!.muteLocalAudioStream(_isMuted);
      developer.log('🎤 Mic ${_isMuted ? "muted" : "unmuted"}',
          name: 'AgoraService');
    } catch (e) {
      developer.log('⚠️ Toggle mic failed: $e', name: 'AgoraService');
      _isMuted = !_isMuted; // Revert
    }

    return _isMuted;
  }

  /// Set mic explicitly
  Future<void> setMicMuted(bool muted) async {
    if (_engine == null) return;

    _isMuted = muted;
    try {
      await _engine!.muteLocalAudioStream(muted);
    } catch (e) {
      developer.log('⚠️ setMicMuted failed: $e', name: 'AgoraService');
    }
  }

  /// Dispose
  Future<void> dispose() async {
    try {
      if (_isInChannel) {
        await leaveChannel();
      }
      await _engine?.release();
    } catch (e) {
      developer.log('⚠️ Agora dispose error: $e', name: 'AgoraService');
    } finally {
      _engine = null;
      _isInitialized = false;
      developer.log('🗑 AgoraService disposed', name: 'AgoraService');
    }
  }
}
