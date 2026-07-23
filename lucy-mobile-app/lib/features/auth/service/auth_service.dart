// lib/features/auth/service/auth_service.dart
// ============================================================
// Project LUCY — Auth Service
// Handles login/register API calls and local token storage.
// ============================================================

import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../model/auth_user.dart';

/// Service responsible for authentication operations.
///
/// Uses [Dio] for HTTP requests to the auth service and
/// [SharedPreferences] for persisting the JWT access token.
class AuthService {
  late final Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.authBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  // ── Login ──────────────────────────────────────────────────

  /// Authenticates a user with [email] and [password].
  ///
  /// On success, stores the JWT in SharedPreferences and returns
  /// the [AuthResponse] containing user data and token.
  ///
  /// Throws [AuthException] on failure.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    // ── MOCK LOGIN FOR TESTING ────────────────────────────────
    // Bypasses the network error since the backend is currently down.
    if (email == 'qucthih26@gmail.com' && password == '123456789') {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network
      final mockResponse = AuthResponse(
        accessToken: 'mock_jwt_token_123',
        tokenType: 'Bearer',
        expiresAt: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        user: AuthUser(
          id: 1,
          email: 'qucthih26@gmail.com',
          displayName: 'QThinh',
          role: 'LUCY',
          isAnonymous: false,
          balance: 0,
        ),
      );
      await _saveToken(mockResponse.accessToken);
      return mockResponse;
    }
    // ──────────────────────────────────────────────────────────

    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'Email': email,
          'Password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Persist the access token locally.
      await _saveToken(authResponse.accessToken);

      developer.log(
        '✅ Login successful: ${authResponse.user.email} '
        '(role=${authResponse.user.role})',
        name: 'AuthService',
      );

      return authResponse;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      developer.log('❌ Login failed: $message', name: 'AuthService');
      throw AuthException(message);
    }
  }

  // ── Register ───────────────────────────────────────────────

  /// Creates a new account with [email], [password], and [displayName].
  ///
  /// On success, stores the JWT and returns the [AuthResponse].
  /// Throws [AuthException] on failure.
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // ── MOCK REGISTER FOR TESTING ─────────────────────────────
    if (email == 'qucthih26@gmail.com') {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network
      final mockResponse = AuthResponse(
        accessToken: 'mock_jwt_token_123',
        tokenType: 'Bearer',
        expiresAt: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        user: AuthUser(
          id: 1,
          email: 'qucthih26@gmail.com',
          displayName: displayName,
          role: 'LUCY',
          isAnonymous: false,
          balance: 0,
        ),
      );
      await _saveToken(mockResponse.accessToken);
      return mockResponse;
    }
    // ──────────────────────────────────────────────────────────

    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'Email': email,
          'Password': password,
          'DisplayName': displayName,
          'Role': 'LUCY',
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Persist the access token locally.
      await _saveToken(authResponse.accessToken);

      developer.log(
        '✅ Register successful: ${authResponse.user.email}',
        name: 'AuthService',
      );

      return authResponse;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      developer.log('❌ Register failed: $message', name: 'AuthService');
      throw AuthException(message);
    }
  }

  // ── Token Management ───────────────────────────────────────

  /// Saves the JWT access token to local storage.
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.accessTokenKey, token);
  }

  /// Retrieves the stored JWT access token, or `null` if not logged in.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.accessTokenKey);
  }

  /// Returns `true` if an access token exists in local storage.
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Removes the stored access token (logout).
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    developer.log('🔓 Logged out — token removed', name: 'AuthService');
  }

  // ── Helpers ────────────────────────────────────────────────

  /// Extracts a user-friendly error message from a [DioException].
  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      return data['error'] as String? ??
          data['message'] as String? ??
          'An unexpected error occurred.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server. Check your connection.';
    }
    return 'Network error. Please try again.';
  }
}

/// Custom exception for authentication errors.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
