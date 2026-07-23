// lib/features/ai_suggestion/bloc/ai_suggestion_bloc.dart
// ============================================================
// Project LUCY — AI Suggestion BLoC
//
// Orchestrates the AI suggestion pipeline:
//   1. STT Service → transcript stream
//   2. Silence Detector → trigger on pause
//   3. LLM Service → generate suggestions
//   4. Auto-hide after 8 seconds
//
// Design decisions:
//   - BLoC owns STT + VAD lifecycle (start/stop with session)
//   - LLM calls are debounced (no duplicate requests)
//   - Suggestions auto-dismiss after 8s
//   - Max 3 suggestions at a time
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../service/llm_service.dart';
import '../service/silence_detector.dart';
import '../service/stt_service.dart';
import 'ai_suggestion_event.dart';
import 'ai_suggestion_state.dart';

class AiSuggestionBloc extends Bloc<AiSuggestionEvent, AiSuggestionState> {
  final SttService _sttService;
  final LlmService _llmService;
  late final SilenceDetector _silenceDetector;

  StreamSubscription? _transcriptSub;
  Timer? _autoHideTimer;

  /// Auto-hide suggestions after this duration.
  static const _autoHideDuration = Duration(seconds: 8);

  AiSuggestionBloc({
    SttService? sttService,
    LlmService? llmService,
  })  : _sttService = sttService ?? SttService(),
        _llmService = llmService ?? LlmService(),
        super(const AiSuggestionState()) {
    _silenceDetector = SilenceDetector(
      silenceDuration: const Duration(seconds: 3),
      onSilenceDetected: (duration) {
        add(AiSuggestionSilenceDetected(silenceDuration: duration));
      },
      onSpeechResumed: () {
        add(const AiSuggestionSpeechResumed());
      },
    );

    on<AiSuggestionSessionStarted>(_onSessionStarted);
    on<AiSuggestionSessionEnded>(_onSessionEnded);
    on<AiSuggestionTranscriptReceived>(_onTranscriptReceived);
    on<AiSuggestionSilenceDetected>(_onSilenceDetected);
    on<AiSuggestionManuallyRequested>(_onManuallyRequested);
    on<AiSuggestionSpeechResumed>(_onSpeechResumed);
    on<AiSuggestionReceived>(_onSuggestionReceived);
    on<AiSuggestionDismissed>(_onDismissed);
    on<AiSuggestionVocabularySaved>(_onVocabularySaved);
  }

  /// Expose silence detector for volume reporting from Agora.
  SilenceDetector get silenceDetector => _silenceDetector;

  // ── SESSION LIFECYCLE ───────────────────────────────────────

  Future<void> _onSessionStarted(
    AiSuggestionSessionStarted event,
    Emitter<AiSuggestionState> emit,
  ) async {
    developer.log(
      '🤖 AI Suggestion session started: ${event.topic} (${event.level})',
      name: 'AiSuggestionBloc',
    );

    emit(state.copyWith(
      status: AiSuggestionStatus.listening,
      topic: event.topic,
      level: event.level,
      language: event.language,
      suggestions: [],
      currentTranscript: '',
      totalSuggestionsShown: 0,
      totalVocabularySaved: 0,
    ));

    // Start STT listening
    await _sttService.startListening(
      language: event.language,
      useMock: true, // MVP mode
    );

    // Subscribe to transcripts
    _transcriptSub?.cancel();
    _transcriptSub = _sttService.transcriptStream.listen((result) {
      add(AiSuggestionTranscriptReceived(
        text: result.text,
        isFinal: result.isFinal,
      ));
    });
  }

  Future<void> _onSessionEnded(
    AiSuggestionSessionEnded event,
    Emitter<AiSuggestionState> emit,
  ) async {
    developer.log(
      '🤖 AI Suggestion session ended. '
      'Suggestions shown: ${state.totalSuggestionsShown}, '
      'Vocab saved: ${state.totalVocabularySaved}',
      name: 'AiSuggestionBloc',
    );

    _transcriptSub?.cancel();
    _autoHideTimer?.cancel();
    await _sttService.stopListening();
    _silenceDetector.reset();

    emit(state.copyWith(
      status: AiSuggestionStatus.idle,
      suggestions: [],
    ));
  }

  // ── TRANSCRIPT HANDLING ─────────────────────────────────────

