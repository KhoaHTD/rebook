import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/admin_module.dart';
import 'package:book_marketplace/app/router/admin_modules.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/auth_user.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/shared/widgets/admin_scope.dart';

/// Khung web quản trị: sidebar trắng phẳng, mục đang chọn tô đen (dashboard chuyên nghiệp).
/// Staff chỉ thấy nhóm Kho + Giám sát phiên; Admin thấy đủ các nhóm.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String get location => widget.location;
  Widget get child => widget.child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < 900;
    final user = ref.watch(sessionControllerProvider).user;
    final isAdmin = user?.role == AuthRole.admin;

    // Mục sidebar do từng module đăng ký (xem admin_module.dart). Staff chỉ thấy mục `staff: true`.
    final entries = [
      for (final m in adminModules)
        for (final i in m.nav)
          if (isAdmin || i.staff) i,
    ];
    // Thứ tự nhóm: Admin xem tổng quan trước; Staff mở đầu bằng Kho.
    final groups = [
      for (final g
          in isAdmin
              ? const [
                  AdminNavGroup.overview,
                  AdminNavGroup.review,
                  AdminNavGroup.auction,
                  AdminNavGroup.warehouse,
                  AdminNavGroup.system,
                ]
              : const [AdminNavGroup.warehouse, AdminNavGroup.auction])
        if (entries.any((i) => i.group == g)) g,
    ];
    String groupLabel(AdminNavGroup g) => switch (g) {
      AdminNavGroup.overview => l10n.adminGroupOverview,
      AdminNavGroup.review => l10n.adminGroupReview,
      AdminNavGroup.auction => l10n.adminGroupAuction,
      AdminNavGroup.warehouse => l10n.adminGroupWarehouse,
      AdminNavGroup.system => l10n.adminGroupSystem,
    };
    Iterable<AdminNavItem> itemsOf(AdminNavGroup g) =>
        entries.where((i) => i.group == g);

    Widget navItem(AdminNavItem i) => _NavItem(
      icon: i.icon,
      label: i.label(l10n),
      selected: underPath(location, i.path),
      count: i.badge?.call(ref) ?? 0,
      liveDot: i.liveDot?.call(ref) ?? false,
      onTap: () {
        if (compact) Navigator.of(context).pop();
        context.go(i.path);
      },
    );

    final sidebar = Container(
      width: compact ? null : 248,
      margin: compact ? null : const EdgeInsets.fromLTRB(16, 16, 0, 16),
      decoration: BoxDecoration(
        color: AdminPalette.card,
        borderRadius: compact ? null : BorderRadius.circular(24),
        boxShadow: compact
            ? null
            : [
                BoxShadow(
                  color: AdminPalette.ink.withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AdminPalette.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      size: 18,
                      color: AdminPalette.card,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.appTitle,
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? AdminPalette.accentSoft
                          : AdminPalette.infoSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      isAdmin ? l10n.adminBadgeAdmin : l10n.adminBadgeStaff,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: isAdmin
                            ? AdminPalette.accent
                            : AdminPalette.info,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final g in groups) ...[
                    _Group(groupLabel(g)),
                    for (final i in itemsOf(g)) navItem(i),
                  ],
                ],
              ),
            ),
            if (user != null)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                decoration: BoxDecoration(
                  color: AdminPalette.bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AdminPalette.accent,
                      child: Text(
                        user.fullName.isEmpty
                            ? '?'
                            : user.fullName.characters.first.toUpperCase(),
                        style: context.textStyles.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.labelLarge,
                          ),
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.labelSmall?.copyWith(
                              color: AdminPalette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.logout,
                      icon: const Icon(Icons.logout_rounded, size: 19),
                      onPressed: () => ref
                          .read(sessionControllerProvider.notifier)
                          .signOut(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    final content = AdminScope(
      onMenu: compact ? () => _scaffoldKey.currentState?.openDrawer() : null,
      child: Theme(data: _adminTheme(Theme.of(context)), child: child),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminPalette.bg,
      drawer: compact ? Drawer(width: 280, child: sidebar) : null,
      body: compact
          ? content
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sidebar,
                Expanded(child: content),
              ],
            ),
    );
  }
}

/// Nút đen, bo 10 — dùng cho mọi màn quản trị (không phải nút xanh của app người mua).
ThemeData _adminTheme(ThemeData base) {
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  return base.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AdminPalette.accent,
        foregroundColor: Colors.white,
        shape: shape,
        minimumSize: const Size(0, 42),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      selectedColor: AdminPalette.accent,
      checkmarkColor: Colors.white,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminPalette.ink,
        side: const BorderSide(color: AdminPalette.line, width: 1.2),
        shape: shape,
        minimumSize: const Size(0, 42),
      ),
    ),
  );
}

class _Group extends StatelessWidget {
  const _Group(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 16, 10, 5),
    child: Text(
      label,
      style: context.textStyles.labelMedium?.copyWith(
        color: AdminPalette.faint,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count = 0,
    this.liveDot = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int count;
  final bool liveDot;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AdminPalette.accent : AdminPalette.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? AdminPalette.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? AdminPalette.accent : AdminPalette.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AdminPalette.card
                          : AdminPalette.badSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$count',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: selected
                            ? AdminPalette.accent
                            : AdminPalette.bad,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (liveDot)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AdminPalette.bad,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
