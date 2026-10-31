/// Mọi đường dẫn trong app người dùng. Không viết chuỗi path trực tiếp trong widget:
/// dùng `context.go(Routes.listing(id))`.
abstract final class Routes {
  /// Web: trang giới thiệu. Mobile: chuyển thẳng tới [home].
  static const landing = '/';

  // Đăng nhập
  static const login = '/login';
  static const register = '/register';
  static const verifyOtp = '/verify-otp';
  static const forgotPassword = '/forgot-password';

  // Nhánh 1 — Khám phá & mua
  static const home = '/home';
  static const search = '/home/search';
  static String listing(String id) => '/home/listings/$id';
  static String shop(String id) => '/home/shops/$id';
  static const cart = '/home/cart';
  static const checkout = '/home/cart/checkout';
  static String paymentResult(String id) => '/home/payments/$id';

  // Nhánh 2 — Đấu giá
  static const auctions = '/auctions';
  static String session(String id) => '/auctions/sessions/$id';
  static String sessionRegister(String id) => '/auctions/sessions/$id/register';
  static String live(String id) => '/auctions/sessions/$id/live';
  static String results(String id) => '/auctions/sessions/$id/results';
  static String lot(String id) => '/auctions/lots/$id';
  static const myAuctions = '/auctions/mine';
  static const auctionSchedule = '/auctions/schedule';
  static const auctionResults = '/auctions/results';
  static const auctionAccount = '/auctions/account';
  static const auctionWallet = '/auctions/account/wallet';
  static const auctionOrders = '/auctions/account/orders';
  static String auctionOrder(String id) => '/auctions/account/orders/$id';
  static const auctionBids = '/auctions/account/bids';
  static const auctionOffers = '/auctions/account/offers';

  // Nhánh 3 — Thông báo
  static const notifications = '/notifications';

  // Nhánh 4 — Tài khoản
  static const account = '/account';
  static const profile = '/account/profile';
  static const addresses = '/account/addresses';
  static const favorites = '/account/favorites';
  static const settings = '/account/settings';
  static const orders = '/account/orders';
  static String order(String id) => '/account/orders/$id';
  static const wallet = '/account/wallet';

  // Người bán (vẫn thuộc nhánh tài khoản)
  static const openShop = '/account/seller/open';
  static const seller = '/account/seller';
  static const sellerListings = '/account/seller/listings';
  static const newListing = '/account/seller/listings/new';
  static String editListing(String id) => '/account/seller/listings/$id';
  static const sellerOrders = '/account/seller/orders';
  static String sellerOrder(String id) => '/account/seller/orders/$id';
  static const consignments = '/account/consignments';
  static const newConsignment = '/account/consignments/new';
  static String consignment(String id) => '/account/consignments/$id';

  static const _authPaths = [login, register, verifyOtp, forgotPassword];
  static bool isAuthPage(String location) => _authPaths.contains(location);

  /// Cần đăng nhập. Chưa đăng nhập → `/login?from=<path>`.
  static bool requiresAuth(String location) =>
      location.startsWith(account) ||
      location.startsWith(notifications) ||
      location.startsWith(cart) ||
      location.startsWith('/home/payments') ||
      location == myAuctions ||
      location.startsWith(auctionAccount) ||
      location.endsWith('/register');
  // Phòng `/live` mở cho khách xem (SRS 2: khách xem trực tiếp phiên, không được trả giá).
}

/// Đường dẫn của web quản trị (main_admin.dart).
abstract final class AdminRoutes {
  static const login = '/login';
  static const dashboard = '/';
  static const consignments = '/consignments';
  static String consignment(String id) => '/consignments/$id';
  static const appointments = '/appointments';
  static const warehouse = '/warehouse';
  static const auctionOrders = '/auction-orders';
  static const sessions = '/sessions';
  static const newSession = '/sessions/new';
  static String session(String id) => '/sessions/$id';
  static String monitor(String id) => '/sessions/$id/monitor';
  static const listings = '/listings';
  static const users = '/users';
  static const categories = '/categories';
  static const config = '/config';
  static const withdrawals = '/withdrawals';
  static const disputes = '/disputes';
  static const activity = '/activity';
}
