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

/// Tài khoản ngân hàng đã dùng để rút tiền (màn "Gần đây"): yêu thích đứng đầu, rồi lần dùng mới nhất.
@riverpod
Future<List<BankAccount>> bankAccounts(Ref ref) {
  ref.watchArea(DataArea.wallet);
  return ref.watch(walletRepositoryProvider).bankAccounts();
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

  Future<Withdrawal?> withdraw(
    int amount, {
    required String bankName,
    required String accountNumber,
    required String accountName,
    String? note,
  }) async {
    state = const AsyncLoading();
    Withdrawal? created;
    state = await AsyncValue.guard(() async {
      created = await ref
          .read(walletRepositoryProvider)
          .requestWithdrawal(
            amount,
            bankName: bankName,
            accountNumber: accountNumber,
            accountName: accountName,
            note: note,
          );
    });
    if (!state.hasError) {
      ref.read(dataChangesProvider.notifier).bump(DataArea.wallet);
    }
    return created;
  }

  /// Đánh dấu / bỏ yêu thích một tài khoản ngân hàng đã lưu.
  Future<void> setBankFavorite(String id, {required bool on}) async {
    await ref.read(walletRepositoryProvider).setBankAccountFavorite(id, on: on);
    ref.read(dataChangesProvider.notifier).bump(DataArea.wallet);
  }
}
