import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/mode_switch.dart';
import 'package:book_marketplace/app/router/nav_overlay.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/router/sidebar.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';

/// Theme riêng của khu đấu giá: luôn tối, đỏ LIVE + vàng đồng (không theo chế độ sáng/tối của máy).
final ThemeData _auctionTheme = AppTheme.auction();

/// Bọc một cây widget bằng theme khu đấu giá (dùng cho khung đấu giá và phòng live).
class AuctionTheme extends StatelessWidget {
  const AuctionTheme({super.key, required this.child});

  final Widget child;

  @override
  // Nền tối: biểu tượng thanh trạng thái (giờ, pin, sóng) phải sáng.
  Widget build(BuildContext context) => Theme(
    data: _auctionTheme,
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AmbientBackground(child: child),
    ),
  );
}

/// Khung khu đấu giá: một giao diện riêng, tách hẳn khỏi khu mua sách (xem `app_shell.dart`).
/// Điều hướng là một nút kính ở góc dưới (xem [NavOverlay]); bấm vào thì sidebar tối trượt ra
/// (Sàn · Lịch · Của tôi · Kết quả, tài khoản ở đáy). Công tắc [ModeSwitch] ở đầu sidebar và đầu trang gốc.
class AuctionShell extends ConsumerWidget {
  const AuctionShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int i) => navigationShell.goBranch(
    i,
    initialLocation: i == navigationShell.currentIndex,
  );

  static const _roots = {
    Routes.auctions,
    Routes.auctionSchedule,
    Routes.myAuctions,
    Routes.auctionResults,
    Routes.auctionAccount,
  };

  static const _icons = [
    Icons.gavel_rounded,
    Icons.event_rounded,
    Icons.confirmation_number_rounded,
    Icons.emoji_events_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuctionTheme(
      child: Builder(
        builder: (context) {
          final loc = GoRouterState.of(context).uri.path;
          return Scaffold(
            body: NavOverlay(
              icon: _icons[navigationShell.currentIndex],
              showButton: !context.windowSize.isCompact || _roots.contains(loc),
              panel: _AuctionSidebar(
                index: navigationShell.currentIndex,
                onBranch: _goBranch,
              ),
              child: navigationShell,
            ),
          );
        },
      ),
    );
  }
}

/// Số phiên đang LIVE (huy hiệu đỏ trên mục "Sàn").
final _liveCountProvider = Provider<int>((ref) {
  final sessions = ref.watch(auctionSessionsProvider).value ?? const [];
  return sessions.where((s) => s.isLive).length;
});

class _AuctionSidebar extends ConsumerWidget {
  const _AuctionSidebar({required this.index, required this.onBranch});

  final int index;
  final ValueChanged<int> onBranch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionControllerProvider);
    final live = ref.watch(_liveCountProvider);

    return SidebarPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 14, 10),
            child: Text(
              l10n.auctionAppTitle,
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontFamily: AppFonts.serif,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: ModeSwitch(mode: AppMode.auction),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                SidebarItem(
                  Icons.gavel_rounded,
                  l10n.auctionNavFloor,
                  selected: index == 0,
                  count: live,
                  onTap: () => onBranch(0),
                ),
                SidebarItem(
                  Icons.event_rounded,
                  l10n.auctionNavSchedule,
                  selected: index == 1,
                  onTap: () => onBranch(1),
                ),
                SidebarItem(
                  Icons.confirmation_number_outlined,
                  l10n.auctionNavMine,
                  selected: index == 2,
                  onTap: () => onBranch(2),
                ),
                SidebarItem(
                  Icons.emoji_events_outlined,
                  l10n.auctionNavResults,
                  selected: index == 3,
                  onTap: () => onBranch(3),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: session.isSignedIn
                ? SidebarItem.user(
                    context,
                    name: session.user!.fullName,
                    selected: index == 4,
                    onTap: () => onBranch(4),
                  )
                : FilledButton(
                    onPressed: () => context.go(Routes.login),
                    child: Text(l10n.login),
                  ),
          ),
        ],
      ),
    );
  }
}
