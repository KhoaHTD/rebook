import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/orders/domain/orders_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class ApiOrdersRepository implements OrdersRepository {
  ApiOrdersRepository(this._client);

  final api.RestClient _client;

  @override
  Future<List<Order>> myOrders() => guardApi(
    () async => (await _client.orders.listMyOrders(size: 100)).toDomain().items,
  );

  @override
  Future<Order> order(String id) =>
      guardApi(() async => (await _client.orders.getOrder(id: id)).toDomain());

  @override
  Future<Order> cancel(String id, String reason) => guardApi(
    () async => (await _client.orders.cancelOrder(
      id: id,
      body: api.ReasonRequest(reason: reason),
    )).toDomain(),
  );

  @override
  Future<Order> confirmReceived(String id) => guardApi(
    () async => (await _client.orders.confirmReceived(id: id)).toDomain(),
  );

  @override
  Future<Order> requestReturn(
    String id,
    String reason,
    List<String> imageUrls,
  ) => guardApi(
    () async => (await _client.orders.requestReturn(
      id: id,
      body: api.ReturnRequestInput(reason: reason, imageUrls: imageUrls),
    )).toDomain(),
  );

  @override
  Future<Order> review(String id, int rating, String? comment) => guardApi(
    () async => (await _client.orders.reviewOrder(
      id: id,
      body: api.ReviewRequest(rating: rating, comment: comment),
    )).toDomain(),
  );

  @override
  Future<CheckoutResult> pay(
    String id,
    PaymentMethod method, {
    String? addressId,
    bool pickupAtWarehouse = false,
  }) => guardApi(
    () async => (await _client.orders.payOrder(
      id: id,
      body: api.PayOrderRequest(
        paymentMethod: toApiEnum(api.PaymentMethod.values, method),
        addressId: addressId,
        pickupAtWarehouse: pickupAtWarehouse,
      ),
    )).toDomain(),
  );

  @override
  Future<List<Address>> addresses() => guardApi(
    () async =>
        (await _client.users.listAddresses()).map((a) => a.toDomain()).toList(),
  );

  @override
  Future<Wallet> wallet() =>
      guardApi(() async => (await _client.wallet.getWallet()).toDomain());
}
