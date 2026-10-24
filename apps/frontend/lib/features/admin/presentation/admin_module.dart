import 'package:flutter/material.dart';

import 'package:book_marketplace/app/router/admin_module.dart';
import 'package:book_marketplace/features/admin/data/admin_repository_provider.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
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
import 'package:book_marketplace/shared/domain/enums.dart';

/// Phần của Admin trong web quản trị: dashboard, duyệt tin, người dùng, danh mục, phiên đấu giá, phí, rút tiền.
/// Thêm màn mới: (1) thêm đường dẫn vào `AdminRoutes` (mục Admin), (2) thêm route + mục sidebar bên dưới,
/// (3) viết màn hình trong `screens/`. Không sửa router / shell.
final adminModule = AdminModule(
  ownedPaths: [
    AdminRoutes.dashboard,
    AdminRoutes.sessions,
    AdminRoutes.listings,
    AdminRoutes.users,
    AdminRoutes.categories,
    AdminRoutes.config,
    AdminRoutes.withdrawals,
    AdminRoutes.disputes,
  ],
  // Staff chỉ xem danh sách phiên và màn giám sát; tạo / sửa phiên chỉ Admin (SRS 2).
  staffCanOpen: (location) =>
      location == AdminRoutes.sessions ||
      (location.startsWith('${AdminRoutes.sessions}/') &&
          location.endsWith('/monitor')),
  smokePaths: (c) async {
    final sessions = await c.read(adminRepositoryProvider).sessions();
    if (sessions.isEmpty) return const [AdminRoutes.newSession];
    final live = sessions.where((s) => s.isLive);
    return [
      AdminRoutes.newSession,
      AdminRoutes.session(sessions.first.id),
      AdminRoutes.monitor((live.isEmpty ? sessions.first : live.first).id),
    ];
  },
  routes: [
    adminPage(AdminRoutes.dashboard, (_) => const DashboardScreen()),
    adminPage(
      AdminRoutes.sessions,
      (_) => const SessionsScreen(),
      routes: [
        adminPage('new', (_) => const SessionEditScreen()),
        adminPage(
          ':id',
          (s) => SessionEditScreen(sessionId: s.pathParameters['id']),
          routes: [
            adminPage(
              'monitor',
              (s) => MonitorScreen(sessionId: s.pathParameters['id']!),
            ),
          ],
        ),
      ],
    ),
    adminPage(AdminRoutes.listings, (_) => const ListingReviewScreen()),
    adminPage(AdminRoutes.users, (_) => const UsersScreen()),
    adminPage(AdminRoutes.categories, (_) => const CategoriesScreen()),
    adminPage(AdminRoutes.config, (_) => const ConfigScreen()),
    adminPage(AdminRoutes.withdrawals, (_) => const WithdrawalsScreen()),
    adminPage(AdminRoutes.disputes, (_) => const DisputesScreen()),
  ],
  nav: [
    AdminNavItem(
      icon: Icons.space_dashboard_outlined,
      label: (l) => l.navDashboard,
      path: AdminRoutes.dashboard,
      group: AdminNavGroup.overview,
    ),
    AdminNavItem(
      icon: Icons.fact_check_outlined,
      label: (l) => l.navListingReview,
      path: AdminRoutes.listings,
      group: AdminNavGroup.review,
      badge: (ref) => ref.watch(pendingListingsProvider).value?.length ?? 0,
    ),
    AdminNavItem(
      icon: Icons.gpp_maybe_outlined,
      label: (l) => l.navDisputes,
      path: AdminRoutes.disputes,
      group: AdminNavGroup.review,
      badge: (ref) => ref.watch(adminDisputesProvider).value?.length ?? 0,
    ),
    AdminNavItem(
      icon: Icons.people_outline_rounded,
      label: (l) => l.navUsers,
      path: AdminRoutes.users,
      group: AdminNavGroup.review,
    ),
    AdminNavItem(
      icon: Icons.category_outlined,
      label: (l) => l.navCategories,
      path: AdminRoutes.categories,
      group: AdminNavGroup.review,
    ),
    AdminNavItem(
      icon: Icons.gavel_rounded,
      label: (l) => l.navSessions,
      path: AdminRoutes.sessions,
      group: AdminNavGroup.auction,
      staff: true,
      liveDot: (ref) =>
          ref.watch(adminSessionsProvider).value?.any((s) => s.isLive) ?? false,
    ),
    AdminNavItem(
      icon: Icons.tune_rounded,
      label: (l) => l.navConfig,
      path: AdminRoutes.config,
      group: AdminNavGroup.system,
    ),
    AdminNavItem(
      icon: Icons.account_balance_outlined,
      label: (l) => l.navWithdrawals,
      path: AdminRoutes.withdrawals,
      group: AdminNavGroup.system,
      badge: (ref) =>
          ref
              .watch(adminWithdrawalsProvider)
              .value
              ?.where((w) => w.status == WithdrawalStatus.pending)
              .length ??
          0,
    ),
  ],
);
