// lib/features/pro_dashboard/model/pinned_resource.dart
// ============================================================
// Project LUCY — Pinned Resource Model
// Documents/images pinned to the room by a moderator.
//
// Source: Dev 3 REST API — POST /api/rooms/{id}/pin-resource
// ============================================================

import 'package:equatable/equatable.dart';

/// A resource (URL or image) pinned to an audio room.
///
/// Moderators can pin links or images for all participants to see.
/// Displayed as horizontal-scrolling thumbnails in Zone 3.
class PinnedResource extends Equatable {
  /// Server-assigned resource ID.
  final String id;

  /// URL of the resource (web link or image URL).
  final String resourceUrl;

  /// Type of resource: `"image"` or `"url"`.
  final String type;

  /// When this resource was pinned.
  final DateTime timestamp;

  const PinnedResource({
    required this.id,
    required this.resourceUrl,
    required this.type,
    required this.timestamp,
  });

  /// Whether this is an image resource.
  bool get isImage => type == 'image';

  /// Creates from API response JSON.
  factory PinnedResource.fromJson(Map<String, dynamic> json) {
    return PinnedResource(
      id: json['id'] as String? ?? '',
      resourceUrl: json['resourceUrl'] as String? ?? '',
      type: json['type'] as String? ?? 'url',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Converts to JSON for API request.
  Map<String, dynamic> toJson() => {
        'id': id,
        'resourceUrl': resourceUrl,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, resourceUrl, type, timestamp];
}
