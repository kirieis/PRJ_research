// lib/features/wallet/service/wallet_service.dart
// ============================================================
// Project LUCY — Wallet API Service
//
// HTTP client layer for wallet operations.
// Endpoints (from Dev 6 — .NET Backend):
//   POST /api/wallet/deposit  → {amount: int, currency: "VND"}
//   POST /api/wallet/gift     → {toUserId, amount, giftType}
//   GET  /api/wallet/balance  → {balance: int, currency: "VND"}
//
// Error codes:
//   409 — Insufficient balance
//   429 — Rate limited (server-side race condition handling)
// ============================================================

import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';

/// Custom exception for wallet-specific errors.
class WalletException implements Exception {
  final int statusCode;
  final String message;

  const WalletException({required this.statusCode, required this.message});

  /// Returns true if the error is "Insufficient balance" (HTTP 409).
  bool get isInsufficientBalance => statusCode == 409;

  /// Returns true if the error is "Rate limited" (HTTP 429).
  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => 'WalletException($statusCode): $message';
}

/// Wallet balance response model.
class WalletBalance {
  final int balance;
  final String currency;

  const WalletBalance({required this.balance, this.currency = 'VND'});

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      balance: json['balance'] as int,
      currency: json['currency'] as String? ?? 'VND',
    );
  }
}

/// Service class encapsulating wallet HTTP calls.
///
/// Uses [Dio] for HTTP requests. All methods throw [WalletException]
/// for known error codes (409, 429) or rethrow unexpected errors.
///
/// **Usage:**
/// ```dart
/// final service = WalletService();
/// final balance = await service.getBalance();
/// await service.deposit(amount: 100000);
/// await service.sendGift(toUserId: 'user_002', amount: 5000, giftType: 'flower');
/// ```
class WalletService {
  final Dio _dio;

  WalletService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.apiBaseUrl,
              connectTimeout:
                  Duration(milliseconds: AppConstants.connectTimeout),
              receiveTimeout:
                  Duration(milliseconds: AppConstants.receiveTimeout),
            ));

  /// Fetches current wallet balance.
  ///
  /// GET /api/wallet/balance → {balance: int, currency: "VND"}
  Future<WalletBalance> getBalance() async {
    try {
      final response = await _dio.get('/api/wallet/balance');
      return WalletBalance.fromJson(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Deposits money into the wallet (simulated top-up).
  ///
  /// POST /api/wallet/deposit → body: {amount: int, currency: "VND"}
  /// Returns the updated [WalletBalance] after deposit.
  Future<WalletBalance> deposit({required int amount}) async {
    try {
      final response = await _dio.post('/api/wallet/deposit', data: {
        'amount': amount,
        'currency': 'VND',
      });
      return WalletBalance.fromJson(response.data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Sends a gift to another user.
  ///
  /// POST /api/wallet/gift → body: {toUserId, amount, giftType}
  /// [giftType] must be one of: "flower", "star", "crown"
  ///
  /// Throws [WalletException] with statusCode 409 if insufficient balance.
  Future<void> sendGift({
    required String toUserId,
    required int amount,
    required String giftType,
  }) async {
    try {
      await _dio.post('/api/wallet/gift', data: {
        'toUserId': toUserId,
        'amount': amount,
        'giftType': giftType,
      });
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Maps [DioException] to [WalletException] for known status codes.
  WalletException _mapDioError(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    switch (statusCode) {
      case 409:
        return const WalletException(
          statusCode: 409,
          message: 'Số dư không đủ',
        );
      case 429:
        return const WalletException(
          statusCode: 429,
          message: 'Quá nhiều yêu cầu, vui lòng thử lại sau',
        );
      default:
        return WalletException(
          statusCode: statusCode,
          message: e.message ?? 'Lỗi không xác định',
        );
    }
  }
}
