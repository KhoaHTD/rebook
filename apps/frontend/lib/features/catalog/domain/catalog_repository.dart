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

/// Chợ sách giá cố định (SRS 4.1–4.3): duyệt, tìm, xem, thêm giỏ.
abstract interface class CatalogRepository {
  Future<HomeFeed> homeFeed();

  Future<Paged<Listing>> search(ListingQuery query, {int page = 0});

  Future<Listing> listing(String id);

  Future<Shop> shop(String id);

  Future<List<Review>> shopReviews(String shopId);

  Future<List<Category>> categories();

  Future<void> addToCart(String listingId, int quantity);

  /// Trạng thái phiên đang chạy (thẻ "Phiên bạn đang xem").
  Future<SessionState> liveState(String sessionId);
}
