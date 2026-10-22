import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/app_shell.dart';
import 'package:book_marketplace/app/router/placeholder_page.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';

part 'app_router.g.dart';

final _rootKey = GlobalKey<NavigatorState>();

typedef _Title = String Function(AppLocalizations l);

/// Trang chưa làm xong: khung Apple Books + thông báo "đang làm".
/// Giai đoạn 3–6 thay từng chỗ bằng màn hình thật.
Widget _soon(BuildContext context, _Title title) =>
    PlaceholderPage(title: title(context.l10n));

/// Thêm màn hình mới: (1) thêm path vào [Routes], (2) thêm GoRoute ở đây.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (location == Routes.landing) return Routes.home;

      final session = ref.read(sessionControllerProvider);
      if (session.status == AuthStatus.unknown) return null;

      if (!session.isSignedIn && Routes.requiresAuth(location)) {
        return Uri(
          path: Routes.login,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }
      if (session.isSignedIn && Routes.isAuthPage(location)) {
        return state.uri.queryParameters['from'] ?? Routes.home;
      }
      return null;
    },
    errorBuilder: (context, state) =>
        PlaceholderPage(title: context.l10n.notFound, notFound: true),
    routes: [
      GoRoute(path: Routes.landing, redirect: (_, _) => Routes.home),
      GoRoute(path: Routes.login, builder: (c, _) => _soon(c, (l) => l.login)),
      GoRoute(
        path: Routes.register,
        builder: (c, _) => _soon(c, (l) => l.register),
      ),
      GoRoute(
        path: Routes.verifyOtp,
        builder: (c, _) => _soon(c, (l) => l.otpTitle),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (c, _) => _soon(c, (l) => l.forgotPassword),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          // Nhánh 1 — Mua sách
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (c, _) => _soon(c, (l) => l.navHome),
                routes: [
                  GoRoute(
                    path: 'search',
                    builder: (c, _) => _soon(c, (l) => l.search),
                  ),
                  GoRoute(
                    path: 'listings/:id',
                    builder: (c, _) => _soon(c, (l) => l.navHome),
                  ),
                  GoRoute(
                    path: 'cart',
                    builder: (c, _) => _soon(c, (l) => l.cartTitle),
                    routes: [
                      GoRoute(
                        path: 'checkout',
                        builder: (c, _) => _soon(c, (l) => l.checkout),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'payments/:id',
                    builder: (c, _) => _soon(c, (l) => l.checkout),
                  ),
                  GoRoute(
                    path: 'shops/:id',
                    builder: (c, _) => _soon(c, (l) => l.navHome),
                  ),
                ],
              ),
            ],
          ),
          // Nhánh 2 — Đấu giá
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.auctions,
                builder: (c, _) => _soon(c, (l) => l.auctionsTitle),
                routes: [
                  GoRoute(
                    path: 'mine',
                    builder: (c, _) => _soon(c, (l) => l.myAuctions),
                  ),
                  GoRoute(
                    path: 'lots/:id',
                    builder: (c, _) => _soon(c, (l) => l.auctionsTitle),
                  ),
                  GoRoute(
                    path: 'sessions/:id',
                    builder: (c, _) => _soon(c, (l) => l.auctionsTitle),
                    routes: [
                      GoRoute(
                        path: 'register',
                        builder: (c, _) => _soon(c, (l) => l.auctionsTitle),
                      ),
                      GoRoute(
                        path: 'results',
                        builder: (c, _) => _soon(c, (l) => l.auctionsTitle),
                      ),
                      // Phòng đấu giá phủ toàn màn hình, không có sidebar / tab bar.
                      GoRoute(
                        path: 'live',
                        parentNavigatorKey: _rootKey,
                        builder: (c, _) => _soon(c, (l) => l.enterLiveRoom),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Nhánh 3 — Thông báo
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.notifications,
                builder: (c, _) => _soon(c, (l) => l.notificationsTitle),
              ),
            ],
          ),
          // Nhánh 4 — Tài khoản (gồm kênh người bán, ký gửi)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.account,
                builder: (c, _) => _soon(c, (l) => l.accountTitle),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (c, _) => _soon(c, (l) => l.accountTitle),
                  ),
                  GoRoute(
                    path: 'addresses',
                    builder: (c, _) => _soon(c, (l) => l.deliveryAddress),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (c, _) => _soon(c, (l) => l.accountTitle),
                  ),
                  GoRoute(
                    path: 'orders',
                    builder: (c, _) => _soon(c, (l) => l.myOrders),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (c, _) => _soon(c, (l) => l.myOrders),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'wallet',
                    builder: (c, _) => _soon(c, (l) => l.wallet),
                  ),
                  GoRoute(
                    path: 'seller',
                    builder: (c, _) => _soon(c, (l) => l.sellerHub),
                    routes: [
                      GoRoute(
                        path: 'open',
                        builder: (c, _) => _soon(c, (l) => l.sellerHub),
                      ),
                      GoRoute(
                        path: 'listings',
                        builder: (c, _) => _soon(c, (l) => l.sellerHub),
                        routes: [
                          GoRoute(
                            path: 'new',
                            builder: (c, _) => _soon(c, (l) => l.newListing),
                          ),
                          GoRoute(
                            path: ':id',
                            builder: (c, _) => _soon(c, (l) => l.newListing),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'orders',
                        builder: (c, _) => _soon(c, (l) => l.shopOrders),
                        routes: [
                          GoRoute(
                            path: ':id',
                            builder: (c, _) => _soon(c, (l) => l.shopOrders),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'consignments',
                    builder: (c, _) => _soon(c, (l) => l.myConsignments),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (c, _) => _soon(c, (l) => l.newConsignment),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (c, _) => _soon(c, (l) => l.myConsignments),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
