/// Model phòng học – map từ bảng `rooms` trong LucyDB.
class RoomModel {
  final int id;
  final int hostId;
  final int levelId;
  final int? currentSubLevelId;
  final String status; // WAITING | ACTIVE | ENDED
  final String? agoraChannelName;
  final int maxParticipants;
  final DateTime? createdAt;
  final DateTime? endedAt;

  const RoomModel({
    required this.id,
    required this.hostId,
    required this.levelId,
    this.currentSubLevelId,
    required this.status,
    this.agoraChannelName,
    this.maxParticipants = 50,
    this.createdAt,
    this.endedAt,
  });

  /// Parse từ JSON response.
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as int,
      hostId: json['hostId'] as int,
      levelId: json['levelId'] as int,
      currentSubLevelId: json['currentSubLevelId'] as int?,
      status: json['status'] as String,
      agoraChannelName: json['agoraChannelName'] as String?,
      maxParticipants: json['maxParticipants'] as int? ?? 50,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
    );
  }

  /// Chuyển sang JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'levelId': levelId,
      'currentSubLevelId': currentSubLevelId,
      'status': status,
      'agoraChannelName': agoraChannelName,
      'maxParticipants': maxParticipants,
      'createdAt': createdAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }

  /// Kiểm tra phòng đang hoạt động.
  bool get isActive => status == 'ACTIVE';

  /// Kiểm tra phòng đã kết thúc.
  bool get isEnded => status == 'ENDED';
}
