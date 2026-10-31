import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/cart/domain/cart_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class ApiCartRepository implements CartRepository {
  ApiCartRepository(this._client);

  final api.RestClient _client;

  @override
  Future<Cart> cart({String? addressId, List<String>? itemIds}) => guardApi(
    () async => (await _client.cart.getCart(
      addressId: addressId,
      itemIds: itemIds,
    )).toDomain(),
  );

  @override
  Future<Cart> updateItem(String itemId, int quantity) => guardApi(
    () async => (await _client.cart.updateCartItem(
      id: itemId,
      body: api.QuantityRequest(quantity: quantity),
    )).toDomain(),
  );

  @override
  Future<Cart> removeItem(String itemId) => guardApi(
    () async => (await _client.cart.removeCartItem(id: itemId)).toDomain(),
  );

  @override
  Future<List<Address>> addresses() => guardApi(
    () async =>
        (await _client.users.listAddresses()).map((a) => a.toDomain()).toList(),
  );

  @override
  Future<Wallet> wallet() =>
      guardApi(() async => (await _client.wallet.getWallet()).toDomain());

  @override
  Future<CheckoutResult> checkout({
    required String addressId,
    required PaymentMethod method,
    List<String>? itemIds,
  }) => guardApi(
    () async => (await _client.orders.checkout(
      body: api.CheckoutRequest(
        addressId: addressId,
        paymentMethod: toApiEnum(api.PaymentMethod.values, method),
        cartItemIds: itemIds,
      ),
    )).toDomain(),
  );

  @override
  Future<Payment> payment(String id) => guardApi(
    () async => (await _client.payments.getPayment(id: id)).toDomain(),
  );

  /// Backend thật nhận kết quả qua IPN của VNPay — app chỉ đọc lại [payment].
  @override
  Future<Payment> simulateGateway(String paymentId, {required bool success}) =>
      payment(paymentId);
}
