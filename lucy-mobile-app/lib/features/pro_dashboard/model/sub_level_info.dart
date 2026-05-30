// lib/features/pro_dashboard/model/sub_level_info.dart
// ============================================================
// Project LUCY — Sub-level Info Model
// Represents the current sub-level within an audio room session.
//
// Source: Dev 4 Socket event 'room-state-updated' and 'next-sublevel'
// ============================================================

import 'package:equatable/equatable.dart';

/// Data about the current sub-level in the room session.
///
/// Sub-levels represent progressive stages within a lesson level.
/// The server (Dev 4) auto-advances every 10/20 minutes or
/// a moderator can force-advance via `force-next-sublevel`.
class SubLevelInfo extends Equatable {
  /// Sub-level identifier from the content service.
  final String subLevelId;

  /// Display title (e.g., "Greeting Strangers", "Ordering Food").
  final String title;

  /// Current position (0-indexed).
  final int index;

  /// Total number of sub-levels in this level.
  final int totalCount;

  const SubLevelInfo({
    required this.subLevelId,
    required this.title,
    this.index = 0,
    this.totalCount = 1,
  });

  /// Human-readable label, e.g. "Sub-level 2/6: Greeting Strangers"
  String get displayLabel => 'Sub-level ${index + 1}/$totalCount: $title';

  /// Whether this is the last sub-level.
  bool get isLast => index >= totalCount - 1;

  /// Creates from JSON payload of `room-state-updated` or `next-sublevel`.
  factory SubLevelInfo.fromJson(Map<String, dynamic> json) {
    return SubLevelInfo(
      subLevelId: json['subLevelId'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown',
      index: json['index'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [subLevelId, title, index, totalCount];
}
