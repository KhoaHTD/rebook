import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/features/orders/data/fake_orders_repository.dart';
import 'package:book_marketplace/features/orders/presentation/providers/orders_providers.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

void main() {
  late FakeStore store;
  late FakeOrdersRepository repo;

  setUp(() {
    store = FakeStore()..login('khoa@rebook.vn', '123456');
    repo = FakeOrdersRepository(store);
  });
  tearDown(() => store.dispose());

  /// Đặt một đơn COD 1 cuốn, trả về id đơn.
  String placeCod() {
    final l = store.searchListings(const ListingQuery()).items.first;
    store.addToCart(l.id, 1);
    return store
        .checkout(
          addressId: store.myAddresses().first.id,
          method: PaymentMethod.cod,
        )
        .orders
        .single
        .id;
  }

  test('hủy đơn chưa xác nhận → Đã hủy, hoàn tồn kho', () async {
    final id = placeCod();
    final listingId = store.order(id).items.single.listingId!;
    final before = store.listing(listingId).stock;
    final o = await repo.cancel(id, 'Đổi ý');
    expect(o.status, OrderStatus.cancelled);
    expect(store.listing(listingId).stock, before + 1);
  });

  test('danh sách có đơn vừa đặt, thuộc nhóm chờ xử lý', () async {
    final id = placeCod();
    final o = (await repo.myOrders()).firstWhere((o) => o.id == id);
    expect(OrderFilter.toDo.matches(o.status), isTrue);
    expect(OrderFilter.done.matches(o.status), isFalse);
  });

  test('không xác nhận đã nhận được khi đơn chưa giao', () async {
    final id = placeCod();
    await expectLater(repo.confirmReceived(id), throwsA(anything));
  });

  test('thanh toán lại đơn chờ thanh toán bằng ví', () async {
    final l = store.searchListings(const ListingQuery()).items.first;
    store.addToCart(l.id, 1);
    final id = store
        .checkout(
          addressId: store.myAddresses().first.id,
          method: PaymentMethod.vnpay,
        )
        .orders
        .single
        .id;
    final wallet = store.walletOf(store.currentUserId!);
    if (wallet.available < store.order(id).total) return;
    final result = await repo.pay(id, PaymentMethod.wallet);
    expect(result.orders.single.status, OrderStatus.pendingConfirm);
  });
}
