import 'package:book_marketplace/features/orders/domain/orders_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class FakeOrdersRepository implements OrdersRepository {
  FakeOrdersRepository(this._store);

  final FakeStore _store;

  @override
  Future<List<Order>> myOrders() => fakeCall(() => _store.myOrders().items);

  @override
  Future<Order> order(String id) => fakeCall(() => _store.order(id));

  @override
  Future<Order> cancel(String id, String reason) =>
      fakeCall(() => _store.cancelByBuyer(id, reason));

  @override
  Future<Order> confirmReceived(String id) =>
      fakeCall(() => _store.confirmReceived(id));

  @override
  Future<Order> requestReturn(
    String id,
    String reason,
    List<String> imageUrls,
  ) => fakeCall(() => _store.requestReturn(id, reason, imageUrls));

  @override
  Future<Order> review(String id, int rating, String? comment) =>
      fakeCall(() => _store.review(id, rating, comment));

  @override
  Future<CheckoutResult> pay(
    String id,
    PaymentMethod method, {
    String? addressId,
    bool pickupAtWarehouse = false,
  }) => fakeCall(
    () => _store.payOrder(
      id,
      method,
      addressId: addressId,
      pickup: pickupAtWarehouse,
    ),
    ms: 500,
  );

  @override
  Future<List<Address>> addresses() => fakeCall(_store.myAddresses);

  @override
  Future<Wallet> wallet() =>
      fakeCall(() => _store.walletOf(_store.currentUserId!));
}
