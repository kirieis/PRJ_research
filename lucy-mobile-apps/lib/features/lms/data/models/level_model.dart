/// Model level – map từ bảng `levels` trong LucyDB.
///
/// Bao gồm danh sách [SubLevelModel] lồng nhau.
import 'sub_level_model.dart';

class LevelModel {
  final int id;
  final int languageId;
  final int stageNumber;
  final int levelNumber;
  final String? topicName;
  final String? targetOutcome;
  final bool isPublished;
  final List<SubLevelModel> subLevels;

  const LevelModel({
    required this.id,
    required this.languageId,
    required this.stageNumber,
    required this.levelNumber,
    this.topicName,
    this.targetOutcome,
    this.isPublished = false,
    this.subLevels = const [],
  });

  /// Parse từ JSON response.
  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: json['id'] as int,
      languageId: json['languageId'] as int,
      stageNumber: json['stageNumber'] as int,
      levelNumber: json['levelNumber'] as int,
      topicName: json['topicName'] as String?,
      targetOutcome: json['targetOutcome'] as String?,
      isPublished: json['isPublished'] as bool? ?? false,
      subLevels: (json['subLevels'] as List<dynamic>?)
              ?.map((e) => SubLevelModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Chuyển sang JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'languageId': languageId,
      'stageNumber': stageNumber,
      'levelNumber': levelNumber,
      'topicName': topicName,
      'targetOutcome': targetOutcome,
      'isPublished': isPublished,
      'subLevels': subLevels.map((e) => e.toJson()).toList(),
    };
  }

  /// Tên hiển thị: "Stage X – Level Y"
  String get displayTitle =>
      'Stage $stageNumber – Level $levelNumber${topicName != null ? ': $topicName' : ''}';
}
