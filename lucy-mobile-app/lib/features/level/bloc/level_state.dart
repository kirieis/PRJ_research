// lib/features/level/bloc/level_state.dart
// ============================================================
// Project LUCY — Level BLoC State
// ============================================================

import 'package:equatable/equatable.dart';

import '../../../core/models/level.dart';

/// Status of level data loading.
enum LevelStatus {
  /// Initial state, not yet loaded.
  initial,

  /// Loading level data from server.
  loading,

  /// Level data loaded successfully.
  loaded,

  /// Level up triggered — show animation.
  levelingUp,

  /// Error loading level data.
  error,
}

/// State for the Level BLoC.
class LevelState extends Equatable {
  /// Current loading status.
  final LevelStatus status;

  /// Current user level (1-5).
  final int currentLevel;

  /// Current XP within this level.
  final int currentXp;

  /// XP required to reach next level.
  final int requiredXp;

  /// CEFR level string (e.g. "A1", "B2").
  final String cefrLevel;

  /// Level title (e.g. "Daily Greetings").
  final String levelTitle;

  /// Number of sessions completed at this level.
  final int sessionsCompleted;

  /// Required sessions for this level.
  final int sessionsRequired;

  /// Average confidence score across sessions.
  final double averageConfidence;

  /// Minimum confidence required to level up.
  final double requiredConfidence;

  /// Last XP result (for animation).
  final XpResult? lastXpResult;

  /// New level after level-up (for animation).
  final int? newLevel;

  /// Error message.
  final String? errorMessage;

  const LevelState({
    this.status = LevelStatus.initial,
    this.currentLevel = 1,
    this.currentXp = 0,
    this.requiredXp = 300,
    this.cefrLevel = 'A1',
    this.levelTitle = 'Daily Greetings',
    this.sessionsCompleted = 0,
    this.sessionsRequired = 3,
    this.averageConfidence = 0.0,
    this.requiredConfidence = 0.40,
    this.lastXpResult,
    this.newLevel,
    this.errorMessage,
  });

  /// Progress ratio for level bar (0.0 → 1.0).
  double get progress =>
      requiredXp > 0 ? (currentXp / requiredXp).clamp(0.0, 1.0) : 0.0;

  /// Whether user meets both XP and confidence requirements.
  bool get meetsLevelUpCriteria =>
      currentXp >= requiredXp && averageConfidence >= requiredConfidence;

  /// Short badge text (e.g. "Lv.3 B1").
  String get levelBadge => 'Lv.$currentLevel $cefrLevel';

  /// XP remaining text (e.g. "150 / 300 XP").
  String get xpDisplayText => '$currentXp / $requiredXp XP';

  LevelState copyWith({
    LevelStatus? status,
    int? currentLevel,
    int? currentXp,
    int? requiredXp,
    String? cefrLevel,
    String? levelTitle,
    int? sessionsCompleted,
    int? sessionsRequired,
    double? averageConfidence,
    double? requiredConfidence,
    XpResult? lastXpResult,
    int? newLevel,
    String? errorMessage,
  }) {
    return LevelState(
      status: status ?? this.status,
      currentLevel: currentLevel ?? this.currentLevel,
      currentXp: currentXp ?? this.currentXp,
      requiredXp: requiredXp ?? this.requiredXp,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      levelTitle: levelTitle ?? this.levelTitle,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      sessionsRequired: sessionsRequired ?? this.sessionsRequired,
      averageConfidence: averageConfidence ?? this.averageConfidence,
      requiredConfidence: requiredConfidence ?? this.requiredConfidence,
      lastXpResult: lastXpResult ?? this.lastXpResult,
      newLevel: newLevel ?? this.newLevel,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentLevel,
        currentXp,
        requiredXp,
        cefrLevel,
        levelTitle,
        sessionsCompleted,
        sessionsRequired,
        averageConfidence,
        requiredConfidence,
        lastXpResult,
        newLevel,
        errorMessage,
      ];
}
