// lib/features/auth/model/auth_user.dart
// ============================================================
// Project LUCY — Auth Data Models
// Mirrors the backend AuthUserResponse / LoginResponse contracts.
// ============================================================

/// Represents a logged-in user from the LUCY auth service.
///
/// Fields match [AuthUserResponse] from the .NET backend:
/// - [id], [email], [role] — identity
/// - [displayName], [avatarUrl] — profile
/// - [isAnonymous] — anonymity flag
/// - [balance] — wallet balance
class AuthUser {
  final int id;
  final String email;
  final String role;
  final int? languageId;
  final String? displayName;
  final String? avatarUrl;
  final bool isAnonymous;
  final double balance;
  final String? createdAt;

  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
    this.languageId,
    this.displayName,
    this.avatarUrl,
    this.isAnonymous = true,
    this.balance = 0,
    this.createdAt,
  });

  /// Deserializes from the API JSON response.
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      email: json['email'] as String,
      role: json['role'] as String,
      languageId: json['languageId'] as int?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? true,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] as String?,
    );
  }
}

/// Response from `POST /api/auth/login` or `POST /api/auth/register`.
///
/// Contains the JWT [accessToken] and the authenticated [user].
class AuthResponse {
  final String accessToken;
  final String tokenType;
  final String expiresAt;
  final AuthUser user;

  const AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
    required this.user,
  });

  /// Deserializes from the API JSON response.
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresAt: json['expiresAt'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
