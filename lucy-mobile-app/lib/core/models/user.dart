// lib/core/models/user.dart
// ============================================================
// Project LUCY — User Data Model
//
// Represents a LUCY platform user with profile, level progress,
// and session statistics.
// ============================================================

import 'package:equatable/equatable.dart';

/// User profile and progress data.
///
/// Used across features:
/// - Auth: login/register flow
/// - Room: display name, avatar, level badge
/// - Level: XP tracking, progression
/// - Social: profile cards, leaderboard
class User extends Equatable {
  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final String? avatarPreset; // e.g. "space_ranger", "anime_hero"
  final int level;
  final int currentXp;
  final int requiredXp;
  final String preferredLanguage; // 'en', 'ja', 'zh'
  final String cefrLevel; // 'A1', 'A2', 'B1', 'B2', 'C1'
  final int totalSessions;
  final int totalSpeakingMinutes;
  final double averageConfidenceScore;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.avatarPreset,
    this.level = 1,
    this.currentXp = 0,
    this.requiredXp = 300,
    this.preferredLanguage = 'en',
    this.cefrLevel = 'A1',
    this.totalSessions = 0,
    this.totalSpeakingMinutes = 0,
    this.averageConfidenceScore = 0.0,
    this.createdAt,
  });

  /// Progress ratio for level progress bar (0.0 → 1.0).
  double get levelProgress =>
      requiredXp > 0 ? (currentXp / requiredXp).clamp(0.0, 1.0) : 0.0;

  /// Whether the user has enough XP to level up.
  bool get canLevelUp => currentXp >= requiredXp;

  /// Short display for level badge (e.g. "Lv.3 B1").
  String get levelBadge => 'Lv.$level $cefrLevel';

  User copyWith({
    String? id,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? avatarPreset,
    int? level,
    int? currentXp,
    int? requiredXp,
    String? preferredLanguage,
    String? cefrLevel,
    int? totalSessions,
    int? totalSpeakingMinutes,
    double? averageConfidenceScore,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarPreset: avatarPreset ?? this.avatarPreset,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      requiredXp: requiredXp ?? this.requiredXp,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      totalSessions: totalSessions ?? this.totalSessions,
      totalSpeakingMinutes: totalSpeakingMinutes ?? this.totalSpeakingMinutes,
      averageConfidenceScore:
          averageConfidenceScore ?? this.averageConfidenceScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      avatarPreset: json['avatarPreset'] as String?,
      level: json['level'] as int? ?? 1,
      currentXp: json['currentXp'] as int? ?? 0,
      requiredXp: json['requiredXp'] as int? ?? 300,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
      cefrLevel: json['cefrLevel'] as String? ?? 'A1',
      totalSessions: json['totalSessions'] as int? ?? 0,
      totalSpeakingMinutes: json['totalSpeakingMinutes'] as int? ?? 0,
      averageConfidenceScore:
          (json['averageConfidenceScore'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'avatarPreset': avatarPreset,
      'level': level,
      'currentXp': currentXp,
      'requiredXp': requiredXp,
      'preferredLanguage': preferredLanguage,
      'cefrLevel': cefrLevel,
      'totalSessions': totalSessions,
      'totalSpeakingMinutes': totalSpeakingMinutes,
      'averageConfidenceScore': averageConfidenceScore,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        email,
        avatarUrl,
        avatarPreset,
        level,
        currentXp,
        requiredXp,
        preferredLanguage,
        cefrLevel,
        totalSessions,
        totalSpeakingMinutes,
        averageConfidenceScore,
        createdAt,
      ];
}
