import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/catalog/data/catalog_repository_provider.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

part 'catalog_providers.g.dart';

@riverpod
Future<HomeFeed> homeFeed(Ref ref) {
  ref.watchArea(DataArea.listings);
  return ref.watch(catalogRepositoryProvider).homeFeed();
}

@riverpod
Future<List<Category>> categories(Ref ref) =>
    ref.watch(catalogRepositoryProvider).categories();

@riverpod
Future<Listing> listing(Ref ref, String id) =>
    ref.watch(catalogRepositoryProvider).listing(id);

@riverpod
Future<Shop> shop(Ref ref, String id) =>
    ref.watch(catalogRepositoryProvider).shop(id);

@riverpod
Future<List<Review>> shopReviews(Ref ref, String shopId) =>
    ref.watch(catalogRepositoryProvider).shopReviews(shopId);

/// Trạng thái phiên đang chạy, tự làm mới mỗi 2 giây (thẻ "Phiên bạn đang xem").
@riverpod
Future<SessionState> liveState(Ref ref, String sessionId) async {
  final timer = Timer(const Duration(seconds: 2), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return ref.watch(catalogRepositoryProvider).liveState(sessionId);
}

/// Bộ lọc tìm kiếm hiện tại. [shopId] để dùng chung cho trang shop.
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  ListingQuery build(String? shopId) => ListingQuery(shopId: shopId);

  void update(ListingQuery query) =>
      state = query.copyWith(shopId: state.shopId);

  void setText(String text) =>
      state = state.copyWith(q: text.trim().isEmpty ? null : text.trim());
}

/// Kết quả tìm kiếm có phân trang; [loadMore] nối trang tiếp theo.
@riverpod
class SearchResults extends _$SearchResults {
  @override
  Future<Paged<Listing>> build(String? shopId) {
    final query = ref.watch(searchQueryProvider(shopId));
    return ref.watch(catalogRepositoryProvider).search(query);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || state.isLoading) return;
    final query = ref.read(searchQueryProvider(shopId));
    final next = await ref
        .read(catalogRepositoryProvider)
        .search(query, page: current.page + 1);
    state = AsyncData(
      Paged(
        items: [...current.items, ...next.items],
        page: next.page,
        size: next.size,
        total: next.total,
      ),
    );
  }
}

/// Thêm vào giỏ (có trạng thái đang xử lý / lỗi).
@riverpod
class AddToCartController extends _$AddToCartController {
  @override
  FutureOr<void> build() {}

  Future<bool> add(String listingId, {int quantity = 1}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(catalogRepositoryProvider).addToCart(listingId, quantity),
    );
    if (!state.hasError) {
      ref.read(dataChangesProvider.notifier).bump(DataArea.cart);
    }
    return !state.hasError;
  }
}

/// Các bản khác của cùng một cuốn (cùng tên sách) đang bán ở shop khác — trang chi tiết
/// cho người mua so sánh tình trạng và giá giữa nhiều người bán.
@riverpod
Future<List<Listing>> otherOffers(Ref ref, String listingId) async {
  ref.watchArea(DataArea.listings);
  final repo = ref.watch(catalogRepositoryProvider);
  final current = await ref.watch(listingProvider(listingId).future);
  final found = await repo.search(
    ListingQuery(q: current.book.title, sort: ListingSort.priceAsc),
  );
  final title = current.book.title.toLowerCase();
  return [
    for (final l in found.items)
      if (l.id != listingId &&
          l.book.title.toLowerCase() == title &&
          l.purchasable)
        l,
  ];
}
