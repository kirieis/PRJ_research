// lib/features/ai_suggestion/service/stt_service.dart
// ============================================================
// Project LUCY — Speech-to-Text Service (Deepgram Streaming)
//
// Streams audio from Agora RTC to Deepgram via WebSocket for
// real-time transcription. Provides interim and final transcripts.
//
// Architecture:
//   Agora Audio Frames → PCM Buffer → WebSocket → Deepgram
//   Deepgram → JSON response → Transcript Stream
//
// MVP: Uses mock transcripts for development without API key.
// Production: Swap to real Deepgram WebSocket endpoint.
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;

/// Transcript result from STT service.
class TranscriptResult {
  /// The transcribed text.
  final String text;

  /// Whether this is a final (committed) transcript vs interim.
  final bool isFinal;

  /// Confidence score (0.0 → 1.0).
  final double confidence;

  /// Language detected.
  final String? language;

  const TranscriptResult({
    required this.text,
    this.isFinal = false,
    this.confidence = 0.0,
    this.language,
  });
}

/// Speech-to-Text streaming service.
///
/// **MVP Mode:** Returns mock transcripts for UI development.
/// **Production Mode:** Connects to Deepgram WebSocket for real STT.
///
/// Usage:
/// ```dart
/// final stt = SttService();
/// await stt.startListening(language: 'en');
///
/// stt.transcriptStream.listen((result) {
///   print('${result.isFinal ? "FINAL" : "interim"}: ${result.text}');
/// });
///
/// // Feed audio data from Agora:
/// stt.feedAudioData(pcmBytes);
///
/// await stt.stopListening();
/// ```
class SttService {
  final _transcriptController =
      StreamController<TranscriptResult>.broadcast();

  bool _isListening = false;
  String _currentLanguage = 'en';

  // Mock simulation
  Timer? _mockTimer;
  int _mockIndex = 0;

  /// Stream of transcript results (interim + final).
  Stream<TranscriptResult> get transcriptStream =>
      _transcriptController.stream;

  /// Whether the service is currently listening.
  bool get isListening => _isListening;

  /// Accumulated transcript text for the current session.
  final StringBuffer _sessionTranscript = StringBuffer();

  /// Get the full session transcript so far.
  String get sessionTranscript => _sessionTranscript.toString();

  /// Start listening for speech.
  ///
  /// [language] — BCP-47 language code (e.g. 'en', 'ja', 'zh').
  /// [useMock] — If true, uses mock transcripts instead of real STT.
  Future<void> startListening({
    String language = 'en',
    bool useMock = true,
  }) async {
    if (_isListening) return;

    _currentLanguage = language;
    _isListening = true;
    _sessionTranscript.clear();
    _mockIndex = 0;

    developer.log(
      '🎤 STT started (lang: $language, mock: $useMock)',
      name: 'SttService',
    );

    if (useMock) {
      _startMockTranscription();
    } else {
      // TODO: Initialize Deepgram WebSocket connection
      // _connectDeepgram(language);
      developer.log(
        '⚠️ Real Deepgram STT not yet implemented — using mock',
        name: 'SttService',
      );
      _startMockTranscription();
    }
  }

  /// Feed raw PCM audio data to the STT engine.
  ///
  /// In production, this sends audio bytes to Deepgram WebSocket.
  /// In mock mode, this is ignored (mock generates its own transcripts).
  void feedAudioData(List<int> pcmBytes) {
    if (!_isListening) return;
    // TODO: Send pcmBytes to Deepgram WebSocket
    // _deepgramSocket?.add(pcmBytes);
  }

  /// Stop listening and cleanup.
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    _mockTimer?.cancel();
    _mockTimer = null;

    developer.log(
      '🎤 STT stopped. Session transcript: ${_sessionTranscript.length} chars',
      name: 'SttService',
    );
  }

  /// Dispose all resources.
  void dispose() {
    stopListening();
    if (!_transcriptController.isClosed) {
      _transcriptController.close();
    }
  }

  // ── Mock Transcription ──────────────────────────────────────

  /// Mock transcripts for different languages.
  static const Map<String, List<String>> _mockTranscripts = {
    'en': [
      'Hello everyone',
      'I think the weather is',
      'quite pleasant today',
      'What do you usually do on weekends',
      'I enjoy reading books and watching movies',
      'Have you ever traveled abroad',
      'I went to Japan last year',
      'The food there was amazing',
    ],
    'ja': [
      'みなさん、こんにちは',
      '今日の天気は',
      'とても良いですね',
      '週末は何をしますか',
      '本を読んだり映画を見たりします',
    ],
    'zh': [
      '大家好',
      '今天天气',
      '非常好',
      '周末你们通常做什么',
      '我喜欢看书和看电影',
    ],
  };

  void _startMockTranscription() {
    final transcripts =
        _mockTranscripts[_currentLanguage] ?? _mockTranscripts['en']!;

    _mockTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isListening || _mockIndex >= transcripts.length) {
        timer.cancel();
        return;
      }

      final text = transcripts[_mockIndex];

      // Emit interim first
      if (!_transcriptController.isClosed) {
        _transcriptController.add(TranscriptResult(
          text: text,
          isFinal: false,
          confidence: 0.7,
          language: _currentLanguage,
        ));
      }

      // Then emit final after 500ms
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isListening || _transcriptController.isClosed) return;

        _sessionTranscript.write('$text. ');
        _transcriptController.add(TranscriptResult(
          text: text,
          isFinal: true,
          confidence: 0.95,
          language: _currentLanguage,
        ));
      });

      _mockIndex++;
    });
  }
}
