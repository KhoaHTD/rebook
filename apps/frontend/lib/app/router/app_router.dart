import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/app_shell.dart';
import 'package:book_marketplace/app/router/auction_shell.dart';
import 'package:book_marketplace/app/router/placeholder_page.dart';
import 'package:book_marketplace/app/router/mode_switch.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/account/presentation/screens/account_screen.dart';
import 'package:book_marketplace/features/account/presentation/screens/address_edit_screen.dart';
import 'package:book_marketplace/features/account/presentation/screens/addresses_screen.dart';
import 'package:book_marketplace/features/catalog/presentation/screens/favorites_screen.dart';
import 'package:book_marketplace/features/account/presentation/screens/profile_screen.dart';
import 'package:book_marketplace/features/account/presentation/screens/settings_screen.dart';
import 'package:book_marketplace/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:book_marketplace/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:book_marketplace/features/wallet/presentation/screens/withdraw_screens.dart';
import 'package:book_marketplace/features/auction/presentation/screens/auction_account_screen.dart';
import 'package:book_marketplace/features/auction/presentation/screens/auction_floor_screen.dart';
import 'package:book_marketplace/features/auction/presentation/screens/auction_history_screen.dart';
import 'package:book_marketplace/features/auction/presentation/screens/auction_schedule_screen.dart';
import 'package:book_marketplace/features/auction/presentation/screens/live_room_screen.dart';
import 'package:book_marketplace/features/auction/presentation/screens/lot_screen.dart';
import 'package:book_marketplace/features/auction/presentation/screens/my_auctions_screen.dart';
import 'package:book_marketplace/features/auction/presentation/screens/my_bids_screen.dart';
import 'package:book_marketplace/features/auction/presentation/screens/offers_screen.dart';
import 'package:book_marketplace/features/auction/presentation/screens/register_session_screen.dart';
import 'package:book_marketplace/features/auction/presentation/screens/results_screen.dart';
import 'package:book_marketplace/features/auction/presentation/screens/session_screen.dart';
import 'package:book_marketplace/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:book_marketplace/features/auth/presentation/screens/login_screen.dart';
import 'package:book_marketplace/features/auth/presentation/screens/register_screen.dart';
import 'package:book_marketplace/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:book_marketplace/features/cart/presentation/screens/cart_screen.dart';
import 'package:book_marketplace/features/cart/presentation/screens/checkout_screen.dart';
import 'package:book_marketplace/features/cart/presentation/screens/payment_result_screen.dart';
import 'package:book_marketplace/features/catalog/presentation/screens/home_screen.dart';
import 'package:book_marketplace/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:book_marketplace/features/orders/presentation/screens/orders_screen.dart';
import 'package:book_marketplace/features/catalog/presentation/screens/listing_detail_screen.dart';
import 'package:book_marketplace/features/catalog/presentation/screens/search_screen.dart';
import 'package:book_marketplace/features/catalog/presentation/screens/shop_screen.dart';
import 'package:book_marketplace/features/consignment/presentation/screens/consignment_detail_screen.dart';
import 'package:book_marketplace/features/landing/presentation/screens/welcome_screen.dart';
import 'package:book_marketplace/features/consignment/presentation/screens/consignments_screen.dart';
import 'package:book_marketplace/features/consignment/presentation/screens/new_consignment_screen.dart';
import 'package:book_marketplace/features/seller/presentation/screens/listing_form_screen.dart';
import 'package:book_marketplace/features/seller/presentation/screens/open_shop_screen.dart';
import 'package:book_marketplace/features/seller/presentation/screens/seller_hub_screen.dart';
import 'package:book_marketplace/features/seller/presentation/screens/seller_listings_screen.dart';
import 'package:book_marketplace/features/seller/presentation/screens/seller_order_detail_screen.dart';
import 'package:book_marketplace/features/seller/presentation/screens/seller_orders_screen.dart';

