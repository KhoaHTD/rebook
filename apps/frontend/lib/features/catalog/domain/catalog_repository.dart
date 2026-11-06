import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/user.dart';

/// Dữ liệu trang Khám phá.
class HomeFeed {
  const HomeFeed({
    required this.featuredShops,
    required this.trending,
    required this.newArrivals,
    required this.liveSessions,
  });

  final List<ShopSummary> featuredShops;
  final List<Listing> trending;
  final List<Listing> newArrivals;

  /// Phiên đang LIVE — cột "Đấu giá trực tiếp".
  final List<AuctionSession> liveSessions;
}

/// Một kệ thể loại ở trang Mua sách: tối đa vài chục cuốn phổ biến nhất của một nhóm thể loại (gồm cả thể loại con)
/// và tổng số sách của nhóm ([total], để ghi "Xem tất cả N cuốn").
class CategoryShelf {
  const CategoryShelf({
    required this.category,
    required this.items,
    required this.total,
  });

  final Category category;
  final List<Listing> items;
  final int total;
}

/// Chợ sách giá cố định (SRS 4.1–4.3): duyệt, tìm, xem, thêm giỏ.
abstract interface class CatalogRepository {
  Future<HomeFeed> homeFeed();

  Future<Paged<Listing>> search(ListingQuery query, {int page = 0});

  /// Kệ theo thể loại cho trang Mua sách: mỗi nhóm thể loại cha có sách là một kệ, [perShelf] cuốn phổ biến nhất
  /// (nhiều lượt yêu thích nhất). Nhóm chưa có sách bị bỏ.
  Future<List<CategoryShelf>> categoryShelves({int perShelf = 10});

  Future<Listing> listing(String id);

  Future<Shop> shop(String id);

  Future<List<Review>> shopReviews(String shopId);

  Future<List<Category>> categories();

  Future<void> addToCart(String listingId, int quantity);

  /// Sách yêu thích của tôi, mới nhất trước (SRS 3, mở rộng).
  Future<List<Listing>> favorites();

  Future<void> setFavorite(String listingId, {required bool on});

  /// Trạng thái phiên đang chạy (thẻ "Phiên bạn đang xem").
  Future<SessionState> liveState(String sessionId);

  /// Mọi tin đang bán (các trang gộp lại) — để trang chủ tự xếp thành nhiều bố cục (danh mục, bảng xếp hạng, ấn bản…).
  Future<List<Listing>> allListings();

  /// Các phiên đấu giá (mọi trạng thái) — mục "Phiên đấu giá nổi bật" ở trang chủ.
  Future<List<AuctionSession>> auctionSessions();

  /// Các lô của một phiên — dải bìa trong thẻ phiên ở trang chủ.
  Future<List<Lot>> sessionLots(String sessionId);
}
