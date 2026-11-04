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
        () async => (await _client.user.getMeShop()).toDomain(),
      );
    } on ServerException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Shop> openShop(ShopDraft draft) => guardApi(
    () async =>
        (await _client.user.putMeShop(body: draft.toRequest())).toDomain(),
  );

  @override
  Future<Shop> updateShop(ShopDraft draft) => openShop(draft);

  /// Backend không có API thống kê người bán: tính từ danh sách đơn và tin đăng.
  @override
  Future<SellerStats> stats() => guardApi(() async {
    final orders =
        (await _client.orderManagement.getSellerOrders(size: 200)).items ??
        const <api.OrderSummary>[];
    final active = await _client.catalog.getSellerListings(
      status: api.ListingStatus.active,
      size: 1,
    );
    final shop = await _client.user.getMeShop();

    final now = DateTime.now();
    int total(Iterable<api.OrderSummary> it) =>
        it.fold(0, (n, o) => n + (o.total?.round() ?? 0));
    final completed = orders
        .where((o) => o.status == api.OrderStatus.completed)
        .toList();
    final thisMonth = completed.where((o) {
      final at = o.createdAt?.toLocal();
      return at != null && at.year == now.year && at.month == now.month;
    });
    const inFlight = {
      api.OrderStatus.preparing,
      api.OrderStatus.shipping,
      api.OrderStatus.delivered,
    };
    return SellerStats(
      revenueTotal: total(completed),
      revenueThisMonth: total(thisMonth),
      pendingBalance: total(orders.where((o) => inFlight.contains(o.status))),
      ordersToConfirm: orders
          .where((o) => o.status == api.OrderStatus.pendingConfirm)
          .length,
      ordersShipping: orders
          .where((o) => o.status == api.OrderStatus.shipping)
          .length,
      ordersCompleted: completed.length,
      activeListings: active.totalItems ?? 0,
      ratingAvg: shop.ratingAvg?.toDouble() ?? 0,
    );
  });

  @override
  Future<List<Category>> categories() => guardApi(
    () async => flattenCategories(await _client.catalog.getCategories()),
  );

  @override
  Future<List<Listing>> myListings({ListingStatus? status}) =>
      guardApi(() async {
        final res = await _client.catalog.getSellerListings(
          status: status == null ? null : listingStatusToApi(status),
          size: 100,
        );
        return [for (final l in res.items.orEmpty) l.toDomain()];
      });

  /// Chi tiết công khai chỉ có tin đang bán; tin chờ duyệt / ẩn lấy từ danh sách của shop.
  @override
  Future<Listing> listing(String id) => guardApi(() async {
    try {
      return (await _client.catalog.getListingsId(id: apiId(id))).toDomain();
    } on Object {
      final mine = await _client.catalog.getSellerListings(size: 100);
      final found = (mine.items.orEmpty)
          .where((l) => '${l.id}' == id)
          .firstOrNull;
      if (found == null) {
        throw const ServerException(404, code: ErrorCodes.notFound);
      }
      return found.toDomain();
    }
  });

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
    final saved = id == null
        ? await _client.catalog.postSellerListings(body: body)
        : await _client.catalog.putSellerListingsId(id: apiId(id), body: body);
    return saved.toDomain();
  });

  @override
  Future<Listing> setVisible(String id, {required bool visible}) =>
      guardApi(() async {
        final listingId = apiId(id);
        final res = visible
            ? await _client.catalog.postSellerListingsIdShow(id: listingId)
            : await _client.catalog.deleteSellerListingsId(id: listingId);
        return res.toDomain();
      });

  /// Backend không xoá hẳn tin đăng: "xoá" = ẩn (giữ lịch sử đơn hàng).
  @override
  Future<void> deleteListing(String id) => guardApi(
    () async => _client.catalog.deleteSellerListingsId(id: apiId(id)),
  );

  @override
  Future<List<Order>> shopOrders({OrderStatus? status}) => guardApi(() async {
    final res = await _client.orderManagement.getSellerOrders(
      status: status == null ? null : orderStatusToApi(status),
      size: 100,
    );
    return [for (final o in res.items.orEmpty) o.toDomain()];
  });

  @override
  Future<Order> shopOrder(String id) => guardApi(
    () async => (await _client.order.getOrdersId(id: apiId(id))).toDomain(),
  );

  @override
  Future<Order> confirm(String id) => guardApi(
    () async =>
        (await _client.orderManagement.postSellerOrdersIdConfirm(id: apiId(id)))
            .toDomain(),
  );

  @override
  Future<Order> ship(String id, {String? trackingCode}) => guardApi(
    () async => (await _client.orderManagement.postSellerOrdersIdShip(
      id: apiId(id),
      body: api.ShipRequest(trackingCode: trackingCode),
    )).toDomain(),
  );

  @override
  Future<Order> markDelivered(String id) => guardApi(
    () async => (await _client.orderManagement.postSellerOrdersIdDelivered(
      id: apiId(id),
    )).toDomain(),
  );

  @override
  Future<Order> cancel(String id, String reason) => guardApi(
    () async => (await _client.orderManagement.postSellerOrdersIdCancel(
      id: apiId(id),
      body: api.ReasonRequest(reason: reason),
    )).toDomain(),
  );

  @override
  Future<Order> decideReturn(String id, {required bool accept, String? note}) =>
      guardApi(
        () async =>
            (await _client.orderManagement.postSellerOrdersIdReturnDecision(
              id: apiId(id),
              body: api.DecisionRequest(approve: accept, note: note),
            )).toDomain(),
      );
}
