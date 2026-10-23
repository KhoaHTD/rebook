import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/orders/data/orders_repository_provider.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

part 'orders_providers.g.dart';

/// Nhóm lọc trên trang Đơn mua.
enum OrderFilter {
  all,
  toDo,
  inTransit,
  delivered,
  done,
  cancelled;

  bool matches(OrderStatus s) => switch (this) {
    all => true,
    toDo => s == OrderStatus.pendingPayment || s == OrderStatus.pendingConfirm,
    inTransit => s == OrderStatus.preparing || s == OrderStatus.shipping,
    delivered => s == OrderStatus.delivered || s == OrderStatus.returnRequested,
    done => s == OrderStatus.completed,
    cancelled =>
      s == OrderStatus.cancelled ||
          s == OrderStatus.returned ||
          s == OrderStatus.failedDelivery,
  };
}

@riverpod
Future<List<Order>> myOrders(Ref ref) {
  ref.watchArea(DataArea.orders);
  return ref.watch(ordersRepositoryProvider).myOrders();
}

@riverpod
Future<Order> orderDetail(Ref ref, String id) {
  ref.watchArea(DataArea.orders);
  return ref.watch(ordersRepositoryProvider).order(id);
}

@riverpod
Future<List<Address>> orderAddresses(Ref ref) {
  ref.watchArea(DataArea.profile);
  return ref.watch(ordersRepositoryProvider).addresses();
}

@riverpod
Future<Wallet> orderWallet(Ref ref) {
  ref.watchArea(DataArea.wallet);
  return ref.watch(ordersRepositoryProvider).wallet();
}

/// Mọi thao tác trên một đơn. Thành công → báo vùng orders/wallet đổi.
@riverpod
class OrderActions extends _$OrderActions {
  @override
  FutureOr<void> build(String orderId) {}

  Future<T?> _run<T>(Future<T> Function() action) async {
    state = const AsyncLoading();
    T? result;
    state = await AsyncValue.guard(() async {
      result = await action();
    });
    if (!state.hasError) {
      final changes = ref.read(dataChangesProvider.notifier);
      for (final area in [DataArea.orders, DataArea.wallet]) {
        changes.bump(area);
      }
    }
    return result;
  }

  Future<Order?> cancel(String reason) =>
      _run(() => ref.read(ordersRepositoryProvider).cancel(orderId, reason));

  Future<Order?> confirmReceived() =>
      _run(() => ref.read(ordersRepositoryProvider).confirmReceived(orderId));

  Future<Order?> requestReturn(String reason, List<String> images) => _run(
    () => ref
        .read(ordersRepositoryProvider)
        .requestReturn(orderId, reason, images),
  );

  Future<Order?> review(int rating, String? comment) => _run(
    () => ref.read(ordersRepositoryProvider).review(orderId, rating, comment),
  );

  Future<CheckoutResult?> pay(
    PaymentMethod method, {
    String? addressId,
    bool pickup = false,
  }) => _run(
    () => ref
        .read(ordersRepositoryProvider)
        .pay(orderId, method, addressId: addressId, pickupAtWarehouse: pickup),
  );
}
