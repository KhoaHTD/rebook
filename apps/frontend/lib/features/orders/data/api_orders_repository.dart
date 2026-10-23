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
  Future<List<Order>> myOrders() => guardApi(() async {
    final res = await _client.order.getOrders(size: 100);
    return [for (final o in res.items.orEmpty) o.toDomain()];
  });

  @override
  Future<Order> order(String id) => guardApi(
    () async => (await _client.order.getOrdersId(id: apiId(id))).toDomain(),
  );

  @override
  Future<Order> cancel(String id, String reason) => guardApi(
    () async => (await _client.order.postOrdersIdCancel(
      id: apiId(id),
      body: api.ReasonRequest(reason: reason),
    )).toDomain(),
  );

  @override
  Future<Order> confirmReceived(String id) => guardApi(
    () async =>
        (await _client.order.postOrdersIdConfirmReceived(id: apiId(id)))
            .toDomain(),
  );

  /// Lý do trả hàng của app là chữ tự do; backend nhận mã + mô tả nên gửi
  /// mã chung "khác mô tả" kèm nguyên văn lý do.
  @override
  Future<Order> requestReturn(
    String id,
    String reason,
    List<String> imageUrls,
  ) => guardApi(
    () async => (await _client.order.postOrdersIdReturn(
      id: apiId(id),
      body: api.ReturnCreateRequest(
        reason: api.ReturnReason.otherNotAsDescribed,
        description: reason,
        images: imageUrls,
      ),
    )).toDomain(),
  );

  @override
  Future<Order> review(String id, int rating, String? comment) =>
      guardApi(() async {
        await _client.order.postOrdersIdReview(
          id: apiId(id),
          body: api.ReviewRequest(rating: rating, comment: comment),
        );
        return (await _client.order.getOrdersId(id: apiId(id))).toDomain();
      });

  /// Đơn đấu giá: chọn nhận hàng (địa chỉ / lấy tại kho) rồi mới thanh toán.
  @override
  Future<CheckoutResult> pay(
    String id,
    PaymentMethod method, {
    String? addressId,
    bool pickupAtWarehouse = false,
  }) => guardApi(() async {
    final orderId = apiId(id);
    if (pickupAtWarehouse || addressId != null) {
      await _client.auction.postOrdersIdDeliveryOption(
        id: orderId,
        body: api.DeliveryOptionRequest(
          addressId: pickupAtWarehouse ? null : int.tryParse(addressId ?? ''),
          pickupAtWarehouse: pickupAtWarehouse,
        ),
      );
    }
    final res = await _client.order.postOrdersIdPay(
      id: orderId,
      body: api.PayRequest(method: paymentMethodToApi(method)),
    );
    return CheckoutResult(
      orders: [if (res.order != null) res.order!.toDomain()],
      payment: res.payment?.toDomain(),
    );
  });

  @override
  Future<List<Address>> addresses() => guardApi(
    () async => [
      for (final a in await _client.user.getMeAddresses()) a.toDomain(),
    ],
  );

  @override
  Future<Wallet> wallet() =>
      guardApi(() async => (await _client.wallet.getWallet()).toDomain());
}
