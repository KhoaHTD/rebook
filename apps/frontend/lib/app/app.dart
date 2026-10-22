import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/admin_router.dart';
import 'package:book_marketplace/app/router/app_router.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/core/settings/app_settings_controller.dart';

/// App người dùng (web + Android + iOS).
class BookMarketplaceApp extends ConsumerWidget {
  const BookMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _RebookMaterialApp(
    router: ref.watch(appRouterProvider),
    title: (l10n) => l10n.appTitle,
  );
}

/// Web quản trị cho Staff / Admin.
class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _RebookMaterialApp(
    router: ref.watch(adminRouterProvider),
    title: (l10n) => l10n.adminAppTitle,
  );
}

class _RebookMaterialApp extends ConsumerWidget {
  const _RebookMaterialApp({required this.router, required this.title});

  final GoRouter router;
  final String Function(AppLocalizations) title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsControllerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => title(context.l10n),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
