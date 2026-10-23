import 'package:book_marketplace/features/wallet/domain/wallet_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';

class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository(this._store);

  final FakeStore _store;

  @override
  Future<Wallet> wallet() =>
      fakeCall(() => _store.walletOf(_store.currentUserId!));

  @override
  Future<List<WalletTxn>> transactions() => fakeCall(_store.myTxns);

  @override
  Future<Payment> topUp(int amount) => fakeCall(() => _store.topUp(amount));

  @override
  Future<List<Withdrawal>> withdrawals() => fakeCall(_store.myWithdrawals);

  @override
  Future<Withdrawal> requestWithdrawal(int amount) =>
      fakeCall(() => _store.requestWithdrawal(amount));
}
