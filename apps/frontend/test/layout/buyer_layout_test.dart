// Chốt chặn vỡ bố cục của app người mua + khu đấu giá: tự mở các route chính ở điện thoại, máy tính bảng và
// desktop, bằng phông tiếng Việt thật (nạp dưới tên Roboto), rồi báo mọi lỗi dựng hình / "RenderFlex overflowed".
// Chỉ bắt lỗi vỡ, không áp đặt kiểu bố cục.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/app/app.dart';
import 'package:book_marketplace/app/router/app_router.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/core/auth/auth_tokens.dart';
import 'package:book_marketplace/core/auth/auth_user.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/auth/token_storage.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage() : super(const FlutterSecureStorage());

  AuthTokens? _tokens;
  AuthUser? _user;

  @override
  Future<AuthTokens?> read() async => _tokens;
  @override
  Future<AuthUser?> readUser() async => _user;
  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;
  @override
  Future<void> writeUser(AuthUser user) async => _user = user;
  @override
  Future<void> clear() async {
    _tokens = null;
    _user = null;
  }
}

Future<void> _loadFonts() async {
  final loader = FontLoader('Roboto');
  for (final w in [400, 500, 600, 700, 800]) {
    loader.addFont(
      File('assets/fonts/BeVietnamPro-$w.ttf')
          .readAsBytes()
          .then((b) => ByteData.sublistView(b)),
    );
  }
  await loader.load();
}

const _sizes = <(String, Size)>[
  ('điện thoại', Size(375, 812)),
  ('máy tính bảng', Size(800, 1100)),
  ('desktop', Size(1400, 860)),
];

void main() {
  setUpAll(_loadFonts);

  for (final (label, size) in _sizes) {
    testWidgets('app người mua dựng các route chính không lỗi — $label', (
      tester,
    ) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(_MemoryTokenStorage()),
        ],
      );
      final store = container.read(fakeStoreProvider);
      final user = store.login('minhanh@rebook.vn', '123456');
      container.read(sessionControllerProvider);
      await tester.pump();
      await container
          .read(sessionControllerProvider.notifier)
          .signIn(
            const AuthTokens(accessToken: 'a', refreshToken: 'r'),
            user.toAuthUser(),
          );

      final listingId = store.listingsByStatus(null).first.id;
      final sessionId = store.sessions.keys.first;
      final orderId = store.orders.keys.isEmpty
          ? null
          : store.orders.keys.first;
      final shopId = store.shops.keys.first;
      final consignmentId = store.consignments.keys.isEmpty
          ? null
          : store.consignments.keys.first;
      final paths = <String>[
        Routes.home,
        Routes.search,
        Routes.listing(listingId),
        Routes.shop(shopId),
        Routes.cart,
        Routes.checkout,
        Routes.notifications,
        Routes.account,
        Routes.profile,
        Routes.addresses,
        Routes.addressNew,
        Routes.favorites,
        Routes.settings,
        Routes.orders,
        if (orderId != null) Routes.order(orderId),
        Routes.wallet,
        Routes.withdrawBank,
        Routes.seller,
        Routes.sellerListings,
        Routes.newListing,
        Routes.sellerOrders,
        Routes.consignments,
        Routes.newConsignment,
        if (consignmentId != null) Routes.consignment(consignmentId),
        Routes.auctions,
        Routes.auctionSchedule,
        Routes.myAuctions,
        Routes.auctionResults,
        Routes.auctionAccount,
        Routes.auctionWallet,
        Routes.auctionOrders,
        Routes.auctionBids,
        Routes.auctionOffers,
        Routes.session(sessionId),
        Routes.sessionRegister(sessionId),
        Routes.results(sessionId),
        Routes.live(sessionId),
        Routes.login,
        Routes.register,
      ];

      final errors = <String>[];
      final previous = FlutterError.onError;
      var current = '';
      FlutterError.onError = (d) {
        // Kèm chỗ trong mã tạo ra widget bị tràn để dễ tìm.
        final where = RegExp(r'book_marketplace/[\w/.-]+\.dart:\d+')
            .firstMatch(d.toString());
        final first = d.exceptionAsString().split('\n').first;
        errors.add('[$current] $first ${where?.group(0)?.trim() ?? ''}');
      };
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const BookMarketplaceApp(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        final router = container.read(appRouterProvider);
        for (final p in paths) {
          current = p;
          router.go(p);
          for (var i = 0; i < 5; i++) {
            await tester.pump(const Duration(milliseconds: 300));
          }
        }
      } finally {
        FlutterError.onError = previous;
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await tester.pump();
      }
      // Gộp theo (route, thông báo) để dễ đọc.
      final unique = errors.toSet().toList();
      expect(unique, isEmpty, reason: unique.take(40).join('\n'));
    });
  }
}
