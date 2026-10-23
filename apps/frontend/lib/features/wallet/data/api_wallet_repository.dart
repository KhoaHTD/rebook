import 'package:book_marketplace/api/generated/export.dart' as api;
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

  /// Backend cần tài khoản ngân hàng nhận tiền; app chỉ hỏi số tiền nên lấy
  /// tài khoản đã khai khi mở shop.
  @override
  Future<Withdrawal> requestWithdrawal(int amount) => guardApi(() async {
    final api.ShopResponse shop;
    try {
      shop = await _client.user.getMeShop();
    } on Object {
      throw const ServerException(
        400,
        code: 'BANK_REQUIRED',
        message: 'Cần mở shop và khai tài khoản ngân hàng trước khi rút tiền.',
      );
    }
    final res = await _client.wallet.postWalletWithdrawals(
      body: api.WithdrawCreateRequest(
        amount: amount,
        bankName: shop.bankName ?? '',
        accountNumber: shop.bankAccountNumber ?? '',
        accountHolder: shop.bankAccountHolder ?? '',
      ),
    );
    return res.toDomain();
  });
}