part 'app_router.g.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Thêm màn hình mới: (1) thêm path vào [Routes], (2) thêm GoRoute ở đây.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    // Web mở trang giới thiệu (`/`); app điện thoại vào thẳng Mua sách.
    initialLocation: kIsWeb ? Routes.landing : Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final session = ref.read(sessionControllerProvider);
      if (location == Routes.landing && (!kIsWeb || session.isSignedIn)) {
        return Routes.home;
      }
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
      GoRoute(
        path: Routes.landing,
        builder: (_, s) => WelcomeScreen(
          initialOffset: double.tryParse(s.uri.queryParameters['y'] ?? '') ?? 0,
        ),
      ),
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
        pageBuilder: (_, state, shell) =>
            _revealPage(state, AppShell(navigationShell: shell)),
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
          // Nhánh 2 — Thông báo
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.notifications,
                builder: (_, _) => const NotificationsScreen(),
              ),
            ],
          ),
          // Nhánh 3 — Tài khoản (gồm kênh người bán, ký gửi)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.account,
                builder: (_, _) => const AccountScreen(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (_, _) => const ProfileScreen(),
                  ),
                  GoRoute(
                    path: 'addresses',
                    builder: (_, _) => const AddressesScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (_, _) => const AddressEditScreen(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (_, s) => AddressEditScreen(
                          addressId: s.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'favorites',
                    builder: (_, _) => const FavoritesScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (_, _) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'orders',
                    builder: (_, _) => const OrdersScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (_, s) =>
                            OrderDetailScreen(orderId: s.pathParameters['id']!),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'wallet',
                    builder: (_, _) => const WalletScreen(),
                    routes: [
                      GoRoute(
                        path: 'withdraw/bank',
                        builder: (_, _) => const WithdrawBankScreen(),
                      ),
                      GoRoute(
                        path: 'withdraw/account',
                        builder: (_, _) => const WithdrawAccountScreen(),
                      ),
                      GoRoute(
                        path: 'withdraw/amount',
                        builder: (_, _) => const WithdrawAmountScreen(),
                      ),
                      GoRoute(
                        path: 'withdraw/done',
                        builder: (_, _) => const WithdrawDoneScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'seller',
                    builder: (_, _) => const SellerHubScreen(),
                    routes: [
                      GoRoute(
                        path: 'open',
                        builder: (_, _) => const OpenShopScreen(),
                      ),
                      GoRoute(
                        path: 'listings',
                        builder: (_, _) => const SellerListingsScreen(),
                        routes: [
                          GoRoute(
                            path: 'new',
                            builder: (_, _) => const ListingFormScreen(),
                          ),
                          GoRoute(
                            path: ':id',
                            builder: (_, s) => ListingFormScreen(
                              listingId: s.pathParameters['id'],
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'orders',
                        builder: (_, _) => const SellerOrdersScreen(),
                        routes: [
                          GoRoute(
                            path: ':id',
                            builder: (_, s) => SellerOrderDetailScreen(
                              orderId: s.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'consignments',
                    builder: (_, _) => const ConsignmentsScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (_, _) => const NewConsignmentScreen(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (_, s) => ConsignmentDetailScreen(
                          consignmentId: s.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Khu đấu giá: khung, theme và trang chủ riêng (Sàn · Lịch · Của tôi · Kết quả · Tài khoản).
      StatefulShellRoute.indexedStack(
        pageBuilder: (_, state, shell) =>
            _revealPage(state, AuctionShell(navigationShell: shell)),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.auctions,
                builder: (_, _) => const AuctionFloorScreen(),
                routes: [
                  GoRoute(
                    path: 'lots/:id',
                    builder: (_, s) =>
                        LotScreen(lotId: s.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'sessions/:id',
                    builder: (_, s) =>
                        SessionScreen(sessionId: s.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'register',
                        builder: (_, s) => RegisterSessionScreen(
                          sessionId: s.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'results',
                        builder: (_, s) =>
                            ResultsScreen(sessionId: s.pathParameters['id']!),
                      ),
                      // Phòng đấu giá phủ toàn màn hình, không có sidebar / tab bar (vẫn theme đấu giá).
                      GoRoute(
                        path: 'live',
                        parentNavigatorKey: _rootKey,
                        builder: (_, s) => AuctionTheme(
                          child: LiveRoomScreen(
                            sessionId: s.pathParameters['id']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.auctionSchedule,
                builder: (_, _) => const AuctionScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.myAuctions,
                builder: (_, _) => const MyAuctionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.auctionResults,
                builder: (_, _) => const AuctionHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.auctionAccount,
                builder: (_, _) => const AuctionAccountScreen(),
                routes: [
                  GoRoute(
                    path: 'wallet',
                    builder: (_, _) => const WalletScreen(auction: true),
                  ),
                  GoRoute(
                    path: 'orders',
                    builder: (_, _) => const OrdersScreen(auction: true),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (_, s) =>
                            OrderDetailScreen(orderId: s.pathParameters['id']!),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'bids',
                    builder: (_, _) => const MyBidsScreen(),
                  ),
                  GoRoute(
                    path: 'offers',
                    builder: (_, _) => const OffersScreen(),
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

/// Trang khung của một khu: khi đổi khu bằng nút tròn thì loang ra từ chỗ bấm ([ModeReveal]),
/// còn lại (mở app, đăng nhập xong…) hiện thẳng.
Page<void> _revealPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 700),
      reverseTransitionDuration: Duration.zero,
      child: child,
      transitionsBuilder: (context, animation, _, child) =>
          ModeReveal.transition(context, animation, child),
    );
