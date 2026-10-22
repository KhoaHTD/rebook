import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

/// Kênh người bán: shop, tin đăng, đơn của shop (SRS 4.1, 4.3, 4.4).
abstract interface class SellerRepository {
  /// null nếu chưa mở shop.
  Future<Shop?> myShop();

  Future<Shop> openShop(ShopDraft draft);

  Future<Shop> updateShop(ShopDraft draft);

  Future<SellerStats> stats();

  Future<List<Category>> categories();

  Future<List<Listing>> myListings({ListingStatus? status});

  Future<Listing> listing(String id);

  /// [id] null → đăng mới. Shop chưa đủ uy tín → chờ duyệt.
  Future<Listing> saveListing(
    String? id,
    BookDraft book, {
    required int price,
    required int stock,
  });

  Future<Listing> setVisible(String id, {required bool visible});

  Future<void> deleteListing(String id);

  Future<List<Order>> shopOrders({OrderStatus? status});

  Future<Order> shopOrder(String id);

  Future<Order> confirm(String id);

  Future<Order> ship(String id, {String? trackingCode});

  /// Đơn vị vận chuyển báo giao thành công (chế độ mock: nút giả lập).
  Future<Order> markDelivered(String id);

  Future<Order> cancel(String id, String reason);

  Future<Order> decideReturn(String id, {required bool accept, String? note});
}
