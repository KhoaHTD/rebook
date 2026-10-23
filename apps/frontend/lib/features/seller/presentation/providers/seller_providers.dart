import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/seller/data/seller_repository_provider.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/user.dart';

part 'seller_providers.g.dart';

@riverpod
Future<Shop?> myShop(Ref ref) {
  ref.watchArea(DataArea.profile);
  return ref.watch(sellerRepositoryProvider).myShop();
}

@riverpod
Future<SellerStats> sellerStats(Ref ref) {
  ref
    ..watchArea(DataArea.orders)
    ..watchArea(DataArea.listings)
    ..watchArea(DataArea.wallet);
  return ref.watch(sellerRepositoryProvider).stats();
}

@riverpod
Future<List<Category>> sellerCategories(Ref ref) =>
    ref.watch(sellerRepositoryProvider).categories();

@riverpod
Future<List<Listing>> sellerListings(Ref ref) {
  ref.watchArea(DataArea.listings);
  return ref.watch(sellerRepositoryProvider).myListings();
}

@riverpod
Future<Listing> sellerListing(Ref ref, String id) =>
    ref.watch(sellerRepositoryProvider).listing(id);

@riverpod
Future<List<Order>> shopOrders(Ref ref) {
  ref.watchArea(DataArea.orders);
  return ref.watch(sellerRepositoryProvider).shopOrders();
}

@riverpod
Future<Order> shopOrder(Ref ref, String id) {
  ref.watchArea(DataArea.orders);
  return ref.watch(sellerRepositoryProvider).shopOrder(id);
}

/// Mọi thao tác ghi của người bán.
@riverpod
class SellerActions extends _$SellerActions {
  @override
  FutureOr<void> build() {}

  Future<T?> _run<T>(Future<T> Function() action, List<String> areas) async {
    state = const AsyncLoading();
    T? result;
    state = await AsyncValue.guard(() async {
      result = await action();
    });
    if (!state.hasError) {
      final changes = ref.read(dataChangesProvider.notifier);
      for (final a in areas) {
        changes.bump(a);
      }
    }
    return result;
  }

  Future<Shop?> openShop(ShopDraft draft) => _run(() async {
    final shop = await ref.read(sellerRepositoryProvider).openShop(draft);
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref
          .read(sessionControllerProvider.notifier)
          .updateUser(user.copyWith(hasShop: true));
    }
    return shop;
  }, [DataArea.profile]);

  Future<Shop?> updateShop(ShopDraft draft) => _run(
    () => ref.read(sellerRepositoryProvider).updateShop(draft),
    [DataArea.profile],
  );

  Future<Listing?> saveListing(
    String? id,
    BookDraft book, {
    required int price,
    required int stock,
  }) => _run(
    () => ref
        .read(sellerRepositoryProvider)
        .saveListing(id, book, price: price, stock: stock),
    [DataArea.listings],
  );

  Future<Listing?> setVisible(String id, {required bool visible}) => _run(
    () => ref.read(sellerRepositoryProvider).setVisible(id, visible: visible),
    [DataArea.listings],
  );

  Future<bool> deleteListing(String id) async {
    await _run(() => ref.read(sellerRepositoryProvider).deleteListing(id), [
      DataArea.listings,
    ]);
    return !state.hasError;
  }

  Future<Order?> confirm(String id) => _run(
    () => ref.read(sellerRepositoryProvider).confirm(id),
    [DataArea.orders],
  );

  Future<Order?> ship(String id, {String? trackingCode}) => _run(
    () =>
        ref.read(sellerRepositoryProvider).ship(id, trackingCode: trackingCode),
    [DataArea.orders],
  );

  Future<Order?> markDelivered(String id) => _run(
    () => ref.read(sellerRepositoryProvider).markDelivered(id),
    [DataArea.orders],
  );

  Future<Order?> cancel(String id, String reason) => _run(
    () => ref.read(sellerRepositoryProvider).cancel(id, reason),
    [DataArea.orders, DataArea.wallet, DataArea.listings],
  );

  Future<Order?> decideReturn(
    String id, {
    required bool accept,
    String? note,
  }) => _run(
    () => ref
        .read(sellerRepositoryProvider)
        .decideReturn(id, accept: accept, note: note),
    [DataArea.orders, DataArea.wallet],
  );
}
