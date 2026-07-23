// lib/features/ai_suggestion/service/silence_detector.dart
// ============================================================
// Project LUCY — Voice Activity Detection (VAD)
//
// Detects silence periods in the audio stream to trigger
// AI suggestions. Uses a simple threshold-based approach:
//   - Tracks consecutive silence duration
//   - Fires callback when silence exceeds threshold (default 3s)
//   - Resets when speech resumes
//
// This runs client-side to minimize latency. The Agora SDK
// provides volume indicators that we use as input.
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;

/// Callback fired when a silence period is detected.
typedef OnSilenceDetected = void Function(Duration silenceDuration);

/// Callback fired when the user starts speaking after silence.
typedef OnSpeechResumed = void Function();

/// Simple threshold-based Voice Activity Detection.
///
/// **How it works:**
/// 1. [reportVolume] is called with Agora's volume indicator (~100ms)
/// 2. If volume < [silenceThreshold] for > [silenceDuration], fire callback
/// 3. When volume rises above threshold, fire speech resumed callback
///
/// **Usage:**
/// ```dart
/// final vad = SilenceDetector(
///   silenceDuration: Duration(seconds: 3),
///   onSilenceDetected: (duration) => bloc.add(SilenceDetected()),
///   onSpeechResumed: () => bloc.add(SpeechResumed()),
/// );
///
/// // In Agora volume indicator callback:
/// vad.reportVolume(volume);
///
/// // Cleanup:
/// vad.dispose();
/// ```
class SilenceDetector {
  /// Minimum silence duration before triggering (default: 3 seconds).
  final Duration silenceDuration;

  /// Volume level below which is considered "silence" (0-255).
  /// Agora reports volume in 0-255 range.
  final int silenceThreshold;

  /// Callback when silence threshold is exceeded.
  final OnSilenceDetected? onSilenceDetected;

  /// Callback when user starts speaking again.
  final OnSpeechResumed? onSpeechResumed;

  /// Minimum interval between silence detections to prevent spam.
  final Duration cooldown;

  Timer? _silenceTimer;
  bool _isSilent = false;
  bool _silenceReported = false;
  DateTime? _lastSilenceReport;
  DateTime? _silenceStartTime;

  SilenceDetector({
    this.silenceDuration = const Duration(seconds: 3),
    this.silenceThreshold = 10,
    this.onSilenceDetected,
    this.onSpeechResumed,
    this.cooldown = const Duration(seconds: 8),
  });

  /// Report current audio volume from Agora's volume indicator.
  ///
  /// Call this from `onAudioVolumeIndication` callback (~100ms interval).
  /// [volume] is in range 0-255 (Agora native format).
  void reportVolume(int volume) {
    if (volume < silenceThreshold) {
      _onSilence();
    } else {
      _onSpeech();
    }
  }

  void _onSilence() {
    if (!_isSilent) {
      _isSilent = true;
      _silenceStartTime = DateTime.now();

      // Start timer for silence detection
      _silenceTimer?.cancel();
      _silenceTimer = Timer(silenceDuration, () {
        if (!_isSilent) return;

        // Check cooldown
        if (_lastSilenceReport != null) {
          final elapsed = DateTime.now().difference(_lastSilenceReport!);
          if (elapsed < cooldown) return;
        }

        _silenceReported = true;
        _lastSilenceReport = DateTime.now();
        final duration = DateTime.now().difference(_silenceStartTime!);

        developer.log(
          '🔇 Silence detected: ${duration.inSeconds}s',
          name: 'SilenceDetector',
        );

        onSilenceDetected?.call(duration);
      });
    }
  }

  void _onSpeech() {
    if (_isSilent) {
      _isSilent = false;
      _silenceTimer?.cancel();

      if (_silenceReported) {
        _silenceReported = false;
        developer.log('🔊 Speech resumed', name: 'SilenceDetector');
        onSpeechResumed?.call();
      }
    }
    _silenceStartTime = null;
  }

  /// Whether the detector is currently in silence state.
  bool get isSilent => _isSilent;

  /// Duration of current silence (null if not silent).
  Duration? get currentSilenceDuration {
    if (!_isSilent || _silenceStartTime == null) return null;
    return DateTime.now().difference(_silenceStartTime!);
  }

  /// Reset the detector state.
  void reset() {
    _silenceTimer?.cancel();
    _isSilent = false;
    _silenceReported = false;
    _silenceStartTime = null;
    _lastSilenceReport = null;
  }

  /// Dispose of all resources.
  void dispose() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }
}
