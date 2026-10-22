import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/app_shell.dart';
import 'package:book_marketplace/app/router/placeholder_page.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:book_marketplace/features/auth/presentation/screens/login_screen.dart';
import 'package:book_marketplace/features/auth/presentation/screens/register_screen.dart';
import 'package:book_marketplace/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:book_marketplace/features/cart/presentation/screens/cart_screen.dart';
import 'package:book_marketplace/features/cart/presentation/screens/checkout_screen.dart';
import 'package:book_marketplace/features/cart/presentation/screens/payment_result_screen.dart';
import 'package:book_marketplace/features/catalog/presentation/screens/home_screen.dart';
import 'package:book_marketplace/features/catalog/presentation/screens/listing_detail_screen.dart';
import 'package:book_marketplace/features/catalog/presentation/screens/search_screen.dart';
import 'package:book_marketplace/features/catalog/presentation/screens/shop_screen.dart';

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
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: Routes.verifyOtp,
        builder: (_, s) =>
            VerifyOtpScreen(email: s.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          // Nhánh 1 — Mua sách
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (_, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'search',
                    builder: (_, s) => SearchScreen(
                      initialCategory: s.uri.queryParameters['category'],
                      initialText: s.uri.queryParameters['q'],
                    ),
                  ),
                  GoRoute(
                    path: 'listings/:id',
                    builder: (_, s) =>
                        ListingDetailScreen(listingId: s.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'cart',
                    builder: (_, _) => const CartScreen(),
                    routes: [
                      GoRoute(
                        path: 'checkout',
                        builder: (_, _) => const CheckoutScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'payments/:id',
                    builder: (_, s) =>
                        PaymentResultScreen(paymentId: s.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'shops/:id',
                    builder: (_, s) =>
                        ShopScreen(shopId: s.pathParameters['id']!),
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
