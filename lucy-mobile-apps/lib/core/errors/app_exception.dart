/// Custom exception classes cho ứng dụng LUCY.
///
/// Map 1:1 với mã lỗi HTTP đã thống nhất với Dev 3 & Dev 6:
/// - 400 → [BadRequestException]
/// - 401 → [UnauthorizedException]
/// - 500 → [ServerException]

/// Base exception class.
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? path;

  const AppException(this.message, {this.statusCode, this.path});

  @override
  String toString() => 'AppException($statusCode): $message';
}

/// 400 – Bad Request: Dữ liệu đầu vào không hợp lệ.
class BadRequestException extends AppException {
  const BadRequestException(String message, {String? path})
      : super(message, statusCode: 400, path: path);
}

/// 401 – Unauthorized: Chưa đăng nhập hoặc token hết hạn.
class UnauthorizedException extends AppException {
  const UnauthorizedException(String message, {String? path})
      : super(message, statusCode: 401, path: path);
}

/// 500 – Internal Server Error: Lỗi phía server.
class ServerException extends AppException {
  const ServerException(String message, {String? path})
      : super(message, statusCode: 500, path: path);
}

/// Không có kết nối mạng.
class NetworkException extends AppException {
  const NetworkException([String message = 'Không có kết nối mạng'])
      : super(message, statusCode: 0);
}
