// lib/core/constants/app_constants.dart
// ============================================================
// Project LUCY — Application-wide Constants
// ============================================================

/// Centralized constants for API configuration and app settings.
class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────────
  /// Base URL for the API Gateway (matches Swagger server config).
  static const String apiBaseUrl = 'http://localhost:8080';

  /// Request timeout in milliseconds.
  static const int connectTimeout = 10000;

  /// Response timeout in milliseconds.
  static const int receiveTimeout = 15000;

  // ── Auth ───────────────────────────────────────────────────
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // ── WebSocket ──────────────────────────────────────────────
  static const String socketUrl = 'http://localhost:3001';

  // ── UI ─────────────────────────────────────────────────────
  static const Duration splashDelay = Duration(seconds: 2);
}
