/// Generic API response wrapper.
///
/// Dùng chung cho tất cả response từ server để thống nhất
/// cách xử lý dữ liệu và lỗi.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  /// Tạo response thành công.
  factory ApiResponse.success(T data) {
    return ApiResponse(success: true, data: data, statusCode: 200);
  }

  /// Tạo response lỗi.
  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}
