// lib/features/audio_room/service/agora_service.dart
// ============================================================
// Project LUCY — Agora RTC Engine Service (Singleton)
// Wraps the agora_rtc_engine SDK for audio-only communication.
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/app_config.dart';

/// Singleton service managing the Agora RTC engine lifecycle.
///
/// Responsibilities:
/// - Initialize the RTC engine in audio-only mode
/// - Join/leave Agora voice channels
/// - Toggle local microphone (mute/unmute)
/// - Expose user join/leave and volume events as Dart streams
///
/// Usage:
/// ```dart
/// final agora = AgoraService();
/// await agora.initialize(AppConfig.agoraAppId);
/// await agora.joinChannel(channelName: 'room-123', token: null, uid: 0);
/// ```
class AgoraService {
  // ── Singleton ─────────────────────────────────────────────
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  /// The underlying Agora RTC engine instance.
  RtcEngine? _engine;

  /// Whether the engine has been successfully initialized.
  bool get isInitialized => _engine != null;

  // ── Stream Controllers ────────────────────────────────────
  // Broadcast streams so multiple listeners (BLoC, UI) can subscribe.

  final _onUserJoinedController = StreamController<int>.broadcast();
  final _onUserOfflineController = StreamController<int>.broadcast();
  final _onVolumeIndicationController =
      StreamController<List<AudioVolumeInfo>>.broadcast();

  /// Emits the UID of a remote user who joined the channel.
  Stream<int> get onUserJoined => _onUserJoinedController.stream;

  /// Emits the UID of a remote user who left the channel.
  Stream<int> get onUserOffline => _onUserOfflineController.stream;

  /// Emits volume information for all active speakers.
  /// Used to detect who is currently speaking (volume > threshold).
  Stream<List<AudioVolumeInfo>> get onVolumeIndication =>
      _onVolumeIndicationController.stream;

  // ── Initialization ────────────────────────────────────────

  /// Initializes the Agora RTC engine with the given [appId].
  ///
  /// Configures the engine for audio-only live broadcasting:
  /// - Disables video entirely (saves bandwidth)
  /// - Sets channel profile to live broadcasting
  /// - Enables audio volume indication for speaking detection
  ///
  /// Throws [Exception] if [appId] is empty.
  Future<void> initialize(String appId) async {
    if (appId.isEmpty) {
      throw Exception(
        'AgoraService: App ID is empty. '
        'Please set AppConfig.agoraAppId from https://console.agora.io',
      );
    }

    if (_engine != null) {
      developer.log('AgoraService already initialized, skipping.',
          name: 'AgoraService');
      return;
    }

    developer.log('Initializing Agora RTC engine...', name: 'AgoraService');

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // Audio-only: disable video completely.
    await _engine!.disableVideo();
    await _engine!.enableAudio();

    // Enable volume indication for speaking detection.
    // interval: how often (ms) the callback fires.
    // smooth: smoothing factor (1–10, higher = smoother).
    // reportVad: report voice activity detection for local user.
    await _engine!.enableAudioVolumeIndication(
      interval: AppConfig.agoraVolumeInterval,
      smooth: 3,
      reportVad: true,
    );

    // Register event handlers.
    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        developer.log(
          '✅ Joined channel: ${connection.channelId}, '
          'uid: ${connection.localUid}, elapsed: ${elapsed}ms',
          name: 'AgoraService',
        );
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        developer.log(
          '👤 Remote user joined: uid=$remoteUid',
          name: 'AgoraService',
        );
        _onUserJoinedController.add(remoteUid);
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        developer.log(
          '👤 Remote user offline: uid=$remoteUid, reason=$reason',
          name: 'AgoraService',
        );
        _onUserOfflineController.add(remoteUid);
      },
      onAudioVolumeIndication: (RtcConnection connection,
          List<AudioVolumeInfo> speakers, int totalVolume,
          int totalVolumeAfterAudioMixing) {
        _onVolumeIndicationController.add(speakers);
      },
      onError: (ErrorCodeType err, String msg) {
        developer.log(
          '❌ Agora error: $err — $msg',
          name: 'AgoraService',
          error: msg,
        );
      },
    ));

    developer.log('✅ Agora RTC engine initialized.', name: 'AgoraService');
  }

  // ── Permission ────────────────────────────────────────────

  /// Requests microphone permission from the OS.
  ///
  /// Returns `true` if granted, `false` otherwise.
  /// Must be called before [joinChannel] on both Android and iOS.
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    developer.log(
      'Microphone permission: $status',
      name: 'AgoraService',
    );
    return status.isGranted;
  }

  // ── Channel Operations ────────────────────────────────────

  /// Joins an Agora voice channel.
  ///
  /// Parameters:
  /// - [channelName]: The Agora channel to join (matches Room.AgoraChannelName)
  /// - [token]: Authentication token from backend. Pass `null` for testing
  ///   mode (Agora project must have "No Certificate" enabled).
  /// - [uid]: User ID. Use 0 for auto-assignment.
  ///
  /// Throws if the engine is not initialized.
  Future<void> joinChannel({
    required String channelName,
    String? token,
    int uid = 0,
  }) async {
    _ensureInitialized();

    developer.log(
      'Joining channel: $channelName, uid: $uid',
      name: 'AgoraService',
    );

    // Set role to broadcaster so this user can send audio.
    await _engine!.setClientRole(
      role: ClientRoleType.clientRoleBroadcaster,
    );

    await _engine!.joinChannel(
      token: token ?? '',
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  /// Leaves the current Agora voice channel.
  Future<void> leaveChannel() async {
    _ensureInitialized();
    developer.log('Leaving channel...', name: 'AgoraService');
    await _engine!.leaveChannel();
  }

  // ── Microphone Control ────────────────────────────────────

  /// Toggles the local microphone.
  ///
  /// [enabled] = `true`  → microphone ON (user can be heard)
  /// [enabled] = `false` → microphone OFF (muted)
  Future<void> toggleMic(bool enabled) async {
    _ensureInitialized();
    await _engine!.enableLocalAudio(enabled);
    developer.log(
      'Microphone ${enabled ? "ON" : "OFF"}',
      name: 'AgoraService',
    );
  }

  // ── Cleanup ───────────────────────────────────────────────

  /// Releases all Agora resources and closes stream controllers.
  ///
  /// Call this when the user permanently leaves the audio room
  /// (not on temporary disconnects).
  Future<void> dispose() async {
    developer.log('Disposing AgoraService...', name: 'AgoraService');

    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
    }

    // Note: We do NOT close broadcast stream controllers in singleton
    // because the singleton persists across navigations.
    // They will be garbage collected when the app exits.
  }

  // ── Private Helpers ───────────────────────────────────────

  /// Throws if the engine has not been initialized.
  void _ensureInitialized() {
    if (_engine == null) {
      throw StateError(
        'AgoraService: Engine not initialized. Call initialize() first.',
      );
    }
  }
}
