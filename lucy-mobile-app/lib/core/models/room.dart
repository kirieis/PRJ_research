// lib/core/models/room.dart
// ============================================================
// Project LUCY — Room Data Model
//
// Represents a learning room with stage progression,
// participant tracking, and session metadata.
// ============================================================

import 'package:equatable/equatable.dart';

/// The 3-stage structure of a LUCY learning session.
enum RoomStage {
  /// Warm-up: Icebreaker questions, self-introduction (5 min).
  warmup,

  /// Topic Discussion: Structured conversation on level topic (10 min).
  topicDiscussion,

  /// Free Talk: Open conversation, minimal AI intervention (5 min).
  freeTalk,
}

/// Room status in the lobby.
enum RoomStatus {
  /// Currently active with participants.
  live,

  /// Scheduled for a future time.
  scheduled,

  /// Session has ended.
  ended,

  /// Waiting for minimum participants to start.
  waiting,
}

/// Participant role within a room.
enum ParticipantRole {
  /// Room host/teacher with moderation powers.
  moderator,

  /// Pro user (verified, has badges).
  pro,

  /// Anonymous learner (default).
  anonymous,
}

/// A participant in an audio room.
class RoomParticipant extends Equatable {
  final String userId;
  final String displayName;
  final ParticipantRole role;
  final bool isMuted;
  final bool isSpeaking;
  final bool handRaised;
  final String? avatarUrl;
  final bool isAvatarHidden;
  final String voiceFilter;

  const RoomParticipant({
    required this.userId,
    required this.displayName,
    this.role = ParticipantRole.anonymous,
    this.isMuted = true,
    this.isSpeaking = false,
    this.handRaised = false,
    this.avatarUrl,
    this.isAvatarHidden = false,
    this.voiceFilter = 'normal',
  });

  RoomParticipant copyWith({
    String? userId,
    String? displayName,
    ParticipantRole? role,
    bool? isMuted,
    bool? isSpeaking,
    bool? handRaised,
    String? avatarUrl,
    bool? isAvatarHidden,
    String? voiceFilter,
  }) {
    return RoomParticipant(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isMuted: isMuted ?? this.isMuted,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      handRaised: handRaised ?? this.handRaised,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAvatarHidden: isAvatarHidden ?? this.isAvatarHidden,
      voiceFilter: voiceFilter ?? this.voiceFilter,
    );
  }

  factory RoomParticipant.fromJson(Map<String, dynamic> json) {
    return RoomParticipant(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      role: ParticipantRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => ParticipantRole.anonymous,
      ),
      isMuted: json['isMuted'] as bool? ?? true,
      isSpeaking: json['isSpeaking'] as bool? ?? false,
      handRaised: json['handRaised'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String?,
      isAvatarHidden: json['isAvatarHidden'] as bool? ?? false,
      voiceFilter: json['voiceFilter'] as String? ?? 'normal',
    );
  }

  @override
  List<Object?> get props => [
        userId,
        displayName,
        role,
        isMuted,
        isSpeaking,
        handRaised,
        avatarUrl,
        isAvatarHidden,
        voiceFilter,
      ];
}

/// A learning room with session data.
class Room extends Equatable {
  final String id;
  final String name;
  final String language; // 'en', 'ja', 'zh'
  final String level; // 'A1', 'A2', 'B1', 'B2', 'C1' or 'N5', 'HSK 4'
  final String description;
  final RoomStatus status;
  final RoomStage currentStage;
  final int maxParticipants;
  final List<RoomParticipant> participants;
  final String? topic;
  final List<String> aiPrompts;
  final int stageDurationSeconds;
  final DateTime? scheduledAt;
  final DateTime? startedAt;

  const Room({
    required this.id,
    required this.name,
    this.language = 'en',
    this.level = 'A1',
    this.description = '',
    this.status = RoomStatus.waiting,
    this.currentStage = RoomStage.warmup,
    this.maxParticipants = 8,
    this.participants = const [],
    this.topic,
    this.aiPrompts = const [],
    this.stageDurationSeconds = 300, // 5 min default
    this.scheduledAt,
    this.startedAt,
  });

  /// Current participant count.
  int get participantCount => participants.length;

  /// Whether the room is full.
  bool get isFull => participants.length >= maxParticipants;

  /// Whether the room is currently active.
  bool get isLive => status == RoomStatus.live;

  /// Stage duration formatted as "MM:SS".
  String get stageDurationFormatted {
    final min = stageDurationSeconds ~/ 60;
    final sec = stageDurationSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  /// Stage name for display.
  String get stageDisplayName {
    switch (currentStage) {
      case RoomStage.warmup:
        return 'Warm-up';
      case RoomStage.topicDiscussion:
        return 'Topic Discussion';
      case RoomStage.freeTalk:
        return 'Free Talk';
    }
  }

  Room copyWith({
    String? id,
    String? name,
    String? language,
    String? level,
    String? description,
    RoomStatus? status,
    RoomStage? currentStage,
    int? maxParticipants,
    List<RoomParticipant>? participants,
    String? topic,
    List<String>? aiPrompts,
    int? stageDurationSeconds,
    DateTime? scheduledAt,
    DateTime? startedAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      language: language ?? this.language,
      level: level ?? this.level,
      description: description ?? this.description,
      status: status ?? this.status,
      currentStage: currentStage ?? this.currentStage,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participants: participants ?? this.participants,
      topic: topic ?? this.topic,
      aiPrompts: aiPrompts ?? this.aiPrompts,
      stageDurationSeconds: stageDurationSeconds ?? this.stageDurationSeconds,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      language: json['language'] as String? ?? 'en',
      level: json['level'] as String? ?? 'A1',
      description: json['description'] as String? ?? '',
      status: RoomStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RoomStatus.waiting,
      ),
      currentStage: RoomStage.values.firstWhere(
        (e) => e.name == json['currentStage'],
        orElse: () => RoomStage.warmup,
      ),
      maxParticipants: json['maxParticipants'] as int? ?? 8,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) =>
                  RoomParticipant.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      topic: json['topic'] as String?,
      aiPrompts: (json['aiPrompts'] as List<dynamic>?)
              ?.map((p) => p as String)
              .toList() ??
          [],
      stageDurationSeconds: json['stageDurationSeconds'] as int? ?? 300,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'] as String)
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        language,
        level,
        description,
        status,
        currentStage,
        maxParticipants,
        participants,
        topic,
        aiPrompts,
        stageDurationSeconds,
        scheduledAt,
        startedAt,
      ];
}
