import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';

/// Nhóm mục trên sidebar quản trị. Thứ tự hiển thị do `admin_shell.dart` quyết định.
enum AdminNavGroup { overview, review, auction, warehouse, system }

/// Một mục trên sidebar quản trị. Mỗi module tự khai báo mục của mình (xem [AdminModule]),
/// không sửa `admin_shell.dart`.
class AdminNavItem {
  const AdminNavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.group,
    this.staff = false,
    this.badge,
    this.liveDot,
  });

  final IconData icon;

  /// Nhãn lấy từ l10n: `(l10n) => l10n.navUsers`.
  final String Function(AppLocalizations l10n) label;
  final String path;
  final AdminNavGroup group;

  /// true → Staff cũng thấy mục này. Mặc định chỉ Admin thấy.
  final bool staff;

  /// Số việc chờ xử lý (huy hiệu đỏ). Chỉ được gọi khi mục đang hiện với người dùng.
  final int Function(WidgetRef ref)? badge;

  /// Chấm đỏ "đang chạy" (vd. có phiên đấu giá đang live).
  final bool Function(WidgetRef ref)? liveDot;
}

/// Mọi thứ một vai trò (Admin / Staff) đóng góp cho web quản trị: route, mục sidebar, quyền truy cập.
/// Mỗi feature có đúng một file module (`features/<tên>/presentation/<tên>_module.dart`);
/// thêm màn mới = sửa file đó + thêm file màn hình, không đụng router hay shell lõi.
/// Các module được gom ở `admin_modules.dart` (khoá).
class AdminModule {
  const AdminModule({
    required this.routes,
    required this.nav,
    required this.ownedPaths,
    this.staffCanOpen = _never,
    this.smokePaths,
  });

  /// Route con trong khung quản trị. Dùng [adminPage] để có kiểu chuyển trang chuẩn.
  final List<RouteBase> routes;
  final List<AdminNavItem> nav;

  /// Đường dẫn gốc module sở hữu (vd. `AdminRoutes.users`). Dùng để biết địa chỉ nào hợp lệ.
  final List<String> ownedPaths;

  /// Địa chỉ nào Staff được mở. Mặc định: không. Staff-module trả `true` cho mọi đường dẫn của mình.
  final bool Function(String location) staffCanOpen;

  /// Địa chỉ CỤ THỂ cho các route có tham số (vd. `/sessions/s3/monitor`), lấy id từ dữ liệu mẫu.
  /// Test layout (test/layout) mở từng địa chỉ này ở nhiều cỡ màn hình để bắt lỗi tràn / vỡ bố cục.
  /// Route có `:tham_số` mà không có địa chỉ ở đây thì test hỏng, để màn mới không lọt khỏi kiểm tra.
  final Future<List<String>> Function(ProviderContainer container)? smokePaths;

  bool owns(String location) => ownedPaths.any((p) => underPath(location, p));
}

bool _never(String location) => false;

/// `location` nằm dưới `path` (hoặc bằng). `'/'` chỉ khớp chính nó.
bool underPath(String location, String path) => path == '/'
    ? location == '/'
    : (location == path || location.startsWith('$path/'));

/// Trang trong khung admin: không hiệu ứng chuyển trang (giống web truyền thống).
GoRoute adminPage(
  String path,
  Widget Function(GoRouterState state) build, {
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  pageBuilder: (_, state) => NoTransitionPage(child: build(state)),
  routes: routes,
);
