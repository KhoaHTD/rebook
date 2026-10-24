import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/admin_router.dart';
import 'package:book_marketplace/app/router/app_router.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/settings/app_settings_controller.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';

/// App người dùng (web + Android + iOS). Staff / Admin đăng nhập ở đây sẽ tự chuyển sang
/// giao diện quản trị riêng (cùng địa chỉ); đăng xuất thì quay lại app người mua.
class BookMarketplaceApp extends ConsumerWidget {
  const BookMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff =
        ref
            .watch(sessionControllerProvider.select((s) => s.user))
            ?.isStaffOrAdmin ??
        false;
    return _RebookMaterialApp(
      router: staff
          ? ref.watch(adminRouterProvider)
          : ref.watch(appRouterProvider),
      title: (l10n) => staff ? l10n.adminAppTitle : l10n.appTitle,
      forceLight: staff,
    );
  }
}

/// Web quản trị cho Staff / Admin.
class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _RebookMaterialApp(
    router: ref.watch(adminRouterProvider),
    title: (l10n) => l10n.adminAppTitle,
    forceLight: true,
  );
}

class _RebookMaterialApp extends ConsumerWidget {
  const _RebookMaterialApp({
    required this.router,
    required this.title,
    this.forceLight = false,
  });

  final GoRouter router;
  final String Function(AppLocalizations) title;

  /// Giao diện quản trị chỉ có bản sáng.
  final bool forceLight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsControllerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => title(context.l10n),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: forceLight ? ThemeMode.light : settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      // Nền màu loang phía sau mọi trang (kính cần có màu phía sau mới "khúc xạ").
      builder: (context, child) =>
          AmbientBackground(child: child ?? const SizedBox.shrink()),
    );
  }
}
