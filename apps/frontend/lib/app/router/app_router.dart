import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';

part 'app_router.g.dart';

/// TẠM (giai đoạn 1): chỉ một trang chờ. Giai đoạn 2 thay bằng khung app Apple Books
/// (sidebar desktop / tab bar mobile) và toàn bộ route trong [Routes].
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) => GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, _) =>
          Scaffold(body: Center(child: Text(context.l10n.appTitle))),
    ),
  ],
);
