/// Model người dùng – map từ bảng `users` trong LucyDB.
///
/// Không bao gồm `password_hash` vì không bao giờ trả về từ API.
class UserModel {
  final int id;
  final String email;
  final String role; // LUCY | PRO | SUPER | ADMIN
  final int? languageId;
  final String? displayName;
  final String? avatarUrl;
  final bool isAnonymous;
  final double balance;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.languageId,
    this.displayName,
    this.avatarUrl,
    this.isAnonymous = true,
    this.balance = 0.0,
    this.createdAt,
  });

  /// Parse từ JSON response.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      role: json['role'] as String,
      languageId: json['languageId'] as int?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? true,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Chuyển sang JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'languageId': languageId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'isAnonymous': isAnonymous,
      'balance': balance,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
