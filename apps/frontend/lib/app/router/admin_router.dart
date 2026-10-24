import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/admin_modules.dart';
import 'package:book_marketplace/app/router/admin_shell.dart';
import 'package:book_marketplace/app/router/placeholder_page.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/core/auth/auth_user.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/auth/presentation/screens/login_screen.dart';

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
      // Địa chỉ của app người mua (vd. /home sau khi đăng nhập ở app thường) → về trang chủ quản trị.
      if (!_isAdminLocation(location)) return _home(user!);
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
        routes: [for (final m in adminModules) ...m.routes],
      ),
    ],
  );
}

String _home(AuthUser user) => user.role == AuthRole.admin
    ? AdminRoutes.dashboard
    : AdminRoutes.consignments;

bool _isAdminLocation(String location) =>
    location == AdminRoutes.login || adminModules.any((m) => m.owns(location));

/// Staff chỉ mở được những địa chỉ mà module cho phép (xem `AdminModule.staffCanOpen`).
bool _staffAllowed(String location) =>
    adminModules.any((m) => m.staffCanOpen(location));
