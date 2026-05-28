/// Hằng số API cho ứng dụng LUCY.
///
/// Tập trung tất cả URL và endpoint tại đây để dễ quản lý
/// khi chuyển đổi giữa môi trường dev / staging / production.
class ApiConstants {
  ApiConstants._(); // Prevent instantiation

  // ── Base URL ──
  static const String baseUrl = 'http://10.0.2.2:8080'; // Android emulator → localhost
  static const String prodUrl = 'https://api.lucy-app.com';

  // ── WebSocket ──
  static const String socketUrl = 'http://10.0.2.2:3000'; // Realtime service
  static const String socketProdUrl = 'wss://realtime.lucy-app.com';

  // ── Auth Endpoints ──
  static const String login = '/api/auth/login';

  // ── LMS Endpoints ──
  static const String levels = '/api/levels';

  // ── Import Endpoints ──
  static const String importDocx = '/api/import/docx';

  // ── Timeout (milliseconds) ──
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}
