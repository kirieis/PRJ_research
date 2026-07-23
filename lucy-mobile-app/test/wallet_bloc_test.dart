// test/wallet_bloc_test.dart
// ============================================================
// Project LUCY — WalletBloc Unit Tests (Dev 5 — T10)
//
// Covers: balance fetch, deposit success, deposit error,
//         gift success, gift 409 (insufficient balance),
//         gift 429 (rate limit)
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:lucy_app/features/wallet/bloc/wallet_bloc.dart';
import 'package:lucy_app/features/wallet/bloc/wallet_event.dart';
import 'package:lucy_app/features/wallet/bloc/wallet_state.dart';
import 'package:lucy_app/features/wallet/service/wallet_service.dart';

@GenerateMocks([WalletService])
import 'wallet_bloc_test.mocks.dart';

void main() {
  late MockWalletService mockService;

  setUp(() {
    mockService = MockWalletService();
  });

  group('WalletBloc — Balance Fetch', () {
    blocTest<WalletBloc, WalletState>(
      'emits [loading, balanceLoaded] when balance fetch succeeds',
      build: () {
        when(mockService.getBalance()).thenAnswer(
          (_) async => const WalletBalance(balance: 500000, currency: 'VND'),
        );
        return WalletBloc(walletService: mockService);
      },
      act: (bloc) => bloc.add(const WalletBalanceFetched()),
      expect: () => [
        const WalletState(status: WalletStatus.loading),
        const WalletState(
          balance: 500000,
          status: WalletStatus.balanceLoaded,
        ),
      ],
      verify: (_) {
        verify(mockService.getBalance()).called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'emits [loading, error] when balance fetch fails',
      build: () {
        when(mockService.getBalance()).thenThrow(
          const WalletException(statusCode: 500, message: 'Network error'),
        );
        return WalletBloc(walletService: mockService);
      },
      act: (bloc) => bloc.add(const WalletBalanceFetched()),
      expect: () => [
        const WalletState(status: WalletStatus.loading),
        const WalletState(
          status: WalletStatus.error,
          errorMessage: 'Network error',
        ),
      ],
    );
  });

  group('WalletBloc — Deposit', () {
    blocTest<WalletBloc, WalletState>(
      'emits [depositing, depositSuccess] when deposit succeeds',
      build: () {
        when(mockService.deposit(amount: 100000)).thenAnswer(
          (_) async => const WalletBalance(balance: 600000, currency: 'VND'),
        );
        return WalletBloc(walletService: mockService);
      },
      seed: () => const WalletState(balance: 500000),
      act: (bloc) => bloc.add(const WalletDepositRequested(amount: 100000)),
      expect: () => [
        const WalletState(
          balance: 500000,
          status: WalletStatus.depositing,
        ),
        const WalletState(
          balance: 600000,
          status: WalletStatus.depositSuccess,
        ),
      ],
      verify: (_) {
        verify(mockService.deposit(amount: 100000)).called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'emits [depositing, error] when deposit fails',
      build: () {
        when(mockService.deposit(amount: 100000)).thenThrow(
          const WalletException(statusCode: 500, message: 'Server error'),
        );
        return WalletBloc(walletService: mockService);
      },
      seed: () => const WalletState(balance: 500000),
      act: (bloc) => bloc.add(const WalletDepositRequested(amount: 100000)),
      expect: () => [
        const WalletState(
          balance: 500000,
          status: WalletStatus.depositing,
        ),
        const WalletState(
          balance: 500000,
          status: WalletStatus.error,
          errorMessage: 'Server error',
        ),
      ],
    );
  });

  group('WalletBloc — Gift', () {
    blocTest<WalletBloc, WalletState>(
      'emits [sendingGift, giftSuccess] when gift succeeds',
      build: () {
        when(mockService.sendGift(
          toUserId: 'host_001',
          amount: 5000,
          giftType: 'flower',
        )).thenAnswer((_) async {});
        return WalletBloc(walletService: mockService);
      },
      seed: () => const WalletState(balance: 100000),
      act: (bloc) => bloc.add(const WalletGiftSent(
        toUserId: 'host_001',
        amount: 5000,
        giftType: 'flower',
      )),
      expect: () => [
        const WalletState(
          balance: 100000,
          status: WalletStatus.sendingGift,
          isInsufficientBalance: false,
        ),
        const WalletState(
          balance: 95000,
          status: WalletStatus.giftSuccess,
          isInsufficientBalance: false,
        ),
      ],
      verify: (_) {
        verify(mockService.sendGift(
          toUserId: 'host_001',
          amount: 5000,
          giftType: 'flower',
        )).called(1);
      },
    );

    blocTest<WalletBloc, WalletState>(
      'emits [sendingGift, error(insufficient)] on 409',
      build: () {
        when(mockService.sendGift(
          toUserId: 'host_001',
          amount: 50000,
          giftType: 'crown',
        )).thenThrow(
          const WalletException(
            message: 'Số dư không đủ',
            statusCode: 409,
          ),
        );
        return WalletBloc(walletService: mockService);
      },
      seed: () => const WalletState(balance: 10000),
      act: (bloc) => bloc.add(const WalletGiftSent(
        toUserId: 'host_001',
        amount: 50000,
        giftType: 'crown',
      )),
      expect: () => [
        const WalletState(
          balance: 10000,
          status: WalletStatus.sendingGift,
          isInsufficientBalance: false,
        ),
        const WalletState(
          balance: 10000,
          status: WalletStatus.error,
          errorMessage: 'Số dư không đủ',
          isInsufficientBalance: true,
        ),
      ],
    );

    blocTest<WalletBloc, WalletState>(
      'emits [sendingGift, error(rate limit)] on 429',
      build: () {
        when(mockService.sendGift(
          toUserId: 'host_001',
          amount: 5000,
          giftType: 'flower',
        )).thenThrow(
          const WalletException(
            message: 'Bạn gửi quà quá nhanh, vui lòng thử lại',
            statusCode: 429,
          ),
        );
        return WalletBloc(walletService: mockService);
      },
      seed: () => const WalletState(balance: 100000),
      act: (bloc) => bloc.add(const WalletGiftSent(
        toUserId: 'host_001',
        amount: 5000,
        giftType: 'flower',
      )),
      expect: () => [
        const WalletState(
          balance: 100000,
          status: WalletStatus.sendingGift,
          isInsufficientBalance: false,
        ),
        const WalletState(
          balance: 100000,
          status: WalletStatus.error,
          errorMessage: 'Bạn gửi quà quá nhanh, vui lòng thử lại',
        ),
      ],
    );
  });
}
