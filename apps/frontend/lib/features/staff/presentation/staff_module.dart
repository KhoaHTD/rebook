import 'package:flutter/material.dart';

import 'package:book_marketplace/app/router/admin_module.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/features/staff/data/staff_repository_provider.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/features/staff/presentation/screens/appointments_screen.dart';
import 'package:book_marketplace/features/staff/presentation/screens/auction_orders_screen.dart';
import 'package:book_marketplace/features/staff/presentation/screens/inspection_screen.dart';
import 'package:book_marketplace/features/staff/presentation/screens/staff_consignments_screen.dart';
import 'package:book_marketplace/features/staff/presentation/screens/warehouse_screen.dart';

/// Phần của Staff trong web quản trị: nhận sách, kiểm định, kho, giao lô đấu giá.
/// Thêm màn mới: (1) thêm đường dẫn vào `AdminRoutes` (mục Staff), (2) thêm route + mục sidebar bên dưới,
/// (3) viết màn hình trong `screens/`. Không sửa router / shell.
final AdminModule staffModule = AdminModule(
  ownedPaths: [
    AdminRoutes.consignments,
    AdminRoutes.appointments,
    AdminRoutes.warehouse,
    AdminRoutes.auctionOrders,
  ],
  staffCanOpen: (location) => staffModule.owns(location),
  // Mở cả phiếu "chờ sơ duyệt" lẫn phiếu "đã nhận sách" (form kiểm định dài nhất).
  smokePaths: (c) async {
    final repo = c.read(staffRepositoryProvider);
    final all = await repo.consignments();
    Iterable<String> idsOf(ConsignmentStatus st) =>
        all.where((x) => x.status == st).take(1).map((x) => x.id);
    return [
      for (final id in [
        ...idsOf(ConsignmentStatus.submitted),
        ...idsOf(ConsignmentStatus.received),
      ])
        AdminRoutes.consignment(id),
    ];
  },
  routes: [
    adminPage(
      AdminRoutes.consignments,
      (_) => const StaffConsignmentsScreen(),
      routes: [
        adminPage(
          ':id',
          (s) => InspectionScreen(consignmentId: s.pathParameters['id']!),
        ),
      ],
    ),
    adminPage(AdminRoutes.appointments, (_) => const AppointmentsScreen()),
    adminPage(AdminRoutes.warehouse, (_) => const WarehouseScreen()),
    adminPage(AdminRoutes.auctionOrders, (_) => const AuctionOrdersScreen()),
  ],
  nav: [
    AdminNavItem(
      icon: Icons.inventory_2_outlined,
      label: (l) => l.navConsignments,
      path: AdminRoutes.consignments,
      group: AdminNavGroup.warehouse,
      staff: true,
    ),
    AdminNavItem(
      icon: Icons.qr_code_scanner_rounded,
      label: (l) => l.navAppointments,
      path: AdminRoutes.appointments,
      group: AdminNavGroup.warehouse,
      staff: true,
    ),
    AdminNavItem(
      icon: Icons.warehouse_outlined,
      label: (l) => l.navWarehouse,
      path: AdminRoutes.warehouse,
      group: AdminNavGroup.warehouse,
      staff: true,
    ),
    AdminNavItem(
      icon: Icons.local_shipping_outlined,
      label: (l) => l.navAuctionOrders,
      path: AdminRoutes.auctionOrders,
      group: AdminNavGroup.warehouse,
      staff: true,
    ),
  ],
);
