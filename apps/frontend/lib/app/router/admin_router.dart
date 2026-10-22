import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/admin_shell.dart';
import 'package:book_marketplace/app/router/placeholder_page.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/core/auth/auth_user.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/auth/presentation/screens/login_screen.dart';

part 'admin_router.g.dart';

typedef _Title = String Function(AppLocalizations l);

/// Router của web quản trị: chỉ Staff / Admin vào được; Staff chỉ thấy phần kho.
@Riverpod(keepAlive: true)
GoRouter adminRouter(Ref ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AdminRoutes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) async {
      final session = ref.read(sessionControllerProvider);
      if (session.status == AuthStatus.unknown) return null;
      final location = state.matchedLocation;
      final onLogin = location == AdminRoutes.login;
      final user = session.user;

      if (session.isSignedIn && !user!.isStaffOrAdmin) {
        await ref.read(sessionControllerProvider.notifier).signOut();
        return '${AdminRoutes.login}?denied=1';
      }
      if (!session.isSignedIn) return onLogin ? null : AdminRoutes.login;
      if (onLogin) return _home(user!);
      // Staff vào trang chỉ dành cho Admin → về trang kho.
      if (user!.role == AuthRole.staff && !_staffAllowed(location)) {
        return AdminRoutes.consignments;
      }
      return null;
    },
    errorBuilder: (context, state) =>
        PlaceholderPage(title: context.l10n.notFound, notFound: true),
    routes: [
      GoRoute(
        path: AdminRoutes.login,
        builder: (_, s) => LoginScreen(
          allowSignUp: false,
          denied: s.uri.queryParameters['denied'] == '1',
        ),
      ),
      ShellRoute(
        builder: (_, state, child) =>
            AdminShell(location: state.matchedLocation, child: child),
        routes: [
          _page(AdminRoutes.dashboard, (l) => l.navDashboard),
          _page(
            AdminRoutes.consignments,
            (l) => l.navConsignments,
            routes: [_page(':id', (l) => l.navConsignments)],
          ),
          _page(AdminRoutes.appointments, (l) => l.navAppointments),
          _page(AdminRoutes.warehouse, (l) => l.navWarehouse),
          _page(AdminRoutes.auctionOrders, (l) => l.navAuctionOrders),
          _page(
            AdminRoutes.sessions,
            (l) => l.navSessions,
            routes: [
              _page('new', (l) => l.navSessions),
              _page(
                ':id',
                (l) => l.navSessions,
                routes: [_page('monitor', (l) => l.navSessions)],
              ),
            ],
          ),
          _page(AdminRoutes.listings, (l) => l.navListingReview),
          _page(AdminRoutes.users, (l) => l.navUsers),
          _page(AdminRoutes.categories, (l) => l.navCategories),
          _page(AdminRoutes.config, (l) => l.navConfig),
          _page(AdminRoutes.withdrawals, (l) => l.navWithdrawals),
          _page(AdminRoutes.disputes, (l) => l.navDisputes),
        ],
      ),
    ],
  );
}

String _home(AuthUser user) => user.role == AuthRole.admin
    ? AdminRoutes.dashboard
    : AdminRoutes.consignments;

bool _staffAllowed(String location) => [
  AdminRoutes.consignments,
  AdminRoutes.appointments,
  AdminRoutes.warehouse,
  AdminRoutes.auctionOrders,
].any((p) => location == p || location.startsWith('$p/'));

/// Trang trong khung admin, không hiệu ứng chuyển trang. Giai đoạn 6 thay trang tạm bằng màn thật.
GoRoute _page(String path, _Title title, {List<RouteBase> routes = const []}) =>
    GoRoute(
      path: path,
      pageBuilder: (context, state) =>
          NoTransitionPage(child: PlaceholderPage(title: title(context.l10n))),
      routes: routes,
    );
