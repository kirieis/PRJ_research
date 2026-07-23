// lib/features/ai_suggestion/bloc/ai_suggestion_event.dart
// ============================================================
// Project LUCY — AI Suggestion BLoC Events
// ============================================================

import 'package:equatable/equatable.dart';

import '../model/suggestion.dart';

/// Base event for the AI suggestion BLoC.
sealed class AiSuggestionEvent extends Equatable {
  const AiSuggestionEvent();

  @override
  List<Object?> get props => [];
}

/// Start the AI suggestion pipeline for a room session.
class AiSuggestionSessionStarted extends AiSuggestionEvent {
  final String topic;
  final String level;
  final String language;

  const AiSuggestionSessionStarted({
    required this.topic,
    this.level = 'A1',
    this.language = 'en',
  });

  @override
  List<Object?> get props => [topic, level, language];
}

/// Stop the AI suggestion pipeline.
class AiSuggestionSessionEnded extends AiSuggestionEvent {
  const AiSuggestionSessionEnded();
}

/// Silence detected by VAD — trigger suggestion request.
class AiSuggestionSilenceDetected extends AiSuggestionEvent {
  final Duration silenceDuration;

  const AiSuggestionSilenceDetected({required this.silenceDuration});

  @override
  List<Object?> get props => [silenceDuration];
}

/// User manually requested a suggestion (tapped 💡 button).
class AiSuggestionManuallyRequested extends AiSuggestionEvent {
  const AiSuggestionManuallyRequested();
}

/// Speech resumed — auto-hide suggestions.
class AiSuggestionSpeechResumed extends AiSuggestionEvent {
  const AiSuggestionSpeechResumed();
}

/// New transcript received from STT service.
class AiSuggestionTranscriptReceived extends AiSuggestionEvent {
  final String text;
  final bool isFinal;

  const AiSuggestionTranscriptReceived({
    required this.text,
    this.isFinal = false,
  });

  @override
  List<Object?> get props => [text, isFinal];
}

/// Suggestions received from LLM service.
class AiSuggestionReceived extends AiSuggestionEvent {
  final AiSuggestionResponse response;

  const AiSuggestionReceived({required this.response});

  @override
  List<Object?> get props => [response];
}

/// User dismissed the suggestion bubble.
class AiSuggestionDismissed extends AiSuggestionEvent {
  const AiSuggestionDismissed();
}

/// User saved a vocabulary item to their notebook.
class AiSuggestionVocabularySaved extends AiSuggestionEvent {
  final String word;

  const AiSuggestionVocabularySaved({required this.word});

  @override
  List<Object?> get props => [word];
}
