import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/router/routes.dart';

void main() {
  group('Routes.requiresAuth (chế độ khách)', () {
    test('khách xem sách, tìm kiếm, đấu giá, gốc tài khoản và cài đặt', () {
      for (final path in [
        Routes.home,
        Routes.search,
        Routes.listing('1'),
        Routes.account,
        Routes.settings,
        Routes.auctions,
        Routes.auctionSchedule,
        Routes.auctionAccount,
        Routes.live('1'),
      ]) {
        expect(Routes.requiresAuth(path), isFalse, reason: path);
      }
    });

    test(
      'giỏ hàng, thông báo, đơn, ví, hồ sơ và đăng ký phiên cần đăng nhập',
      () {
        for (final path in [
          Routes.cart,
          Routes.checkout,
          Routes.notifications,
          Routes.orders,
          Routes.wallet,
          Routes.profile,
          Routes.seller,
          Routes.myAuctions,
          Routes.auctionWallet,
          Routes.sessionRegister('1'),
        ]) {
          expect(Routes.requiresAuth(path), isTrue, reason: path);
        }
      },
    );
  });
}
