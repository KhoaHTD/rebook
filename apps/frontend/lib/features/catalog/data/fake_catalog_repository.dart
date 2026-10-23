import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository(this._store);

  final FakeStore _store;

  @override
  Future<HomeFeed> homeFeed() => fakeCall(() {
    final feed = _store.homeFeed();
    return HomeFeed(
      featuredShops: feed.shops,
      trending: feed.trending,
      newArrivals: feed.fresh,
      liveSessions: _store.listSessions(status: SessionStatus.live),
    );
  });

  @override
  Future<Paged<Listing>> search(ListingQuery query, {int page = 0}) =>
      fakeCall(() => _store.searchListings(query, page: page));

  @override
  Future<Listing> listing(String id) => fakeCall(() => _store.listing(id));

  @override
  Future<Shop> shop(String id) => fakeCall(() => _store.shop(id));

  @override
  Future<List<Review>> shopReviews(String shopId) =>
      fakeCall(() => _store.shopReviews(shopId));

  @override
  Future<List<Category>> categories() =>
      fakeCall(() => List.of(_store.categories));

  @override
  Future<void> addToCart(String listingId, int quantity) =>
      fakeCall(() => _store.addToCart(listingId, quantity));

  @override
  Future<SessionState> liveState(String sessionId) =>
      fakeCall(() => _store.sessionState(sessionId), ms: 60);

  @override
  Future<List<Listing>> allListings() => fakeCall(
    () => _store.searchListings(const ListingQuery(), size: 200).items,
  );

  @override
  Future<List<AuctionSession>> auctionSessions() =>
      fakeCall(() => _store.listSessions());

  @override
  Future<List<Lot>> sessionLots(String sessionId) =>
      fakeCall(() => _store.catalogue(sessionId).lots);
}
