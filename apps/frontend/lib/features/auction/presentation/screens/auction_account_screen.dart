import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/features/auction/presentation/providers/second_chance_providers.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Hồ sơ trong khu đấu giá: ví cọc (khả dụng / đang giữ), lô đã thắng, phiên đã đăng ký + số bài, lịch sử trả giá,
/// lô đang theo dõi. Hồ sơ cá nhân, địa chỉ, thông báo, cài đặt dùng chung với khu mua sách (bấm vào sẽ sang khung đó).
class AuctionAccountScreen extends ConsumerWidget {
  const AuctionAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final user = ref.watch(sessionControllerProvider).user;
    final wallet = ref.watch(auctionWalletProvider).value;
    final offers = ref.watch(pendingOfferCountProvider);

    Widget row(
      IconData icon,
      String label,
      VoidCallback onTap, {
      Color? color,
    }) => ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: color == null ? null : TextStyle(color: color)),
      trailing: color == null
          ? Icon(Icons.chevron_right_rounded, color: c.tertiaryText)
          : null,
      onTap: onTap,
    );

    return AppPage(
      title: l10n.auctionAccountTitle,
      showBack: false,
      onRefresh: () => ref.refresh(auctionWalletProvider.future),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: c.tintSoft,
                      child: Text(
                        user.fullName.characters.first.toUpperCase(),
                        style: text.headlineSmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName, style: text.headlineSmall),
                          Text(user.email, style: text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.xl),
              Glass(
                blur: false,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: _Money(
                        label: l10n.auctionAccountAvailable,
                        value: wallet == null
                            ? '—'
                            : formatVnd(wallet.available),
                        color: c.tint,
                      ),
                    ),
                    Expanded(
                      child: _Money(
                        label: l10n.auctionAccountHeld,
                        value: wallet == null ? '—' : formatVnd(wallet.held),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Glass(
                blur: false,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    row(
                      Icons.account_balance_wallet_outlined,
                      l10n.auctionWalletTitle,
                      () => context.go(Routes.auctionWallet),
                    ),
                    row(
                      Icons.emoji_events_outlined,
                      l10n.wonLots,
                      () => context.go(Routes.auctionOrders),
                    ),
                    row(
                      Icons.confirmation_number_outlined,
                      l10n.auctionAccountRegistrations,
                      () => context.go(Routes.myAuctions),
                    ),
                    row(
                      Icons.gavel_rounded,
                      l10n.myBids,
                      () => context.go(Routes.auctionBids),
                    ),
                    row(
                      Icons.local_offer_outlined,
                      offers > 0
                          ? '${l10n.auctionAccountOffers} ($offers)'
                          : l10n.auctionAccountOffers,
                      () => context.go(Routes.auctionOffers),
                    ),
                    row(
                      Icons.bookmark_border_rounded,
                      l10n.mineWatching,
                      () => context.go(Routes.myAuctions),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Glass(
                blur: false,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    row(
                      Icons.person_outline_rounded,
                      l10n.profile,
                      () => context.go(Routes.profile),
                    ),
                    row(
                      Icons.location_on_outlined,
                      l10n.addresses,
                      () => context.go(Routes.addresses),
                    ),
                    row(
                      Icons.notifications_none_rounded,
                      l10n.navNotifications,
                      () => context.go(Routes.notifications),
                    ),
                    row(
                      Icons.settings_outlined,
                      l10n.settings,
                      () => context.go(Routes.settings),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Glass(
                blur: false,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    row(
                      Icons.menu_book_rounded,
                      l10n.modeBackToBooks,
                      () => context.go(Routes.home),
                    ),
                    row(
                      Icons.logout_rounded,
                      l10n.logout,
                      () => ref
                          .read(sessionControllerProvider.notifier)
                          .signOut(),
                      color: c.live,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ],
    );
  }
}

class _Money extends StatelessWidget {
  const _Money({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.labelMedium),
        const SizedBox(height: 2),
        Text(
          value,
          style: text.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
