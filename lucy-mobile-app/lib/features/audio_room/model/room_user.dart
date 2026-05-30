// lib/features/audio_room/model/room_user.dart
// ============================================================
// Project LUCY — Room Participant Model
// Represents a single user inside an audio room.
// ============================================================

import 'package:equatable/equatable.dart';

/// Immutable data model for a participant in an audio room.
///
/// Each user has an anonymous persona (emoji + display name)
/// assigned by the .NET auth service. The [personaIndex] maps
/// to a preset in [PersonaData.personas].
class RoomUser extends Equatable {
  /// Unique user identifier (from .NET auth service).
  final String userId;

  /// Anonymous display name, e.g. "Anonymous Fox".
  final String displayName;

  /// Index into the persona preset list (0–9).
  /// Determines which emoji avatar to display.
  final int personaIndex;

  /// Whether the user's microphone is muted.
  final bool isMuted;

  /// Whether the user is currently speaking (audio activity detected).
  final bool isSpeaking;

  /// Whether the user has raised their hand to speak.
  final bool isHandRaised;

  /// Agora RTC user ID for audio channel mapping.
  final int agoraUid;

  const RoomUser({
    required this.userId,
    required this.displayName,
    this.personaIndex = 0,
    this.isMuted = true,
    this.isSpeaking = false,
    this.isHandRaised = false,
    this.agoraUid = 0,
  });

  /// Creates a copy with the specified fields replaced.
  RoomUser copyWith({
    String? userId,
    String? displayName,
    int? personaIndex,
    bool? isMuted,
    bool? isSpeaking,
    bool? isHandRaised,
    int? agoraUid,
  }) {
    return RoomUser(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      personaIndex: personaIndex ?? this.personaIndex,
      isMuted: isMuted ?? this.isMuted,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      agoraUid: agoraUid ?? this.agoraUid,
    );
  }

  /// Constructs a [RoomUser] from a JSON map (Socket.io payload).
  factory RoomUser.fromJson(Map<String, dynamic> json) {
    return RoomUser(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Anonymous',
      personaIndex: json['personaIndex'] as int? ?? 0,
      isMuted: json['isMuted'] as bool? ?? true,
      isSpeaking: false, // Speaking state is local (from Agora)
      isHandRaised: json['isHandRaised'] as bool? ?? false,
      agoraUid: json['agoraUid'] as int? ?? 0,
    );
  }

  /// Serializes this user to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'personaIndex': personaIndex,
      'isMuted': isMuted,
      'isHandRaised': isHandRaised,
      'agoraUid': agoraUid,
    };
  }

  @override
  List<Object?> get props => [
        userId,
        displayName,
        personaIndex,
        isMuted,
        isSpeaking,
        isHandRaised,
        agoraUid,
      ];
}
