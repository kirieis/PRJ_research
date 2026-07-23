// lib/features/ai_suggestion/model/suggestion.dart
// ============================================================
// Project LUCY — AI Suggestion Data Model
//
// Represents a real-time suggestion from the AI pipeline:
//   STT transcript → LLM analysis → suggestion phrases
// ============================================================

import 'package:equatable/equatable.dart';

import 'vocabulary_item.dart';

/// A single AI suggestion displayed in the Suggestion Bubble.
class AiSuggestion extends Equatable {
  /// Unique ID for this suggestion.
  final String id;

  /// Suggested phrase the user can say next.
  /// e.g. "quite pleasant today"
  final String phrase;

  /// Context hint for when to use this phrase.
  /// e.g. "To continue describing the weather"
  final String? contextHint;

  /// Vocabulary items extracted from this suggestion.
  final List<VocabularyItem> vocabulary;

  /// Confidence score from the LLM (0.0 → 1.0).
  final double confidence;

  /// Timestamp when the suggestion was generated.
  final DateTime createdAt;

  const AiSuggestion({
    required this.id,
    required this.phrase,
    this.contextHint,
    this.vocabulary = const [],
    this.confidence = 0.8,
    required this.createdAt,
  });

  factory AiSuggestion.fromJson(Map<String, dynamic> json) {
    return AiSuggestion(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      phrase: json['phrase'] as String,
      contextHint: json['contextHint'] as String?,
      vocabulary: (json['vocabulary'] as List<dynamic>?)
              ?.map((v) => VocabularyItem.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, phrase, contextHint, vocabulary, confidence];
}

/// Response from the AI suggestion API.
class AiSuggestionResponse extends Equatable {
  /// List of suggested phrases.
  final List<AiSuggestion> suggestions;

  /// The transcript that triggered this suggestion.
  final String sourceTranscript;

  /// Current topic context.
  final String? topic;

  /// Processing latency in milliseconds.
  final int latencyMs;

  const AiSuggestionResponse({
    required this.suggestions,
    required this.sourceTranscript,
    this.topic,
    this.latencyMs = 0,
  });

  factory AiSuggestionResponse.fromJson(Map<String, dynamic> json) {
    return AiSuggestionResponse(
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((s) => AiSuggestion.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      sourceTranscript: json['sourceTranscript'] as String? ?? '',
      topic: json['topic'] as String?,
      latencyMs: json['latencyMs'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [suggestions, sourceTranscript, topic, latencyMs];
}
