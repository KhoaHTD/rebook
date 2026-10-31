import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/wallet/domain/wallet_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';

class ApiWalletRepository implements WalletRepository {
  ApiWalletRepository(this._client);

  final api.RestClient _client;

  @override
  Future<Wallet> wallet() =>
      guardApi(() async => (await _client.wallet.getWallet()).toDomain());

  @override
  Future<List<WalletTxn>> transactions() => guardApi(() async {
    final page = await _client.wallet.listWalletTransactions(size: 100);
    return page.items.map((e) => e.toDomain()).toList();
  });

  @override
  Future<Payment> topUp(int amount) => guardApi(
    () async => (await _client.wallet.topUp(
      body: api.TopUpRequest(amount: amount, returnUrl: Env.paymentReturnUrl),
    )).toDomain(),
  );

  @override
  Future<List<Withdrawal>> withdrawals() => guardApi(
    () async => (await _client.wallet.listWithdrawals())
        .map((e) => e.toDomain())
        .toList(),
  );

  @override
  Future<List<BankAccount>> bankAccounts() => guardApi(
    () async => (await _client.wallet.listBankAccounts())
        .map((e) => e.toDomain())
        .toList(),
  );

  @override
  Future<BankAccount> setBankAccountFavorite(String id, {required bool on}) =>
      guardApi(
        () async => (await _client.wallet.setBankAccountFavorite(
          id: id,
          body: api.FavoriteRequest(favorite: on),
        )).toDomain(),
      );

  @override
  Future<Withdrawal> requestWithdrawal(
    int amount, {
    required String bankName,
    required String accountNumber,
    required String accountName,
    String? note,
  }) => guardApi(
    () async => (await _client.wallet.requestWithdrawal(
      body: api.WithdrawalRequest(
        amount: amount,
        bankName: bankName,
        bankAccountNumber: accountNumber,
        bankAccountName: accountName,
        note: note,
      ),
    )).toDomain(),
  );
}
