import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/cart/domain/cart_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

/// Backend khoá giỏ hàng theo tin đăng nên `itemId` ở đây chính là id tin đăng.
class ApiCartRepository implements CartRepository {
  ApiCartRepository(this._client);

  final api.RestClient _client;

  @override
  Future<Cart> cart({String? addressId}) => guardApi(() async {
    final cart = await _client.order.getCart();
    final empty = (cart.shops.orEmpty).isEmpty;
    final address = int.tryParse(addressId ?? '');
    if (address == null || empty) return cartToDomain(cart);
    // Phí ship phụ thuộc địa chỉ nhận: hỏi báo giá của backend.
    final quote = await _client.order.postOrdersCheckoutPreview(
      body: api.CheckoutPreviewRequest(addressId: address),
    );
    return cartToDomain(cart, quote: quote);
  });

  @override
  Future<Cart> updateItem(String itemId, int quantity) => guardApi(
    () async => cartToDomain(
      await _client.order.putCartListingId(
        listingId: apiId(itemId),
        body: api.UpdateCartRequest(quantity: quantity),
      ),
    ),
  );

  @override
  Future<Cart> removeItem(String itemId) => guardApi(
    () async => cartToDomain(
      await _client.order.deleteCartListingId(listingId: apiId(itemId)),
    ),
  );

  @override
  Future<List<Address>> addresses() => guardApi(
    () async => [
      for (final a in await _client.user.getMeAddresses()) a.toDomain(),
    ],
  );

  @override
  Future<Wallet> wallet() =>
      guardApi(() async => (await _client.wallet.getWallet()).toDomain());

  @override
  Future<CheckoutResult> checkout({
    required String addressId,
    required PaymentMethod method,
    List<String>? itemIds,
  }) => guardApi(() async {
    final res = await _client.order.postOrdersCheckout(
      body: api.CheckoutRequest(
        addressId: apiId(addressId),
        paymentMethod: paymentMethodToApi(method),
        listingIds: itemIds?.map(apiId).toList(),
      ),
    );
    return CheckoutResult(
      orders: [for (final o in res.orders.orEmpty) o.toDomain()],
      payment: res.payment?.toDomain(),
    );
  });

  @override
  Future<Payment> payment(String id) => guardApi(
    () async => (await _client.wallet.getPaymentsCode(code: id)).toDomain(),
  );

  /// Backend chỉ có "giả lập thanh toán thành công". Giả lập thất bại = không
  /// làm gì, thanh toán giữ nguyên trạng thái chờ rồi tự hết hạn.
  @override
  Future<Payment> simulateGateway(String paymentId, {required bool success}) =>
      guardApi(() async {
        final res = success
            ? await _client.wallet.postPaymentsCodeSimulate(code: paymentId)
            : await _client.wallet.getPaymentsCode(code: paymentId);
        return res.toDomain();
      });
}
