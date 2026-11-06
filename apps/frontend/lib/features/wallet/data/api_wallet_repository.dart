import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/wallet/domain/wallet_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';

class ApiWalletRepository implements WalletRepository {
  ApiWalletRepository(this._client);

  final api.RestClient _client;

  @override
  Future<Wallet> wallet() => guardApi(() async {
    final w = (await _client.wallet.getWallet()).toDomain();
    final info = await _client.wallet.getWalletWithdrawable();
    return w.copyWith(
      locked: info.locked?.toInt() ?? 0,
      unlockAt: info.unlockAt,
    );
  });

  @override
  Future<List<WalletTxn>> transactions() => guardApi(() async {
    final res = await _client.wallet.getWalletTransactions(size: 100);
    return [for (final t in res.items.orEmpty) t.toDomain()];
  });

  @override
  Future<Payment> topUp(int amount) => guardApi(
    () async => (await _client.wallet.postWalletTopUp(
      body: api.TopUpRequest(amount: amount),
    )).toDomain(),
  );

  @override
  Future<List<Withdrawal>> withdrawals() => guardApi(
    () async => [
      for (final w in await _client.wallet.getWalletWithdrawals()) w.toDomain(),
    ],
  );

  /// Backend tự lưu tài khoản ngân hàng này vào danh sách "Gần đây".
  @override
  Future<Withdrawal> requestWithdrawal(
    int amount, {
    required String bankName,
    required String accountNumber,
    required String accountName,
    String? note,
  }) => guardApi(() async {
    final res = await _client.wallet.postWalletWithdrawals(
      body: api.WithdrawCreateRequest(
        amount: amount,
        bankName: bankName,
        accountNumber: accountNumber,
        accountHolder: accountName,
        note: note,
      ),
    );
    return res.toDomain();
  });

  @override
  Future<List<BankAccount>> bankAccounts() => guardApi(
    () async => [
      for (final a in await _client.wallet.getWalletBankAccounts())
        a.toDomain(),
    ],
  );

  @override
  Future<BankAccount> setBankAccountFavorite(String id, {required bool on}) =>
      guardApi(() async {
        final res = on
            ? await _client.wallet.postWalletBankAccountsIdFavorite(
                id: apiId(id),
              )
            : await _client.wallet.deleteWalletBankAccountsIdFavorite(
                id: apiId(id),
              );
        return res.toDomain();
      });
}
