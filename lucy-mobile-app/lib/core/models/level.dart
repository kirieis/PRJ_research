// lib/core/models/level.dart
// ============================================================
// Project LUCY — Level & XP System Data Models
//
// Defines the leveling system:
//   - LevelConfig: per-level requirements and metadata
//   - XpCalculator: session XP formula with anti-AFK
//   - EngagementMetrics: per-session engagement data
//
// XP Formula:
//   session_xp = base_xp × engagement_multiplier × duration_ratio
// ============================================================

import 'package:equatable/equatable.dart';

/// CEFR-aligned level configuration.
///
/// Each level has specific requirements for progression:
/// - Minimum sessions to complete
/// - Session duration
/// - Required total XP
/// - Minimum AI confidence score
class LevelConfig extends Equatable {
  final int level;
  final String cefrLevel;
  final String title;
  final int requiredSessions;
  final int sessionDurationMinutes;
  final int requiredXp;
  final double minConfidenceScore;

  const LevelConfig({
    required this.level,
    required this.cefrLevel,
    required this.title,
    required this.requiredSessions,
    required this.sessionDurationMinutes,
    required this.requiredXp,
    required this.minConfidenceScore,
  });

  @override
  List<Object?> get props => [
        level,
        cefrLevel,
        title,
        requiredSessions,
        sessionDurationMinutes,
        requiredXp,
        minConfidenceScore,
      ];

  /// All LUCY levels — single source of truth.
  static const List<LevelConfig> allLevels = [
    LevelConfig(
      level: 1,
      cefrLevel: 'A1',
      title: 'Daily Greetings',
      requiredSessions: 3,
      sessionDurationMinutes: 20,
      requiredXp: 300,
      minConfidenceScore: 0.40,
    ),
    LevelConfig(
      level: 2,
      cefrLevel: 'A2',
      title: 'Simple Conversations',
      requiredSessions: 4,
      sessionDurationMinutes: 20,
      requiredXp: 500,
      minConfidenceScore: 0.50,
    ),
    LevelConfig(
      level: 3,
      cefrLevel: 'B1',
      title: 'Opinion & Discussion',
      requiredSessions: 5,
      sessionDurationMinutes: 25,
      requiredXp: 800,
      minConfidenceScore: 0.55,
    ),
    LevelConfig(
      level: 4,
      cefrLevel: 'B2',
      title: 'Debate & Argumentation',
      requiredSessions: 6,
      sessionDurationMinutes: 25,
      requiredXp: 1200,
      minConfidenceScore: 0.60,
    ),
    LevelConfig(
      level: 5,
      cefrLevel: 'C1',
      title: 'Professional Discourse',
      requiredSessions: 8,
      sessionDurationMinutes: 30,
      requiredXp: 2000,
      minConfidenceScore: 0.70,
    ),
  ];

  /// Get config for a specific level.
  static LevelConfig forLevel(int level) {
    return allLevels.firstWhere(
      (config) => config.level == level,
      orElse: () => allLevels.last,
    );
  }
}

/// Raw engagement metrics collected during a session.
///
/// These metrics are calculated server-side using audio analysis
/// and Socket.IO events, then sent to the client at session end.
class EngagementMetrics extends Equatable {
  /// Ratio of time the user was speaking (0.0 → 1.0).
  final double speakingRatio;

  /// Average response time in seconds after being prompted.
  /// Lower is better. Capped at 10s.
  final double averageResponseTime;

  /// Number of suggested vocabulary words the user actually used.
  final int vocabularyUsed;

  /// Total suggested vocabulary during the session.
  final int vocabularySuggested;

  /// Number of question-answer interactions with peers.
  final int peerInteractions;

  /// Total time the user was unmuted (seconds).
  final int unmutedDurationSeconds;

  /// Total session duration (seconds).
  final int totalDurationSeconds;

  /// AI-evaluated confidence score for this session (0.0 → 1.0).
  final double confidenceScore;

  const EngagementMetrics({
    this.speakingRatio = 0.0,
    this.averageResponseTime = 10.0,
    this.vocabularyUsed = 0,
    this.vocabularySuggested = 0,
    this.peerInteractions = 0,
    this.unmutedDurationSeconds = 0,
    this.totalDurationSeconds = 1200,
    this.confidenceScore = 0.0,
  });

  /// Vocabulary usage ratio (0.0 → 1.0).
  double get vocabularyRatio => vocabularySuggested > 0
      ? (vocabularyUsed / vocabularySuggested).clamp(0.0, 1.0)
      : 0.0;

