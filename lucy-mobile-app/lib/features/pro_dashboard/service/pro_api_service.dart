// lib/features/pro_dashboard/service/pro_api_service.dart
// ============================================================
// Project LUCY — Pro Dashboard API Service
// REST API calls for moderator features (hints, pin resources).
//
// Endpoints provided by Dev 3 (Spring Boot):
// - GET  /api/rooms/{id}/moderator-hints
// - POST /api/rooms/{id}/pin-resource
// ============================================================

import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../model/pinned_resource.dart';

/// Service for Pro Dashboard REST API interactions.
///
/// Uses [Dio] for HTTP requests. All endpoints target the
/// Spring Boot content service (Dev 3) via [AppConfig.apiBaseUrl].
class ProApiService {
  late final Dio _dio;

  ProApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }

  /// Allows injecting a custom Dio instance for testing.
  ProApiService.withDio(this._dio);

  // ── Moderator Hints ────────────────────────────────────────

  /// Fetches AI-generated question hints for the moderator.
  ///
  /// Endpoint: `GET /api/rooms/{roomId}/moderator-hints`
  /// Source: Dev 3 (Spring Boot)
  ///
  /// Returns list of hint objects with `triggerMinute` and `question`.
  Future<List<Map<String, dynamic>>> getModeratorHints(String roomId) async {
    try {
      developer.log(
        '📥 GET /api/rooms/$roomId/moderator-hints',
        name: 'ProApiService',
      );

      final response = await _dio.get('/api/rooms/$roomId/moderator-hints');

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }

      return [];
    } on DioException catch (e) {
      developer.log(
        '❌ getModeratorHints failed: ${e.message}',
        name: 'ProApiService',
        error: e,
      );
      return [];
    }
  }

  // ── Pin Resource ───────────────────────────────────────────

  /// Pins a resource (URL or image) to the room.
  ///
  /// Endpoint: `POST /api/rooms/{roomId}/pin-resource`
  /// Source: Dev 3 (Spring Boot)
  ///
  /// Body: `{resourceUrl: "...", type: "image"|"url"}`
  /// Returns the created [PinnedResource] or null on failure.
  Future<PinnedResource?> pinResource({
    required String roomId,
    required String resourceUrl,
    required String type,
  }) async {
    try {
      developer.log(
        '📤 POST /api/rooms/$roomId/pin-resource — $type: $resourceUrl',
        name: 'ProApiService',
      );

      final response = await _dio.post(
        '/api/rooms/$roomId/pin-resource',
        data: {
          'resourceUrl': resourceUrl,
          'type': type,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return PinnedResource.fromJson(response.data);
        }
        // If server returns just OK, create a local resource.
        return PinnedResource(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          resourceUrl: resourceUrl,
          type: type,
          timestamp: DateTime.now(),
        );
      }

      return null;
    } on DioException catch (e) {
      developer.log(
        '❌ pinResource failed: ${e.message}',
        name: 'ProApiService',
        error: e,
      );
      return null;
    }
  }
}
