import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

/// Dio HTTP client singleton cho toàn bộ ứng dụng.
///
/// Đã cấu hình sẵn:
/// - Base URL
/// - Timeout
/// - JWT interceptor (tự động gắn token vào header)
/// - Error interceptor (log lỗi)
class DioClient {
  static DioClient? _instance;
  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'jwt_access_token';

  DioClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ── JWT Interceptor ──
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Tự động gắn token nếu có (trừ login endpoint)
          if (!options.path.contains('/auth/login')) {
            final token = await _storage.read(key: _tokenKey);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Log lỗi để debug
          // ignore: avoid_print
          print('[DioClient] Error: ${error.response?.statusCode} – ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  /// Lấy singleton instance.
  static DioClient get instance {
    _instance ??= DioClient._();
    return _instance!;
  }

  /// Lưu JWT token sau khi đăng nhập thành công.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Xóa JWT token khi đăng xuất.
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Kiểm tra đã có token chưa.
  Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }
}
