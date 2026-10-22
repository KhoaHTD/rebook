/// Mọi đường dẫn trong app. Không viết chuỗi path trực tiếp trong widget:
/// dùng `context.go(Routes.bookDetail(id))`.
abstract final class Routes {
  static const home = '/';
  static String bookDetail(String id) => '/books/$id';

  /// Tìm kiếm toàn màn hình (ô tìm kiếm dưới đáy). `channel`: all | buy | auction.
  static const search = '/search';

  /// Sheet đăng bán sách.
  static const sell = '/sell';

  static const auctions = '/auctions';

  /// Catalogue một lô: báo cáo kiểm định, giá ước tính, đăng ký.
  static String lot(String id) => '/lots/$id';

  /// Phòng đấu giá trực tiếp của lô.
  static String auctionRoom(String id) => '/lots/$id/live';

  static const profile = '/profile';
  static const login = '/login';

  /// Cần đăng nhập. Chưa đăng nhập -> chuyển tới `/login?from=<path>`.
  static bool requiresAuth(String location) =>
      location.startsWith(profile) ||
      location.startsWith(sell) ||
      (location.startsWith('/lots/') && location.endsWith('/live'));
}
