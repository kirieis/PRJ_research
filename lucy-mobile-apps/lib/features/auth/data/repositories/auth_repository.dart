import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/login_request.dart';
import '../models/user_model.dart';

/// Repository xử lý tất cả API calls liên quan đến Auth.
///
/// Phụ trách: Dev 6 (Trương Bảo Tuấn) – Backend
///            Dev 1 (Nguyễn Trí Thiện) – Mobile integration
class AuthRepository {
  final Dio _dio = DioClient.instance.dio;

  /// Đăng nhập – POST /api/auth/login
  ///
  /// Trả về [UserModel] nếu thành công.
  /// Throw exception tương ứng nếu thất bại (400, 401, 500).
  Future<UserModel> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      // Lưu JWT token
      final accessToken = response.data['accessToken'] as String;
      await DioClient.instance.saveToken(accessToken);

      // Parse user info
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message =
          e.response?.data?['message'] as String? ?? 'Đã xảy ra lỗi';

      switch (statusCode) {
        case 400:
          throw BadRequestException(message, path: ApiConstants.login);
        case 401:
          throw UnauthorizedException(message, path: ApiConstants.login);
        default:
          throw ServerException(message, path: ApiConstants.login);
      }
    }
  }

  /// Đăng xuất – xóa token khỏi secure storage.
  Future<void> logout() async {
    await DioClient.instance.clearToken();
  }

  /// Kiểm tra đã đăng nhập chưa.
  Future<bool> isLoggedIn() async {
    return await DioClient.instance.hasToken();
  }
}
