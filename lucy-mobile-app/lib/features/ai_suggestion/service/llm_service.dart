// lib/features/ai_suggestion/service/llm_service.dart
// ============================================================
// Project LUCY — LLM Service (Gemini Flash)
//
// Sends conversation context to LLM for real-time suggestions.
// Optimized for low-latency (<800ms) using Gemini 2.0 Flash.
//
// MVP: Returns mock suggestions for UI development.
// Production: Calls Gemini Flash API or backend proxy.
// ============================================================

import 'dart:async';
import 'dart:developer' as developer;

import '../model/suggestion.dart';
import '../model/vocabulary_item.dart';

/// LLM service for generating AI suggestions.
///
/// **Pipeline:**
/// 1. Receives transcript + topic + user level
/// 2. Constructs prompt with context
/// 3. Calls LLM API (Gemini Flash)
/// 4. Parses response into [AiSuggestionResponse]
///
/// **MVP Mode:** Returns mock suggestions instantly.
/// **Production Mode:** Calls backend `/api/ai/suggest` endpoint.
class LlmService {
  /// Target latency for LLM response.
  static const Duration targetLatency = Duration(milliseconds: 800);

  /// Generate suggestions based on conversation context.
  ///
  /// [transcript] — Recent speech transcript (last ~30 seconds).
  /// [topic] — Current room topic (e.g. "Daily Greetings").
  /// [level] — User's CEFR level (e.g. "A1", "B2").
  /// [language] — Target language (e.g. "en", "ja").
  /// [useMock] — If true, returns mock data without API call.
  Future<AiSuggestionResponse> getSuggestions({
    required String transcript,
    required String topic,
    String level = 'A1',
    String language = 'en',
    bool useMock = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    developer.log(
      '🤖 LLM request: "$transcript" (topic: $topic, level: $level)',
      name: 'LlmService',
    );

    AiSuggestionResponse response;

    if (useMock) {
      response = await _getMockSuggestions(
        transcript: transcript,
        topic: topic,
        level: level,
        language: language,
      );
    } else {
      // TODO: Call backend API
      // response = await _callGeminiFlash(transcript, topic, level, language);
      response = await _getMockSuggestions(
        transcript: transcript,
        topic: topic,
        level: level,
        language: language,
      );
    }

    stopwatch.stop();
    developer.log(
      '🤖 LLM response: ${response.suggestions.length} suggestions '
      '(${stopwatch.elapsedMilliseconds}ms)',
      name: 'LlmService',
    );

    return AiSuggestionResponse(
      suggestions: response.suggestions,
      sourceTranscript: transcript,
      topic: topic,
      latencyMs: stopwatch.elapsedMilliseconds,
    );
  }

  // ── Mock Suggestions ────────────────────────────────────────

  /// Context-aware mock suggestions based on transcript keywords.
  Future<AiSuggestionResponse> _getMockSuggestions({
    required String transcript,
    required String topic,
    required String level,
    required String language,
  }) async {
    // Simulate network latency (200-600ms)
    await Future.delayed(const Duration(milliseconds: 400));

    final lower = transcript.toLowerCase();
    final now = DateTime.now();

    // Context-aware suggestion selection
    List<AiSuggestion> suggestions;

    if (lower.contains('weather') || lower.contains('pleasant')) {
      suggestions = [
        AiSuggestion(
          id: 'sug_${now.millisecondsSinceEpoch}_1',
          phrase: 'quite pleasant today',
          contextHint: 'To describe the weather positively',
          vocabulary: const [
            VocabularyItem(
              word: 'pleasant',
              pronunciation: '/ˈplɛzənt/',
              partOfSpeech: 'adj',
              meaning: 'dễ chịu, thoải mái',
              example: 'The weather is quite pleasant today.',
              cefrLevel: 'A2',
            ),
          ],
          confidence: 0.92,
          createdAt: now,
        ),
        AiSuggestion(
          id: 'sug_${now.millisecondsSinceEpoch}_2',
          phrase: 'getting warmer recently',
          contextHint: 'To continue the weather topic',
          vocabulary: const [
            VocabularyItem(
              word: 'recently',
              pronunciation: '/ˈriːsəntli/',
              partOfSpeech: 'adv',
              meaning: 'gần đây',
              example: 'It has been getting warmer recently.',
              cefrLevel: 'A2',
            ),
          ],
          confidence: 0.85,
          createdAt: now,
        ),
      ];
    } else if (lower.contains('weekend') || lower.contains('hobby')) {
      suggestions = [
        AiSuggestion(
          id: 'sug_${now.millisecondsSinceEpoch}_1',
          phrase: 'I usually spend my weekends...',
          contextHint: 'To share your weekend routine',
          vocabulary: const [
            VocabularyItem(
              word: 'usually',
              pronunciation: '/ˈjuːʒuəli/',
              partOfSpeech: 'adv',
              meaning: 'thường xuyên',
              example: 'I usually go jogging on Saturday mornings.',
              cefrLevel: 'A1',
            ),
          ],
          confidence: 0.90,
          createdAt: now,
        ),
        AiSuggestion(
          id: 'sug_${now.millisecondsSinceEpoch}_2',
          phrase: 'What about you? Do you have any hobbies?',
          contextHint: 'To ask about the other person\'s interests',
          vocabulary: const [
            VocabularyItem(
              word: 'hobby',
              pronunciation: '/ˈhɒbi/',
              partOfSpeech: 'noun',
              meaning: 'sở thích',
              example: 'Reading is one of my favorite hobbies.',
              cefrLevel: 'A1',
            ),
          ],
          confidence: 0.88,
          createdAt: now,
        ),
      ];
    } else if (lower.contains('travel') || lower.contains('japan')) {
      suggestions = [
        AiSuggestion(
          id: 'sug_${now.millisecondsSinceEpoch}_1',
          phrase: 'That sounds like an amazing experience!',
          contextHint: 'To react positively to a travel story',
          vocabulary: const [
            VocabularyItem(
              word: 'experience',
              pronunciation: '/ɪkˈspɪəriəns/',
              partOfSpeech: 'noun',
              meaning: 'trải nghiệm',
              example: 'Traveling abroad is always a great experience.',
              cefrLevel: 'A2',
            ),
          ],
          confidence: 0.91,
          createdAt: now,
        ),
        AiSuggestion(
          id: 'sug_${now.millisecondsSinceEpoch}_2',
          phrase: 'What was the most memorable part of your trip?',
          contextHint: 'To ask a follow-up question',
          vocabulary: const [
            VocabularyItem(
              word: 'memorable',
              pronunciation: '/ˈmɛmərəbl/',
              partOfSpeech: 'adj',
              meaning: 'đáng nhớ',
              example: 'It was the most memorable vacation I ever had.',
              cefrLevel: 'B1',
            ),
          ],
          confidence: 0.87,
          createdAt: now,
        ),
      ];
    } else {
      // Default suggestions for any context
      suggestions = [
        AiSuggestion(
          id: 'sug_${now.millisecondsSinceEpoch}_1',
          phrase: 'Could you tell me more about that?',
          contextHint: 'To ask for elaboration',
          vocabulary: const [
            VocabularyItem(
              word: 'elaborate',
              pronunciation: '/ɪˈlæbəreɪt/',
              partOfSpeech: 'verb',
              meaning: 'giải thích thêm',
              example: 'Could you elaborate on that point?',
              cefrLevel: 'B1',
            ),
          ],
          confidence: 0.85,
          createdAt: now,
        ),
        AiSuggestion(
          id: 'sug_${now.millisecondsSinceEpoch}_2',
          phrase: 'That\'s an interesting point of view!',
          contextHint: 'To acknowledge the speaker',
          vocabulary: const [
            VocabularyItem(
              word: 'point of view',
              pronunciation: '/pɔɪnt əv vjuː/',
              partOfSpeech: 'noun',
              meaning: 'quan điểm',
              example: 'Everyone has their own point of view.',
              cefrLevel: 'A2',
            ),
          ],
          confidence: 0.82,
          createdAt: now,
        ),
      ];
    }

    return AiSuggestionResponse(
      suggestions: suggestions,
      sourceTranscript: transcript,
      topic: topic,
    );
  }
}
