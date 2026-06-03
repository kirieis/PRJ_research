// lib/features/wallet/bloc/wallet_state.dart
// ============================================================
// Project LUCY — Wallet BLoC State
// ============================================================

import 'package:equatable/equatable.dart';

/// Possible wallet operation statuses.
enum WalletStatus {
  initial,
  loading,
  depositing,
  sendingGift,
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
