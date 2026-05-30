// lib/core/config/app_config.dart
// ============================================================
// Project LUCY — Centralized App Configuration
// All environment-specific values live here.
// NEVER hard-code API keys, URLs, or secrets in widgets.
// ============================================================

/// Centralized configuration for external services.
///
/// In production, these values should be loaded from environment
/// variables or a secure config file (.env). For MVP development,
/// they are defined as compile-time constants.
class AppConfig {
  AppConfig._(); // Prevent instantiation

  // ──────────────────────────────────────────────────────────
  // AGORA RTC
  // ──────────────────────────────────────────────────────────

  /// Agora App ID from https://console.agora.io
  /// IMPORTANT: Replace with your actual App ID before testing.
  /// Leave empty string to trigger graceful error in AgoraService.
  static const String agoraAppId = '';

  /// Default Agora UID (0 = server auto-assigns).
  static const int agoraDefaultUid = 0;

  /// Audio volume indication interval in milliseconds.
  /// Lower = more responsive speaking detection, higher CPU.
  static const int agoraVolumeInterval = 200;

  /// Volume threshold to consider a user "speaking".
  /// Range: 0–255. Typical speech starts at ~50.
  static const int agoraSpeakingThreshold = 50;

  // ──────────────────────────────────────────────────────────
  // SOCKET.IO (Node.js Realtime Server)
  // ──────────────────────────────────────────────────────────

  /// Socket.io server URL for the realtime service.
  static const String socketServerUrl = 'http://localhost:3001';

  // ──────────────────────────────────────────────────────────
  // REST API (Spring Boot / .NET Gateway)
  // ──────────────────────────────────────────────────────────

  /// Base URL for the API Gateway.
  static const String apiBaseUrl = 'http://localhost:8080';
}
