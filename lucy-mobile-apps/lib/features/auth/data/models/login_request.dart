/// DTO cho request đăng nhập – POST /api/auth/login.
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  /// Chuyển sang JSON để gửi lên server.
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}
