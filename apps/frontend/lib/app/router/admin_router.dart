import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/admin_shell.dart';
import 'package:book_marketplace/app/router/placeholder_page.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/core/auth/auth_user.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/admin/presentation/screens/categories_screen.dart';
import 'package:book_marketplace/features/admin/presentation/screens/config_screen.dart';
import 'package:book_marketplace/features/admin/presentation/screens/dashboard_screen.dart';
import 'package:book_marketplace/features/admin/presentation/screens/disputes_screen.dart';
import 'package:book_marketplace/features/admin/presentation/screens/listing_review_screen.dart';
import 'package:book_marketplace/features/admin/presentation/screens/monitor_screen.dart';
import 'package:book_marketplace/features/admin/presentation/screens/session_edit_screen.dart';
import 'package:book_marketplace/features/admin/presentation/screens/sessions_screen.dart';
import 'package:book_marketplace/features/admin/presentation/screens/users_screen.dart';
import 'package:book_marketplace/features/admin/presentation/screens/withdrawals_screen.dart';
import 'package:book_marketplace/features/auth/presentation/screens/login_screen.dart';
import 'package:book_marketplace/features/staff/presentation/screens/appointments_screen.dart';
import 'package:book_marketplace/features/staff/presentation/screens/auction_orders_screen.dart';
import 'package:book_marketplace/features/staff/presentation/screens/inspection_screen.dart';
import 'package:book_marketplace/features/staff/presentation/screens/staff_consignments_screen.dart';
import 'package:book_marketplace/features/staff/presentation/screens/warehouse_screen.dart';

part 'admin_router.g.dart';

/// Router của web quản trị: chỉ Staff / Admin vào được; Staff thấy phần kho + giám sát phiên.
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
          _page(AdminRoutes.dashboard, (_) => const DashboardScreen()),
          _page(
            AdminRoutes.consignments,
            (_) => const StaffConsignmentsScreen(),
            routes: [
              _page(
                ':id',
                (s) => InspectionScreen(consignmentId: s.pathParameters['id']!),
              ),
            ],
          ),
          _page(AdminRoutes.appointments, (_) => const AppointmentsScreen()),
          _page(AdminRoutes.warehouse, (_) => const WarehouseScreen()),
          _page(AdminRoutes.auctionOrders, (_) => const AuctionOrdersScreen()),
          _page(
            AdminRoutes.sessions,
            (_) => const SessionsScreen(),
            routes: [
              _page('new', (_) => const SessionEditScreen()),
              _page(
                ':id',
                (s) => SessionEditScreen(sessionId: s.pathParameters['id']),
                routes: [
                  _page(
                    'monitor',
                    (s) => MonitorScreen(sessionId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          _page(AdminRoutes.listings, (_) => const ListingReviewScreen()),
          _page(AdminRoutes.users, (_) => const UsersScreen()),
          _page(AdminRoutes.categories, (_) => const CategoriesScreen()),
          _page(AdminRoutes.config, (_) => const ConfigScreen()),
          _page(AdminRoutes.withdrawals, (_) => const WithdrawalsScreen()),
          _page(AdminRoutes.disputes, (_) => const DisputesScreen()),
        ],
      ),
    ],
  );
}

String _home(AuthUser user) => user.role == AuthRole.admin
    ? AdminRoutes.dashboard
    : AdminRoutes.consignments;

/// Staff: phần kho + danh sách phiên và màn giám sát (SRS 2 — Staff / Auctioneer).
/// Tạo / sửa phiên chỉ Admin.
bool _staffAllowed(String location) =>
    location == AdminRoutes.sessions ||
    (location.startsWith('${AdminRoutes.sessions}/') &&
        location.endsWith('/monitor')) ||
    [
      AdminRoutes.consignments,
      AdminRoutes.appointments,
      AdminRoutes.warehouse,
      AdminRoutes.auctionOrders,
    ].any((p) => location == p || location.startsWith('$p/'));

/// Trang trong khung admin: không hiệu ứng chuyển trang (giống web truyền thống).
GoRoute _page(
  String path,
  Widget Function(GoRouterState state) build, {
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  pageBuilder: (_, state) => NoTransitionPage(child: build(state)),
  routes: routes,
);
