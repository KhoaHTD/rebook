import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/catalog/data/catalog_repository_provider.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/favorites_providers.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/features/catalog/domain/explore_event.dart';
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

/// Mọi tin đang bán — trang chủ tự nhóm thành danh mục, bảng xếp hạng, ấn bản…
@riverpod
Future<List<Listing>> allListings(Ref ref) {
  ref.watchArea(DataArea.listings);
  return ref.watch(catalogRepositoryProvider).allListings();
}

/// Sự kiện ở đầu trang Khám phá: dựng từ các tin đang bán.
@riverpod
Future<List<ExploreEvent>> exploreEvents(Ref ref) async {
  final listings = await ref.watch(allListingsProvider.future);
  final categories = await ref.watch(categoriesProvider.future);
  // "Dành cho bạn" cần sách yêu thích; chưa đăng nhập thì rỗng.
  final favorites = await ref.watch(favoriteListingsProvider.future);
  return buildExploreEvents(
    listings,
    categories: categories,
    favorites: favorites,
  );
}

/// Số sách đang bán của từng thể loại (cha = tổng của chính nó và các con), để ghi "N cuốn" ở bảng chọn thể loại.
@riverpod
Future<Map<String, int>> categoryCounts(Ref ref) async {
  final listings = await ref.watch(allListingsProvider.future);
  final cats = await ref.watch(categoriesProvider.future);
  final parentOf = {for (final c in cats) c.id: c.parentId};
  final counts = <String, int>{};
  for (final l in listings) {
    final id = l.book.categoryId;
    if (id == null) continue;
    counts[id] = (counts[id] ?? 0) + 1;
    final parent = parentOf[id];
    if (parent != null) counts[parent] = (counts[parent] ?? 0) + 1;
  }
  return counts;
}

@riverpod
Future<List<AuctionSession>> homeSessions(Ref ref) {
  ref.watchArea(DataArea.auctions);
  return ref.watch(catalogRepositoryProvider).auctionSessions();
}

@riverpod
Future<List<Lot>> sessionLots(Ref ref, String sessionId) {
  ref.watchArea(DataArea.auctions);
  return ref.watch(catalogRepositoryProvider).sessionLots(sessionId);
}

/// Kệ thể loại ở trang Mua sách (10 cuốn phổ biến nhất mỗi nhóm); đổi yêu thích thì tải lại để thứ tự theo kịp.
@riverpod
Future<List<CategoryShelf>> categoryShelves(Ref ref) {
  ref
    ..watchArea(DataArea.favorites)
    ..watchArea(DataArea.listings);
  return ref.watch(catalogRepositoryProvider).categoryShelves();
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
