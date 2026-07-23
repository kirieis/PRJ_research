// lib/features/ai_suggestion/bloc/ai_suggestion_state.dart
// ============================================================
// Project LUCY — AI Suggestion BLoC State
// ============================================================

import 'package:equatable/equatable.dart';

import '../model/suggestion.dart';
import '../model/vocabulary_item.dart';

/// Status of the AI suggestion pipeline.
enum AiSuggestionStatus {
  /// Pipeline not started.
  idle,

  /// Listening to audio, no suggestions yet.
  listening,

  /// Processing transcript through LLM.
  loading,

  /// Suggestions available and displayed.
  showing,

  /// Suggestions dismissed by user or auto-hidden.
  dismissed,

  /// Error in the pipeline.
  error,
}

/// State for the AI suggestion BLoC.
class AiSuggestionState extends Equatable {
  /// Current pipeline status.
  final AiSuggestionStatus status;

  /// Current suggestions to display.
  final List<AiSuggestion> suggestions;

  /// Latest transcript text from STT.
  final String currentTranscript;

  /// Current room topic.
  final String topic;

  /// User's CEFR level.
  final String level;

  /// Target language.
  final String language;

  /// Vocabulary items saved during this session.
  final List<VocabularyItem> savedVocabulary;

  /// Total suggestions shown in this session (for analytics).
  final int totalSuggestionsShown;

  /// Total vocabulary words saved in this session.
  final int totalVocabularySaved;

  /// Last LLM response latency in milliseconds.
  final int lastLatencyMs;

  /// Error message if status is [AiSuggestionStatus.error].
  final String? errorMessage;

  const AiSuggestionState({
    this.status = AiSuggestionStatus.idle,
    this.suggestions = const [],
    this.currentTranscript = '',
    this.topic = '',
    this.level = 'A1',
    this.language = 'en',
    this.savedVocabulary = const [],
    this.totalSuggestionsShown = 0,
    this.totalVocabularySaved = 0,
    this.lastLatencyMs = 0,
    this.errorMessage,
  });

  /// Whether suggestions are currently visible.
  bool get isShowingSuggestions => status == AiSuggestionStatus.showing;

  /// Whether the pipeline is active (listening or processing).
  bool get isActive =>
      status == AiSuggestionStatus.listening ||
      status == AiSuggestionStatus.loading ||
      status == AiSuggestionStatus.showing;

  AiSuggestionState copyWith({
    AiSuggestionStatus? status,
    List<AiSuggestion>? suggestions,
    String? currentTranscript,
    String? topic,
    String? level,
    String? language,
    List<VocabularyItem>? savedVocabulary,
    int? totalSuggestionsShown,
    int? totalVocabularySaved,
    int? lastLatencyMs,
    String? errorMessage,
  }) {
    return AiSuggestionState(
      status: status ?? this.status,
      suggestions: suggestions ?? this.suggestions,
      currentTranscript: currentTranscript ?? this.currentTranscript,
      topic: topic ?? this.topic,
      level: level ?? this.level,
      language: language ?? this.language,
      savedVocabulary: savedVocabulary ?? this.savedVocabulary,
      totalSuggestionsShown:
          totalSuggestionsShown ?? this.totalSuggestionsShown,
      totalVocabularySaved:
          totalVocabularySaved ?? this.totalVocabularySaved,
      lastLatencyMs: lastLatencyMs ?? this.lastLatencyMs,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        suggestions,
        currentTranscript,
        topic,
        level,
        language,
        savedVocabulary,
        totalSuggestionsShown,
        totalVocabularySaved,
        lastLatencyMs,
        errorMessage,
      ];
}
