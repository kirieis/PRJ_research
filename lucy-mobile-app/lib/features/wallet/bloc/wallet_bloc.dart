// lib/features/wallet/bloc/wallet_bloc.dart
// ============================================================
// Project LUCY — Wallet BLoC
//
// Manages wallet state: balance fetching, deposits, and gifts.
// Uses WalletService for all API calls.
//
// Error handling:
//   409 → isInsufficientBalance = true
//   429 → rate limit message (server handles race condition)
//   No automatic retry — user must manually retry.
// ============================================================

import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../service/wallet_service.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

/// BLoC managing wallet operations.
///
/// **Design decisions:**
/// - All API calls go through [WalletService] — BLoC never touches Dio directly.
/// - No automatic retry on failure — user must manually trigger actions.
/// - 409 errors set [WalletState.isInsufficientBalance] for UI to show snackbar.
/// - Balance is updated optimistically on deposit success.
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletService _walletService;

  WalletBloc({WalletService? walletService})
      : _walletService = walletService ?? WalletService(),
        super(const WalletState()) {
    on<WalletBalanceFetched>(_onBalanceFetched);
    on<WalletDepositRequested>(_onDepositRequested);
    on<WalletGiftSent>(_onGiftSent);
  }

  // ── FETCH BALANCE ────────────────────────────────────────────

  Future<void> _onBalanceFetched(
    WalletBalanceFetched event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.loading));

    try {
      final result = await _walletService.getBalance();

      developer.log(
        '💰 Balance fetched: ${result.balance} ${result.currency}',
        name: 'WalletBloc',
      );

      emit(state.copyWith(
        balance: result.balance,
        status: WalletStatus.balanceLoaded,
      ));
    } on WalletException catch (e) {
      developer.log('❌ Fetch balance error: $e', name: 'WalletBloc');
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: 'Không thể tải số dư',
      ));
    }
  }

  // ── DEPOSIT ──────────────────────────────────────────────────

  Future<void> _onDepositRequested(
    WalletDepositRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(status: WalletStatus.depositing));

    try {
      final result = await _walletService.deposit(amount: event.amount);

      developer.log(
        '💰 Deposit successful: +${event.amount} VND → new balance: ${result.balance}',
        name: 'WalletBloc',
      );

      emit(state.copyWith(
        balance: result.balance,
        status: WalletStatus.depositSuccess,
      ));
    } on WalletException catch (e) {
      developer.log('❌ Deposit error: $e', name: 'WalletBloc');
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: 'Lỗi nạp tiền, vui lòng thử lại',
      ));
    }
  }

  // ── SEND GIFT ────────────────────────────────────────────────

  Future<void> _onGiftSent(
    WalletGiftSent event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(
      status: WalletStatus.sendingGift,
      isInsufficientBalance: false,
    ));

    try {
      await _walletService.sendGift(
        toUserId: event.toUserId,
        amount: event.amount,
        giftType: event.giftType,
      );

      developer.log(
        '🎁 Gift sent: ${event.giftType} (${event.amount} VND) → ${event.toUserId}',
        name: 'WalletBloc',
      );

      // Deduct balance locally after confirmed server success.
      emit(state.copyWith(
        balance: state.balance - event.amount,
        status: WalletStatus.giftSuccess,
        isInsufficientBalance: false,
      ));
    } on WalletException catch (e) {
      developer.log('❌ Gift error: $e', name: 'WalletBloc');

      if (e.isInsufficientBalance) {
        emit(state.copyWith(
          status: WalletStatus.error,
          errorMessage: 'Số dư không đủ',
          isInsufficientBalance: true,
        ));
      } else {
        emit(state.copyWith(
          status: WalletStatus.error,
          errorMessage: e.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: WalletStatus.error,
        errorMessage: 'Lỗi gửi quà, vui lòng thử lại',
      ));
    }
  }
}
