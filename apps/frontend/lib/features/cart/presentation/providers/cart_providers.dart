import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/cart/data/cart_repository_provider.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

part 'cart_providers.g.dart';

/// Địa chỉ đang chọn ở bước thanh toán (ảnh hưởng phí ship).
@riverpod
class SelectedAddress extends _$SelectedAddress {
  @override
  String? build() => null;

  void select(String id) => state = id;
}

/// Giỏ hàng hiện tại; sửa số lượng / xoá ngay trong notifier.
@riverpod
class CartController extends _$CartController {
  @override
  Future<Cart> build() {
    ref.watchArea(DataArea.cart);
    if (ref.watch(currentUserProvider) == null) return Future.value(Cart.empty);
    final addressId = ref.watch(selectedAddressProvider);
    return ref.read(cartRepositoryProvider).cart(addressId: addressId);
  }

  Future<void> setQuantity(String itemId, int quantity) async {
    final repo = ref.read(cartRepositoryProvider);
    state = await AsyncValue.guard(
      () => quantity <= 0
          ? repo.removeItem(itemId)
          : repo.updateItem(itemId, quantity),
    );
  }
}

/// Các món giỏ đang BỎ chọn. Mặc định chọn hết; món mới thêm vào tự được chọn.
@Riverpod(keepAlive: true)
class CartExcluded extends _$CartExcluded {
  @override
  Set<String> build() => const {};

  void toggle(String itemId) {
    state = state.contains(itemId)
        ? (Set.of(state)..remove(itemId))
        : {...state, itemId};
  }

  /// Chọn / bỏ chọn một loạt món (cả shop hoặc cả giỏ).
  void setSelected(Iterable<String> itemIds, {required bool selected}) {
    state = selected
        ? state.difference(itemIds.toSet())
        : {...state, ...itemIds};
  }
}

/// Id các món đang được chọn để thanh toán.
@riverpod
List<String> selectedCartItemIds(Ref ref) {
  final cart = ref.watch(cartControllerProvider).value;
  final excluded = ref.watch(cartExcludedProvider);
  if (cart == null) return const [];
  return [
    for (final g in cart.groups)
      for (final i in g.items)
        if (!excluded.contains(i.id)) i.id,
  ];
}

/// Giỏ chỉ gồm các món đã chọn: tạm tính + phí ship tính lại theo khối lượng các món này.
@riverpod
Future<Cart> selectedCart(Ref ref) async {
  final all = await ref.watch(cartControllerProvider.future);
  final ids = ref.watch(selectedCartItemIdsProvider);
  final total = all.groups.fold(0, (n, g) => n + g.items.length);
  if (ids.isEmpty) return Cart.empty;
  if (ids.length == total) return all;
  return ref
      .read(cartRepositoryProvider)
      .cart(addressId: ref.watch(selectedAddressProvider), itemIds: ids);
}

/// Số cuốn trong giỏ (chấm đỏ trên icon giỏ).
@riverpod
int cartCount(Ref ref) =>
    ref.watch(cartControllerProvider).value?.itemCount ?? 0;

@riverpod
Future<List<Address>> checkoutAddresses(Ref ref) {
  ref.watchArea(DataArea.profile);
  return ref.watch(cartRepositoryProvider).addresses();
}

@riverpod
Future<Wallet> checkoutWallet(Ref ref) {
  ref.watchArea(DataArea.wallet);
  return ref.watch(cartRepositoryProvider).wallet();
}

/// Đặt hàng. Trả về kết quả (đơn đã tạo + phiên thanh toán nếu có).
@riverpod
class CheckoutController extends _$CheckoutController {
  @override
  FutureOr<CheckoutResult?> build() => null;

  Future<CheckoutResult?> placeOrder({
    required String addressId,
    required PaymentMethod method,
    List<String>? itemIds,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(cartRepositoryProvider)
          .checkout(addressId: addressId, method: method, itemIds: itemIds),
    );
    final changes = ref.read(dataChangesProvider.notifier);
    for (final area in [DataArea.cart, DataArea.orders, DataArea.wallet]) {
      changes.bump(area);
    }
    return state.value;
  }
}

@riverpod
Future<Payment> payment(Ref ref, String id) =>
    ref.watch(cartRepositoryProvider).payment(id);

/// Cổng VNPay giả lập (chỉ chế độ mock).
@riverpod
class GatewayController extends _$GatewayController {
  @override
  FutureOr<void> build() {}

  Future<void> pay(String paymentId, {required bool success}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(cartRepositoryProvider)
          .simulateGateway(paymentId, success: success),
    );
    ref.invalidate(paymentProvider(paymentId));
    final changes = ref.read(dataChangesProvider.notifier);
    for (final area in [DataArea.orders, DataArea.wallet]) {
      changes.bump(area);
    }
  }
}
