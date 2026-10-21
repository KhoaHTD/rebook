/// Mọi đường dẫn trong app. Không viết chuỗi path trực tiếp trong widget:
/// dùng `context.go(Routes.bookDetail(id))`.
abstract final class Routes {
  static const catalog = '/';
  static String bookDetail(String id) => '/books/$id';

  static const auctions = '/auctions';
  static String auctionRoom(String id) => '/auctions/$id';

  static const profile = '/profile';
  static const login = '/login';

  /// Cần đăng nhập. Chưa đăng nhập -> chuyển tới `/login?from=<path>`.
  static bool requiresAuth(String location) =>
      location.startsWith(profile) || location.startsWith('$auctions/');
}
