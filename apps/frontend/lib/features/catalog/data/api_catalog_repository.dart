import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this._client);

  final api.RestClient _client;
  static const pageSize = 20;

  @override
  Future<HomeFeed> homeFeed() => guardApi(() async {
    final dto = await _client.listings.getHomeFeed();
    return HomeFeed(
      featuredShops: dto.featuredShops.map((e) => e.toDomain()).toList(),
      trending: dto.trending.map((e) => e.toDomain()).toList(),
      newArrivals: dto.newArrivals.map((e) => e.toDomain()).toList(),
      liveSessions: dto.liveSessions.map((e) => e.toDomain()).toList(),
    );
  });

  @override
  Future<Paged<Listing>> search(ListingQuery query, {int page = 0}) =>
      guardApi(() async {
        final dto = await _client.listings.searchListings(
          page: page,
          size: pageSize,
          q: query.q,
          categoryId: query.categoryId,
          author: query.author,
          condition: query.condition == null
              ? null
              : toApiEnum(api.ConditionGrade.values, query.condition!),
          minPrice: query.minPrice,
          maxPrice: query.maxPrice,
          shopId: query.shopId,
          sort: toApiEnum(api.ListingSort.values, query.sort),
        );
        return dto.toDomain();
      });

  @override
  Future<Listing> listing(String id) => guardApi(
    () async => (await _client.listings.getListing(id: id)).toDomain(),
  );

  @override
  Future<Shop> shop(String id) =>
      guardApi(() async => (await _client.shops.getShop(id: id)).toDomain());

  @override
  Future<List<Review>> shopReviews(String shopId) => guardApi(() async {
    final page = await _client.shops.listShopReviews(id: shopId);
    return page.items.map((e) => e.toDomain()).toList();
  });

  @override
  Future<List<Category>> categories() => guardApi(() async {
    final list = await _client.categories.listCategories();
    return list.map((e) => e.toDomain()).toList();
  });

  @override
  Future<void> addToCart(String listingId, int quantity) => guardApi(
    () => _client.cart.addCartItem(
      body: api.AddCartItemRequest(listingId: listingId, quantity: quantity),
    ),
  );

  @override
  Future<SessionState> liveState(String sessionId) => guardApi(
    () async =>
        (await _client.auctions.getSessionState(id: sessionId)).toDomain(),
  );
}
