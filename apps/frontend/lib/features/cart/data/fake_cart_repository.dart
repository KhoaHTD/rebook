import 'package:book_marketplace/features/cart/domain/cart_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class FakeCartRepository implements CartRepository {
  FakeCartRepository(this._store);

  final FakeStore _store;

  @override
  Future<Cart> cart({String? addressId, List<String>? itemIds}) =>
      fakeCall(() => _store.cart(addressId: addressId, itemIds: itemIds));

  @override
  Future<Cart> updateItem(String itemId, int quantity) =>
      fakeCall(() => _store.updateCartItem(itemId, quantity), ms: 120);

  @override
  Future<Cart> removeItem(String itemId) =>
      fakeCall(() => _store.updateCartItem(itemId, 0), ms: 120);

  @override
  Future<List<Address>> addresses() => fakeCall(_store.myAddresses);

  @override
  Future<Wallet> wallet() =>
      fakeCall(() => _store.walletOf(_store.currentUserId!));

  @override
  Future<CheckoutResult> checkout({
    required String addressId,
    required PaymentMethod method,
    List<String>? itemIds,
  }) => fakeCall(
    () =>
        _store.checkout(addressId: addressId, method: method, itemIds: itemIds),
    ms: 600,
  );

  @override
  Future<Payment> payment(String id) => fakeCall(() => _store.payment(id));

  @override
  Future<Payment> simulateGateway(String paymentId, {required bool success}) =>
      fakeCall(
        () => _store.completePayment(paymentId, success: success),
        ms: 800,
      );
}
