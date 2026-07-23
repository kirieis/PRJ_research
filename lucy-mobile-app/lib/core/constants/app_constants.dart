// lib/core/constants/app_constants.dart
// ============================================================
// Project LUCY — Application-wide Constants
// ============================================================

/// Centralized constants for API configuration and app settings.
class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────────
  /// Base URL for the API Gateway.
  ///
  /// **Network accessibility notes:**
  /// - Android Emulator: `10.0.2.2` maps to host machine's localhost.
  /// - iOS Simulator: `localhost` works, but `10.0.2.2` does NOT.
  /// - Real Device: Use LAN IP (e.g. `192.168.1.x`) or staging domain.
  /// - Production: Use actual domain (e.g. `https://api.lucy.vn`).
  static const String apiBaseUrl = 'http://10.0.2.2:8080';

  /// Base URL for the Auth Service (.NET).
  /// Auth service runs on port 5086 (separate from API Gateway on 8080).
  static const String authBaseUrl = 'http://10.0.2.2:5086';

  /// Request timeout in milliseconds.
  static const int connectTimeout = 10000;

  /// Response timeout in milliseconds.
  static const int receiveTimeout = 15000;

  // ── Auth ───────────────────────────────────────────────────
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // ── WebSocket ──────────────────────────────────────────────
  /// Socket.IO server URL — same accessibility rules as [apiBaseUrl].
  static const String socketUrl = 'http://10.0.2.2:3001';

  // ── UI ─────────────────────────────────────────────────────
  static const Duration splashDelay = Duration(seconds: 2);
}