  /// Duration ratio: actual unmuted time / total time (0.0 → 1.0).
  double get durationRatio => totalDurationSeconds > 0
      ? (unmutedDurationSeconds / totalDurationSeconds).clamp(0.0, 1.0)
      : 0.0;

  /// Response speed score (0.0 → 1.0).
  /// 0s = 1.0, 3s = 0.7, 10s = 0.0.
  double get responseSpeedScore =>
      (1.0 - (averageResponseTime / 10.0)).clamp(0.0, 1.0);

  /// Peer interaction score (0.0 → 1.0).
  /// Normalized: 0 = 0.0, 5+ = 1.0.
  double get peerInteractionScore =>
      (peerInteractions / 5.0).clamp(0.0, 1.0);

  factory EngagementMetrics.fromJson(Map<String, dynamic> json) {
    return EngagementMetrics(
      speakingRatio: (json['speakingRatio'] as num?)?.toDouble() ?? 0.0,
      averageResponseTime:
          (json['averageResponseTime'] as num?)?.toDouble() ?? 10.0,
      vocabularyUsed: json['vocabularyUsed'] as int? ?? 0,
      vocabularySuggested: json['vocabularySuggested'] as int? ?? 0,
      peerInteractions: json['peerInteractions'] as int? ?? 0,
      unmutedDurationSeconds: json['unmutedDurationSeconds'] as int? ?? 0,
      totalDurationSeconds: json['totalDurationSeconds'] as int? ?? 1200,
      confidenceScore:
          (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        speakingRatio,
        averageResponseTime,
        vocabularyUsed,
        vocabularySuggested,
        peerInteractions,
        unmutedDurationSeconds,
        totalDurationSeconds,
        confidenceScore,
      ];
}

/// XP calculation engine.
///
/// Implements the formula:
///   session_xp = base_xp × engagement_multiplier × duration_ratio
///
/// Engagement multiplier is a weighted sum:
///   speaking_ratio    × 0.40
///   response_speed    × 0.20
///   vocabulary_usage  × 0.20
///   peer_interaction  × 0.20
class XpCalculator {
  XpCalculator._();

  /// Base XP awarded per completed session.
  static const int baseXp = 100;

  /// Weights for engagement multiplier components.
  static const double wSpeaking = 0.40;
  static const double wResponseSpeed = 0.20;
  static const double wVocabulary = 0.20;
  static const double wPeerInteraction = 0.20;

  /// Penalty multiplier for early leave (before stage 3).
  static const double earlyLeavePenalty = 0.30;

  /// Calculate XP for a completed session.
  ///
  /// Returns [XpResult] with breakdown of earned XP.
  static XpResult calculate({
    required EngagementMetrics metrics,
    bool completedFullSession = true,
  }) {
    // Engagement multiplier (0.0 → 1.0)
    final engagementMultiplier = (metrics.speakingRatio * wSpeaking) +
        (metrics.responseSpeedScore * wResponseSpeed) +
        (metrics.vocabularyRatio * wVocabulary) +
        (metrics.peerInteractionScore * wPeerInteraction);

    // Duration ratio (penalizes AFK / muted users)
    final durationRatio = metrics.durationRatio;

    // Base calculation
    var xp = (baseXp * engagementMultiplier * durationRatio).round();

    // Early leave penalty
    if (!completedFullSession) {
      xp = (xp * earlyLeavePenalty).round();
    }

    // Minimum 1 XP if they spoke at all
    if (metrics.speakingRatio > 0 && xp < 1) {
      xp = 1;
    }

    return XpResult(
      totalXp: xp,
      baseXp: baseXp,
      engagementMultiplier: engagementMultiplier,
      durationRatio: durationRatio,
      completedFullSession: completedFullSession,
      confidenceScore: metrics.confidenceScore,
    );
  }
}

/// Result of XP calculation with breakdown.
class XpResult extends Equatable {
  final int totalXp;
  final int baseXp;
  final double engagementMultiplier;
  final double durationRatio;
  final bool completedFullSession;
  final double confidenceScore;

  const XpResult({
    required this.totalXp,
    required this.baseXp,
    required this.engagementMultiplier,
    required this.durationRatio,
    required this.completedFullSession,
    required this.confidenceScore,
  });

  /// Engagement percentage for display (e.g. "78%").
  String get engagementPercentage =>
      '${(engagementMultiplier * 100).round()}%';

  @override
  List<Object?> get props => [
        totalXp,
        baseXp,
        engagementMultiplier,
        durationRatio,
        completedFullSession,
        confidenceScore,
      ];
}
