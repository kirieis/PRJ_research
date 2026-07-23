// lib/features/post_session/model/session_report.dart
// ============================================================
// Project LUCY — Post-Session Report Data Model
//
// AI-generated session report with:
//   - Engagement metrics breakdown
//   - XP earned with multiplier details
//   - Mistakes corrected
//   - New vocabulary learned
//   - Confidence score trend
// ============================================================

import 'package:equatable/equatable.dart';

import '../../../core/models/level.dart';
import '../../ai_suggestion/model/vocabulary_item.dart';

/// A mistake identified by AI during the session.
class SessionMistake extends Equatable {
  /// What the user said (incorrect).
  final String original;

  /// Corrected version.
  final String correction;

  /// Type of mistake: 'grammar', 'pronunciation', 'vocabulary'.
  final String type;

  /// Explanation in Vietnamese.
  final String explanation;

  const SessionMistake({
    required this.original,
    required this.correction,
    required this.type,
    required this.explanation,
  });

  factory SessionMistake.fromJson(Map<String, dynamic> json) {
    return SessionMistake(
      original: json['original'] as String,
      correction: json['correction'] as String,
      type: json['type'] as String? ?? 'grammar',
      explanation: json['explanation'] as String,
    );
  }

  @override
  List<Object?> get props => [original, correction, type, explanation];
}

/// Complete post-session report.
class SessionReport extends Equatable {
  /// Session ID.
  final String sessionId;

  /// Room ID.
  final String roomId;

  /// Session topic.
  final String topic;

  /// Session duration in seconds.
  final int durationSeconds;

  /// Whether the user completed the full session (all 3 stages).
  final bool completedFullSession;

  /// Raw engagement metrics.
  final EngagementMetrics metrics;

  /// Calculated XP result.
  final XpResult xpResult;

  /// AI-identified mistakes.
  final List<SessionMistake> mistakes;

  /// New vocabulary learned during the session.
  final List<VocabularyItem> newVocabulary;

  /// AI confidence score for this session (0.0 → 1.0).
  final double confidenceScore;

  /// Confidence score change from previous session.
  final double confidenceChange;

  /// AI-generated summary of the session (1-2 sentences).
  final String aiSummary;

  /// Timestamp of session completion.
  final DateTime completedAt;

  const SessionReport({
    required this.sessionId,
    required this.roomId,
    required this.topic,
    required this.durationSeconds,
    this.completedFullSession = true,
    required this.metrics,
    required this.xpResult,
    this.mistakes = const [],
    this.newVocabulary = const [],
    this.confidenceScore = 0.0,
    this.confidenceChange = 0.0,
    this.aiSummary = '',
    required this.completedAt,
  });

  /// Duration formatted as "MM:SS".
  String get durationFormatted {
    final min = durationSeconds ~/ 60;
    final sec = durationSeconds % 60;
    return '${min}m ${sec}s';
  }

  /// Confidence percentage for display (e.g. "72%").
  String get confidencePercentage => '${(confidenceScore * 100).round()}%';

  /// Confidence change formatted (e.g. "+5%" or "-2%").
  String get confidenceChangeFormatted {
    final change = (confidenceChange * 100).round();
    return change >= 0 ? '+$change%' : '$change%';
  }

  /// Whether confidence improved.
  bool get isConfidenceImproved => confidenceChange > 0;

  factory SessionReport.fromJson(Map<String, dynamic> json) {
    final metrics = EngagementMetrics.fromJson(
      json['metrics'] as Map<String, dynamic>? ?? {},
    );
    return SessionReport(
      sessionId: json['sessionId'] as String,
      roomId: json['roomId'] as String,
      topic: json['topic'] as String? ?? '',
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      completedFullSession: json['completedFullSession'] as bool? ?? true,
      metrics: metrics,
      xpResult: XpCalculator.calculate(
        metrics: metrics,
        completedFullSession: json['completedFullSession'] as bool? ?? true,
      ),
      mistakes: (json['mistakes'] as List<dynamic>?)
              ?.map((m) => SessionMistake.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      newVocabulary: (json['newVocabulary'] as List<dynamic>?)
              ?.map((v) => VocabularyItem.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      confidenceChange: (json['confidenceChange'] as num?)?.toDouble() ?? 0.0,
      aiSummary: json['aiSummary'] as String? ?? '',
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Generate a mock report for MVP development.
  factory SessionReport.mock({
    String sessionId = 'session_001',
    String roomId = 'room_001',
    String topic = 'Daily Greetings',
  }) {
    const metrics = EngagementMetrics(
      speakingRatio: 0.65,
      averageResponseTime: 2.5,
      vocabularyUsed: 4,
      vocabularySuggested: 6,
      peerInteractions: 3,
      unmutedDurationSeconds: 780,
      totalDurationSeconds: 1200,
      confidenceScore: 0.72,
    );

    return SessionReport(
      sessionId: sessionId,
      roomId: roomId,
      topic: topic,
      durationSeconds: 1200,
      completedFullSession: true,
      metrics: metrics,
      xpResult: XpCalculator.calculate(metrics: metrics),
      mistakes: const [
        SessionMistake(
          original: 'I go to school yesterday',
          correction: 'I went to school yesterday',
          type: 'grammar',
          explanation:
              'Dùng thì quá khứ đơn (Past Simple) vì hành động xảy ra "yesterday".',
        ),
        SessionMistake(
          original: 'She have a beautiful house',
          correction: 'She has a beautiful house',
          type: 'grammar',
          explanation:
              'Ngôi thứ 3 số ít (She/He/It) dùng "has" thay vì "have".',
        ),
      ],
      newVocabulary: const [
        VocabularyItem(
          word: 'pleasant',
          pronunciation: '/ˈplɛzənt/',
          partOfSpeech: 'adj',
          meaning: 'dễ chịu, thoải mái',
          example: 'The weather is quite pleasant today.',
          cefrLevel: 'A2',
        ),
        VocabularyItem(
          word: 'memorable',
          pronunciation: '/ˈmɛmərəbl/',
          partOfSpeech: 'adj',
          meaning: 'đáng nhớ',
          example: 'It was the most memorable vacation.',
          cefrLevel: 'B1',
        ),
        VocabularyItem(
          word: 'experience',
          pronunciation: '/ɪkˈspɪəriəns/',
          partOfSpeech: 'noun',
          meaning: 'trải nghiệm',
          example: 'Traveling abroad is a great experience.',
          cefrLevel: 'A2',
        ),
      ],
      confidenceScore: 0.72,
      confidenceChange: 0.05,
      aiSummary:
          'Bạn đã tham gia tích cực trong buổi học hôm nay! Tốc độ phản hồi tốt, nhưng cần chú ý thêm về chia động từ thì quá khứ.',
      completedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        roomId,
        topic,
        durationSeconds,
        completedFullSession,
        metrics,
        xpResult,
        mistakes,
        newVocabulary,
        confidenceScore,
        confidenceChange,
        aiSummary,
        completedAt,
      ];
}
