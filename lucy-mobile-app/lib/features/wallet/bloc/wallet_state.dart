// lib/features/wallet/bloc/wallet_state.dart
// ============================================================
// Project LUCY — Wallet BLoC State
//
// FIX (Audit): Tách WalletStatus.success thành sub-types
// để tránh snackbar hiện sai context (deposit vs gift vs balance).
// ============================================================

import 'package:equatable/equatable.dart';

/// Possible wallet operation statuses.
///
/// FIX: Tách `success` thành 3 sub-types rõ ràng:
/// - [balanceLoaded] — GET balance thành công
/// - [depositSuccess] — POST deposit thành công
/// - [giftSuccess] — POST gift thành công
enum WalletStatus {
  initial,
  loading,
  depositing,
  sendingGift,
  balanceLoaded,
  depositSuccess,
  giftSuccess,
  /// @deprecated — giữ lại cho backward compatibility, dùng sub-types ở trên.
  success,
  error,
}

/// Immutable state for the wallet feature.
///
/// Tracks:
/// - [balance]: current wallet balance in VND
/// - [status]: current operation status
/// - [errorMessage]: non-null when [status] is [WalletStatus.error]
/// - [isInsufficientBalance]: true when a 409 error occurred
class WalletState extends Equatable {
  final int balance;
  final WalletStatus status;
  final String? errorMessage;
  final bool isInsufficientBalance;

  const WalletState({
    this.balance = 0,
    this.status = WalletStatus.initial,
    this.errorMessage,
    this.isInsufficientBalance = false,
  });

  /// Whether the wallet is currently performing a deposit.
  bool get isDepositing => status == WalletStatus.depositing;

  /// Whether the wallet is currently sending a gift.
  bool get isSendingGift => status == WalletStatus.sendingGift;

  /// Whether any async operation is in progress.
  bool get isBusy =>
      status == WalletStatus.loading ||
      status == WalletStatus.depositing ||
      status == WalletStatus.sendingGift;

  /// Whether any success status is active (for backward compat).
  bool get isSuccess =>
      status == WalletStatus.success ||
      status == WalletStatus.depositSuccess ||
      status == WalletStatus.giftSuccess ||
      status == WalletStatus.balanceLoaded;

  WalletState copyWith({
    int? balance,
    WalletStatus? status,
    String? errorMessage,
    bool? isInsufficientBalance,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      status: status ?? this.status,
      errorMessage: errorMessage,
      isInsufficientBalance:
          isInsufficientBalance ?? this.isInsufficientBalance,
    );
  }

  @override
  List<Object?> get props =>
      [balance, status, errorMessage, isInsufficientBalance];
}
