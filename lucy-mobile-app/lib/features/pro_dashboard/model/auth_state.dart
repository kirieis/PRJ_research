// lib/features/pro_dashboard/model/auth_state.dart
// ============================================================
// Project LUCY — Auth State Model
// Lightweight JWT-derived auth data for role-based access.
//
// Source: Dev 6 (.NET) provides role in JWT payload.
// Until real JWT flow is integrated, passed via route params.
// ============================================================

import 'package:equatable/equatable.dart';

/// Represents the authenticated user's identity and role.
///
/// The [role] field determines UI visibility:
/// - `"mentor"` / `"host"` → full moderator controls (Zone 1 + Zone 2)
/// - `"pro"` → read-only dashboard access
/// - `"learner"` → no dashboard access (redirected)
class AuthState extends Equatable {
  /// Unique user identifier from .NET auth service.
  final String userId;

  /// Anonymous display name (e.g., "Anonymous Fox").
  final String displayName;

  /// Role from JWT payload. Possible values: "mentor", "host", "pro", "learner".
  final String role;

  const AuthState({
    required this.userId,
    required this.displayName,
    required this.role,
  });

  /// Whether this user has moderator privileges.
  /// Only mentors and hosts can control sub-levels and approve speakers.
  bool get canModerate => role == 'mentor' || role == 'host';

  /// Creates from route extras map.
  factory AuthState.fromExtras(Map<String, dynamic> extras) {
    return AuthState(
      userId: extras['userId'] as String? ?? '',
      displayName: extras['displayName'] as String? ?? 'Anonymous',
      role: extras['role'] as String? ?? 'learner',
    );
  }

  @override
  List<Object?> get props => [userId, displayName, role];
}
