import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/app_shell.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/auction/presentation/screens/auction_list_screen.dart';
import 'package:book_marketplace/features/auction/presentation/screens/auction_room_screen.dart';
import 'package:book_marketplace/features/auth/presentation/screens/login_screen.dart';
import 'package:book_marketplace/features/catalog/presentation/screens/book_detail_screen.dart';
import 'package:book_marketplace/features/catalog/presentation/screens/catalog_screen.dart';
import 'package:book_marketplace/features/profile/presentation/screens/profile_screen.dart';

part 'app_router.g.dart';

/// Thêm màn hình mới: (1) thêm path vào [Routes], (2) thêm GoRoute ở đây.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.catalog,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      if (session == SessionStatus.unknown) return null;

      final location = state.matchedLocation;
      final signedIn = session == SessionStatus.signedIn;

      if (!signedIn && Routes.requiresAuth(location)) {
        return Uri(
          path: Routes.login,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }
      if (signedIn && location == Routes.login) {
        return state.uri.queryParameters['from'] ?? Routes.catalog;
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: Center(child: Text(context.l10n.notFound)),
    ),
    routes: [
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.catalog,
                builder: (_, _) => const CatalogScreen(),
                routes: [
                  GoRoute(
                    path: 'books/:id',
                    builder: (_, state) =>
                        BookDetailScreen(bookId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.auctions,
                builder: (_, _) => const AuctionListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => AuctionRoomScreen(
                      auctionId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
