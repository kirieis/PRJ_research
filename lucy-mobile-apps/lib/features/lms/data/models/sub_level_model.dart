/// Model sub-level – map từ bảng `sub_levels` trong LucyDB.
class SubLevelModel {
  final int id;
  final int levelId;
  final int orderIndex;
  final String? title;
  final String? phonetic;
  final int? durationMinutes;
  final String contentType; // VOCABULARY | GRAMMAR | LISTENING | SPEAKING

  const SubLevelModel({
    required this.id,
    required this.levelId,
    required this.orderIndex,
    this.title,
    this.phonetic,
    this.durationMinutes,
    required this.contentType,
  });

  /// Parse từ JSON response.
  factory SubLevelModel.fromJson(Map<String, dynamic> json) {
    return SubLevelModel(
      id: json['id'] as int,
      levelId: json['levelId'] as int,
      orderIndex: json['orderIndex'] as int,
      title: json['title'] as String?,
      phonetic: json['phonetic'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
      contentType: json['contentType'] as String,
    );
  }

  /// Chuyển sang JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'levelId': levelId,
      'orderIndex': orderIndex,
      'title': title,
      'phonetic': phonetic,
      'durationMinutes': durationMinutes,
      'contentType': contentType,
    };
  }

  /// Icon tương ứng với content type.
  String get contentTypeEmoji {
    switch (contentType) {
      case 'VOCABULARY':
        return '📝';
      case 'GRAMMAR':
        return '📖';
      case 'LISTENING':
        return '🎧';
      case 'SPEAKING':
        return '🎤';
      default:
        return '📄';
    }
  }
}
