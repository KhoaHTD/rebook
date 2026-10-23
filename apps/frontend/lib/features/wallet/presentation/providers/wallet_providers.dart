import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/wallet/data/wallet_repository_provider.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';

part 'wallet_providers.g.dart';

@riverpod
Future<Wallet> myWallet(Ref ref) {
  ref.watchArea(DataArea.wallet);
  return ref.watch(walletRepositoryProvider).wallet();
}

@riverpod
Future<List<WalletTxn>> walletTransactions(Ref ref) {
  ref.watchArea(DataArea.wallet);
  return ref.watch(walletRepositoryProvider).transactions();
}

@riverpod
Future<List<Withdrawal>> myWithdrawals(Ref ref) {
  ref.watchArea(DataArea.wallet);
  return ref.watch(walletRepositoryProvider).withdrawals();
}

/// Nạp / rút. Nạp trả về phiên thanh toán để mở VNPay.
@riverpod
class WalletController extends _$WalletController {
  /// Số tiền tối thiểu mỗi lần nạp / rút.
  static const minAmount = 10000;

  @override
  FutureOr<void> build() {}

  Future<Payment?> topUp(int amount) async {
    state = const AsyncLoading();
    Payment? payment;
    state = await AsyncValue.guard(() async {
      payment = await ref.read(walletRepositoryProvider).topUp(amount);
    });
    return payment;
  }

  Future<bool> withdraw(int amount) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(walletRepositoryProvider).requestWithdrawal(amount),
    );
    if (!state.hasError) {
      ref.read(dataChangesProvider.notifier).bump(DataArea.wallet);
    }
    return !state.hasError;
  }
}
