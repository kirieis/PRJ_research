import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/level_model.dart';

/// Repository xử lý API calls liên quan đến LMS (Learning Management System).
///
/// Phụ trách: Dev 3 (Trần Quốc Thịnh) – Backend
///            Dev 1 (Nguyễn Trí Thiện) – Mobile integration
class LmsRepository {
  final Dio _dio = DioClient.instance.dio;

  /// Lấy danh sách levels – GET /api/levels
  ///
  /// [languageId] – Lọc theo ngôn ngữ (optional)
  /// [isPublished] – Lọc theo trạng thái publish (optional)
  /// [stageNumber] – Lọc theo giai đoạn (optional)
  Future<List<LevelModel>> getLevels({
    int? languageId,
    bool? isPublished,
    int? stageNumber,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (languageId != null) queryParams['language_id'] = languageId;
      if (isPublished != null) queryParams['is_published'] = isPublished;
      if (stageNumber != null) queryParams['stage_number'] = stageNumber;

      final response = await _dio.get(
        ApiConstants.levels,
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => LevelModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message =
          e.response?.data?['message'] as String? ?? 'Đã xảy ra lỗi';

      switch (statusCode) {
        case 400:
          throw BadRequestException(message, path: ApiConstants.levels);
        case 401:
          throw UnauthorizedException(message, path: ApiConstants.levels);
        default:
          throw ServerException(message, path: ApiConstants.levels);
      }
    }
  }

  /// Import file DOCX – POST /api/import/docx
  ///
  /// [filePath] – Đường dẫn file .docx trên thiết bị
  /// [languageId] – ID ngôn ngữ cho nội dung import
  /// [stageNumber] – Giai đoạn (optional)
  Future<LevelModel> importDocx({
    required String filePath,
    required int languageId,
    int? stageNumber,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: 'import.docx'),
        'language_id': languageId,
        if (stageNumber != null) 'stage_number': stageNumber,
      });

      final response = await _dio.post(
        ApiConstants.importDocx,
        data: formData,
      );

      return LevelModel.fromJson(
          response.data['level'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message =
          e.response?.data?['message'] as String? ?? 'Đã xảy ra lỗi';

      switch (statusCode) {
        case 400:
          throw BadRequestException(message, path: ApiConstants.importDocx);
        case 401:
          throw UnauthorizedException(message, path: ApiConstants.importDocx);
        default:
          throw ServerException(message, path: ApiConstants.importDocx);
      }
    }
  }
}
