import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/seller/domain/seller_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class ApiSellerRepository implements SellerRepository {
  ApiSellerRepository(this._client);

  final api.RestClient _client;

  @override
  Future<Shop?> myShop() async {
    try {
      return await guardApi(
        () async => (await _client.shops.getMyShop()).toDomain(),
      );
    } on ServerException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Shop> openShop(ShopDraft draft) => guardApi(
    () async =>
        (await _client.shops.openShop(body: draft.toRequest())).toDomain(),
  );

  @override
  Future<Shop> updateShop(ShopDraft draft) => guardApi(
    () async =>
        (await _client.shops.updateMyShop(body: draft.toRequest())).toDomain(),
  );

  @override
  Future<SellerStats> stats() =>
      guardApi(() async => (await _client.shops.getMyShopStats()).toDomain());

  @override
  Future<List<Category>> categories() => guardApi(
    () async => (await _client.categories.listCategories())
        .map((e) => e.toDomain())
        .toList(),
  );

  @override
  Future<List<Listing>> myListings({ListingStatus? status}) =>
      guardApi(() async {
        final page = await _client.sellerListings.listMyListings(
          size: 100,
          status: status == null
              ? null
              : toApiEnum(api.ListingStatus.values, status),
        );
        return page.toDomain().items;
      });

  @override
  Future<Listing> listing(String id) => guardApi(
    () async => (await _client.listings.getListing(id: id)).toDomain(),
  );

  @override
  Future<Listing> saveListing(
    String? id,
    BookDraft book, {
    required int price,
    required int stock,
  }) => guardApi(() async {
    final body = api.ListingRequest(
      book: book.toRequest(),
      price: price,
      stock: stock,
    );
    final dto = id == null
        ? await _client.sellerListings.createListing(body: body)
        : await _client.sellerListings.updateListing(id: id, body: body);
    return dto.toDomain();
  });

  @override
  Future<Listing> setVisible(String id, {required bool visible}) => guardApi(
    () async => (await _client.sellerListings.setListingVisibility(
      id: id,
      body: api.VisibilityRequest(visible: visible),
    )).toDomain(),
  );

  @override
  Future<void> deleteListing(String id) =>
      guardApi(() => _client.sellerListings.deleteListing(id: id));

  @override
  Future<List<Order>> shopOrders({OrderStatus? status}) => guardApi(() async {
    final page = await _client.sellerOrders.listShopOrders(
      size: 100,
      status: status == null ? null : toApiEnum(api.OrderStatus.values, status),
    );
    return page.toDomain().items;
  });

  /// Spec chưa có GET một đơn của shop: lấy từ danh sách.
  @override
  Future<Order> shopOrder(String id) async {
    final list = await shopOrders();
    return list.firstWhere(
      (o) => o.id == id,
      orElse: () => throw const ServerException(404, code: ErrorCodes.notFound),
    );
  }

  @override
  Future<Order> confirm(String id) => guardApi(
    () async =>
        (await _client.sellerOrders.confirmShopOrder(id: id)).toDomain(),
  );

  @override
  Future<Order> ship(String id, {String? trackingCode}) => guardApi(
    () async => (await _client.sellerOrders.shipShopOrder(
      id: id,
      body: api.ShipRequest(trackingCode: trackingCode),
    )).toDomain(),
  );

  @override
  Future<Order> markDelivered(String id) => guardApi(
    () async =>
        (await _client.sellerOrders.markShopOrderDelivered(id: id)).toDomain(),
  );

  @override
  Future<Order> cancel(String id, String reason) => guardApi(
    () async => (await _client.sellerOrders.cancelShopOrder(
      id: id,
      body: api.ReasonRequest(reason: reason),
    )).toDomain(),
  );

  @override
  Future<Order> decideReturn(String id, {required bool accept, String? note}) =>
      guardApi(
        () async => (await _client.sellerOrders.decideReturn(
          id: id,
          body: api.ReturnDecisionRequest(accept: accept, note: note),
        )).toDomain(),
      );
}
