import 'package:book_marketplace/features/seller/domain/seller_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class FakeSellerRepository implements SellerRepository {
  FakeSellerRepository(this._store);

  final FakeStore _store;

  @override
  Future<Shop?> myShop() => fakeCall(_store.myShop);

  @override
  Future<Shop> openShop(ShopDraft draft) =>
      fakeCall(() => _store.openShop(draft), ms: 500);

  @override
  Future<Shop> updateShop(ShopDraft draft) =>
      fakeCall(() => _store.updateShop(draft));

  @override
  Future<SellerStats> stats() => fakeCall(_store.sellerStats);

  @override
  Future<List<Category>> categories() =>
      fakeCall(() => List.of(_store.categories));

  @override
  Future<List<Listing>> myListings({ListingStatus? status}) =>
      fakeCall(() => _store.myListings(status: status).items);

  @override
  Future<Listing> listing(String id) => fakeCall(() => _store.listing(id));

  @override
  Future<Listing> saveListing(
    String? id,
    BookDraft book, {
    required int price,
    required int stock,
  }) => fakeCall(() => _store.saveListing(id, book, price, stock), ms: 500);

  @override
  Future<Listing> setVisible(String id, {required bool visible}) =>
      fakeCall(() => _store.setListingVisible(id, visible: visible));

  @override
  Future<void> deleteListing(String id) =>
      fakeCall(() => _store.deleteListing(id));

  @override
  Future<List<Order>> shopOrders({OrderStatus? status}) =>
      fakeCall(() => _store.shopOrders(status: status).items);

  @override
  Future<Order> shopOrder(String id) => fakeCall(() => _store.order(id));

  @override
  Future<Order> confirm(String id) => fakeCall(() => _store.sellerConfirm(id));

  @override
  Future<Order> ship(String id, {String? trackingCode}) =>
      fakeCall(() => _store.sellerShip(id, trackingCode));

  @override
  Future<Order> markDelivered(String id) =>
      fakeCall(() => _store.markDelivered(id));

  @override
  Future<Order> cancel(String id, String reason) =>
      fakeCall(() => _store.sellerCancel(id, reason));

  @override
  Future<Order> decideReturn(String id, {required bool accept, String? note}) =>
      fakeCall(() => _store.decideReturn(id, accept: accept, note: note));
}
