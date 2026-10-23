import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/data/session_loader.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this._client);

  final api.RestClient _client;

  static const _pageSize = 20;

  /// Backend không có endpoint "trang chủ": ghép từ danh sách tin (mới nhất,
  /// bán chạy) và các phiên đang diễn ra. Shop nổi bật = shop có đánh giá cao
  /// nhất trong số tin vừa lấy.
  @override
  Future<HomeFeed> homeFeed() => guardApi(() async {
    final results = await Future.wait([
      _client.catalog.getListings(sort: 'newest', size: 12),
      _client.catalog.getListings(sort: 'best_selling', size: 12),
      _client.auction.getSessions(status: api.SessionStatus.live, size: 10),
    ]);
    final newest = (results[0] as api.PageResponseListingSummary).items;
    final trending = (results[1] as api.PageResponseListingSummary).items;
    final live = (results[2] as api.PageResponseSessionSummary).items;

    final shops = <String, ShopSummary>{};
    for (final l in [...?newest, ...?trending]) {
      final s = l.shop?.toDomain();
      if (s != null && s.id.isNotEmpty) shops[s.id] = s;
    }
    final featured = shops.values.toList()
      ..sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));

    return HomeFeed(
      featuredShops: featured.take(6).toList(),
      trending: [for (final l in trending.orEmpty) l.toDomain()],
      newArrivals: [for (final l in newest.orEmpty) l.toDomain()],
      liveSessions: [for (final s in live.orEmpty) s.toDomain()],
    );
  });

  @override
  Future<Paged<Listing>> search(ListingQuery query, {int page = 0}) =>
      guardApi(() async {
        final res = await _client.catalog.getListings(
          q: query.q,
          category: int.tryParse(query.categoryId ?? ''),
          author: query.author,
          condition: query.condition == null
              ? null
              : conditionToApi(query.condition!),
          minPrice: query.minPrice,
          maxPrice: query.maxPrice,
          shopId: int.tryParse(query.shopId ?? ''),
          sort: switch (query.sort) {
            ListingSort.priceAsc => 'price_asc',
            ListingSort.priceDesc => 'price_desc',
            ListingSort.relevance => 'best_selling',
            ListingSort.newest => 'newest',
          },
          page: page,
          size: _pageSize,
        );
        return pagedOf(
          items: res.items,
          page: res.page,
          size: res.size,
          totalItems: res.totalItems,
          map: (api.ListingSummary e) => e.toDomain(),
        );
      });

  @override
  Future<Listing> listing(String id) => guardApi(
    () async => (await _client.catalog.getListingsId(id: apiId(id))).toDomain(),
  );

  @override
  Future<Shop> shop(String id) => guardApi(
    () async => (await _client.user.getShopsId(id: apiId(id))).toDomain(),
  );

  @override
  Future<List<Review>> shopReviews(String shopId) => guardApi(() async {
    final res = await _client.order.getShopsShopIdReviews(
      shopId: apiId(shopId),
      size: 50,
    );
    return [for (final r in res.items.orEmpty) r.toDomain()];
  });

  @override
  Future<List<Category>> categories() => guardApi(
    () async => flattenCategories(await _client.catalog.getCategories()),
  );

  @override
  Future<void> addToCart(String listingId, int quantity) => guardApi(
    () => _client.order.postCart(
      body: api.AddCartRequest(listingId: apiId(listingId), quantity: quantity),
    ),
  );

  @override
  Future<SessionState> liveState(String sessionId) =>
      guardApi(() => loadSessionState(_client, sessionId));

  @override
  Future<List<Listing>> allListings() => guardApi(() async {
    final res = await _client.catalog.getListings(size: 100);
    return [for (final l in res.items.orEmpty) l.toDomain()];
  });

  @override
  Future<List<AuctionSession>> auctionSessions() => guardApi(() async {
    final res = await _client.auction.getSessions(size: 100);
    return [for (final s in res.items.orEmpty) s.toDomain()];
  });

  @override
  Future<List<Lot>> sessionLots(String sessionId) => guardApi(
    () async =>
        (await _client.auction.getSessionsId(id: apiId(sessionId)))
            .lotsToDomain(),
  );
}
