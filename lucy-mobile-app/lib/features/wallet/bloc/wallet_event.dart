// lib/features/wallet/bloc/wallet_event.dart
// ============================================================
// Project LUCY — Wallet BLoC Events
// ============================================================

import 'package:equatable/equatable.dart';

/// Base class for all wallet events.
abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch the current wallet balance from server.
class WalletBalanceFetched extends WalletEvent {
  const WalletBalanceFetched();
}

/// User initiated a deposit.
class WalletDepositRequested extends WalletEvent {
  final int amount;

  const WalletDepositRequested({required this.amount});

  @override
  List<Object?> get props => [amount];
}

/// User initiated a gift send.
class WalletGiftSent extends WalletEvent {
  final String toUserId;
  final int amount;
  final String giftType;

  const WalletGiftSent({
    required this.toUserId,
    required this.amount,
    required this.giftType,
  });

  @override
  List<Object?> get props => [toUserId, amount, giftType];
}
