import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/account/presentation/providers/account_providers.dart';
import 'package:book_marketplace/shared/widgets/app_image.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Tài khoản: lối vào mua sắm, bán sách (shop, ký gửi), hồ sơ, cài đặt, đăng xuất.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final user = ref.watch(sessionControllerProvider).user;
    if (user == null) return const SizedBox.shrink();

    Widget group(String title, List<Widget> rows) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
            child: Text(
              title,
              style: context.textStyles.titleSmall?.copyWith(
                color: c.secondaryText,
              ),
            ),
          ),
          InfoPanel(
            padding: EdgeInsets.zero,
            child: Column(children: rows),
          ),
        ],
      ),
    );
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
      title: l10n.accountTitle,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: c.fill,
                    child: user.avatarUrl == null
                        ? Text(
                            user.fullName.characters.first.toUpperCase(),
                            style: context.textStyles.headlineSmall,
                          )
                        : ClipOval(
                            child: SizedBox.square(
                              dimension: 64,
                              child: AppImage(user.avatarUrl!),
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: context.textStyles.headlineSmall,
                        ),
                        Text(user.email, style: context.textStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              group(l10n.sectionBuying, [
                row(
                  Icons.receipt_long_outlined,
                  l10n.myOrders,
                  () => context.go(Routes.orders),
                ),
                row(
                  Icons.account_balance_wallet_outlined,
                  l10n.wallet,
                  () => context.go(Routes.wallet),
                ),
                row(
                  Icons.location_on_outlined,
                  l10n.addresses,
                  () => context.go(Routes.addresses),
                ),
              ]),
              group(l10n.sectionSelling, [
                user.hasShop
                    ? row(
                        Icons.storefront_outlined,
                        l10n.sellerHub,
                        () => context.go(Routes.seller),
                      )
                    : row(
                        Icons.add_business_outlined,
                        l10n.openShopCta,
                        () => context.go(Routes.openShop),
                      ),
                row(
                  Icons.inventory_2_outlined,
                  l10n.myConsignments,
                  () => context.go(Routes.consignments),
                ),
              ]),
              group(l10n.sectionAccount, [
                row(
                  Icons.person_outline_rounded,
                  l10n.profile,
                  () => context.go(Routes.profile),
                ),
                row(
                  Icons.settings_outlined,
                  l10n.settings,
                  () => context.go(Routes.settings),
                ),
                row(Icons.logout_rounded, l10n.logout, () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (d) => AlertDialog(
                      content: Text(l10n.logoutConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(d, false),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(d, true),
                          child: Text(l10n.logout),
                        ),
                      ],
                    ),
                  );
                  if (ok ?? false) {
                    await ref
                        .read(accountControllerProvider.notifier)
                        .signOut();
                  }
                }, color: c.live),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}