  void _onTranscriptReceived(
    AiSuggestionTranscriptReceived event,
    Emitter<AiSuggestionState> emit,
  ) {
    if (event.isFinal) {
      emit(state.copyWith(currentTranscript: event.text));
    }
  }

  // ── SUGGESTION TRIGGERS ─────────────────────────────────────

  Future<void> _onSilenceDetected(
    AiSuggestionSilenceDetected event,
    Emitter<AiSuggestionState> emit,
  ) async {
    if (state.status == AiSuggestionStatus.loading) return;
    if (state.currentTranscript.isEmpty) return;

    developer.log(
      '🔇 Silence detected (${event.silenceDuration.inSeconds}s) — requesting suggestions',
      name: 'AiSuggestionBloc',
    );

    await _requestSuggestions(emit);
  }

  Future<void> _onManuallyRequested(
    AiSuggestionManuallyRequested event,
    Emitter<AiSuggestionState> emit,
  ) async {
    if (state.status == AiSuggestionStatus.loading) return;

    developer.log(
      '💡 Manual suggestion requested',
      name: 'AiSuggestionBloc',
    );

    await _requestSuggestions(emit);
  }

  Future<void> _requestSuggestions(
    Emitter<AiSuggestionState> emit,
  ) async {
    emit(state.copyWith(status: AiSuggestionStatus.loading));

    try {
      final response = await _llmService.getSuggestions(
        transcript: state.currentTranscript.isNotEmpty
            ? state.currentTranscript
            : 'Hello, how are you?',
        topic: state.topic,
        level: state.level,
        language: state.language,
        useMock: true, // MVP mode
      );

      add(AiSuggestionReceived(response: response));
    } catch (e) {
      developer.log('❌ LLM error: $e', name: 'AiSuggestionBloc');
      emit(state.copyWith(
        status: AiSuggestionStatus.error,
        errorMessage: 'Không thể tạo gợi ý: $e',
      ));
    }
  }

  // ── SUGGESTION DISPLAY ──────────────────────────────────────

  void _onSuggestionReceived(
    AiSuggestionReceived event,
    Emitter<AiSuggestionState> emit,
  ) {
    _autoHideTimer?.cancel();

    emit(state.copyWith(
      status: AiSuggestionStatus.showing,
      suggestions: event.response.suggestions.take(3).toList(),
      lastLatencyMs: event.response.latencyMs,
      totalSuggestionsShown:
          state.totalSuggestionsShown + event.response.suggestions.length,
    ));

    // Auto-hide after 8 seconds
    _autoHideTimer = Timer(_autoHideDuration, () {
      add(const AiSuggestionDismissed());
    });
  }

  void _onSpeechResumed(
    AiSuggestionSpeechResumed event,
    Emitter<AiSuggestionState> emit,
  ) {
    _autoHideTimer?.cancel();
    if (state.isShowingSuggestions) {
      emit(state.copyWith(
        status: AiSuggestionStatus.listening,
        suggestions: [],
      ));
    }
  }

  void _onDismissed(
    AiSuggestionDismissed event,
    Emitter<AiSuggestionState> emit,
  ) {
    _autoHideTimer?.cancel();
    emit(state.copyWith(
      status: AiSuggestionStatus.listening,
      suggestions: [],
    ));
  }

  // ── VOCABULARY SAVE ─────────────────────────────────────────

  void _onVocabularySaved(
    AiSuggestionVocabularySaved event,
    Emitter<AiSuggestionState> emit,
  ) {
    // Find and mark the vocabulary item as saved
    final allVocab = state.suggestions
        .expand((s) => s.vocabulary)
        .where((v) => v.word == event.word)
        .toList();

    if (allVocab.isNotEmpty) {
      final saved = [...state.savedVocabulary, allVocab.first];
      developer.log(
        '📖 Vocabulary saved: ${event.word}',
        name: 'AiSuggestionBloc',
      );
      emit(state.copyWith(
        savedVocabulary: saved,
        totalVocabularySaved: state.totalVocabularySaved + 1,
      ));
    }
  }

  // ── CLEANUP ─────────────────────────────────────────────────

  @override
  Future<void> close() {
    _transcriptSub?.cancel();
    _autoHideTimer?.cancel();
    _sttService.dispose();
    _silenceDetector.dispose();
    return super.close();
  }
}
