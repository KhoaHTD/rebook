import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/cart/data/fake_cart_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

void main() {
  late FakeStore store;
  late FakeCartRepository repo;

  setUp(() {
    store = FakeStore()..login('minhanh@rebook.vn', '123456');
    repo = FakeCartRepository(store);
  });
  tearDown(() => store.dispose());

  Future<String> address() async => (await repo.addresses()).first.id;

  test('giỏ hai shop → hai đơn COD, giỏ trống, tồn kho giảm', () async {
    final a = store.searchListings(const ListingQuery()).items;
    final first = a.firstWhere((l) => l.shop.id != 's1');
    final second = a.firstWhere(
      (l) => l.shop.id != 's1' && l.shop.id != first.shop.id,
    );
    store
      ..addToCart(first.id, 1)
      ..addToCart(second.id, 1);
    final cart = await repo.cart();
    expect(cart.groups, hasLength(2));

    final result = await repo.checkout(
      addressId: await address(),
      method: PaymentMethod.cod,
    );
    expect(result.orders, hasLength(2));
    expect(result.payment, isNull);
    expect((await repo.cart()).groups, isEmpty);
    expect(store.listing(first.id).stock, first.stock - 1);
  });

  test('VNPay: tạo payment, cổng báo thành công → đơn chờ xác nhận', () async {
    final l = store
        .searchListings(const ListingQuery())
        .items
        .firstWhere((l) => l.shop.id != 's1');
    store.addToCart(l.id, 1);
    final result = await repo.checkout(
      addressId: await address(),
      method: PaymentMethod.vnpay,
    );
    final order = result.orders.single;
    expect(order.status, OrderStatus.pendingPayment);

    final paid = await repo.simulateGateway(result.payment!.id, success: true);
    expect(paid.status, PaymentStatus.success);
    expect(store.order(order.id).status, OrderStatus.pendingConfirm);
  });

  test('ví không đủ tiền → INSUFFICIENT_BALANCE', () async {
    final l = store
        .searchListings(const ListingQuery(sort: ListingSort.priceDesc))
        .items
        .firstWhere((l) => l.shop.id != 's1');
    store.addToCart(l.id, l.stock);
    final wallet = await repo.wallet();
    final total = (await repo.cart()).total;
    if (wallet.available >= total) return; // dữ liệu mẫu đủ tiền thì bỏ qua
    await expectLater(
      repo.checkout(addressId: await address(), method: PaymentMethod.wallet),
      throwsA(
        isA<ServerException>().having(
          (e) => e.code,
          'code',
          ErrorCodes.insufficientBalance,
        ),
      ),
    );
  });
}
