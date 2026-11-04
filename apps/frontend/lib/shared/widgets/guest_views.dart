import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/login_prompt.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Tên mục để nói "đăng nhập để xem …" theo đường dẫn khách đang mở.
String _feature(AppLocalizations l10n, String path) {
  bool under(String p) => path == p || path.startsWith('$p/');
  if (under(Routes.cart) || under('/home/payments')) return l10n.navCart;
  if (under(Routes.notifications)) return l10n.navNotifications;
  if (under(Routes.orders)) return l10n.myOrders;
  if (under(Routes.wallet)) return l10n.wallet;
  if (under(Routes.favorites)) return l10n.favTitle;
  if (under(Routes.addresses)) return l10n.addresses;
  if (under(Routes.profile)) return l10n.profile;
  if (under(Routes.seller)) return l10n.sellerHub;
  if (under(Routes.consignments)) return l10n.myConsignments;
  return l10n.gateFeatureGeneric;
}

/// Khách mở mục cần đăng nhập (giỏ hàng, thông báo, đơn hàng…): khung vẫn còn, nội dung là lời mời đăng nhập
/// thay vì bị đẩy sang trang đăng nhập.
class GuestGate extends StatelessWidget {
  const GuestGate({super.key, required this.location});

  /// Đường dẫn khách đang mở (để quay lại sau khi đăng nhập).
  final String location;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final feature = _feature(l10n, location);
    return AppPage(
      title: feature,
      showBack: false,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: InfoPanel(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: c.tintSoft,
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: c.tint,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.loginRequiredTitle,
                    textAlign: TextAlign.center,
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.gateBody(feature.toLowerCase()),
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: c.secondaryText),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () => context.go(loginPath(location)),
                    child: Text(l10n.login),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => context.go(Routes.register),
                    child: Text(l10n.register),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Mục Tài khoản của khách: chỉ có "Tài khoản khách", lời mời đăng nhập / đăng ký và Cài đặt.
class GuestAccountView extends StatelessWidget {
  const GuestAccountView({super.key, this.auction = false});

  /// Bản trong khu đấu giá (đổi tiêu đề).
  final bool auction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    return AppPage(
      title: auction ? l10n.auctionAccountTitle : l10n.accountTitle,
      showBack: false,
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
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 32,
                      color: c.secondaryText,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.guestAccountTitle, style: text.headlineSmall),
                        Text(l10n.guestAccountBody, style: text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => context.go(loginPath(Routes.account)),
                child: Text(l10n.login),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => context.go(Routes.register),
                child: Text(l10n.register),
              ),
              const SizedBox(height: AppSpacing.xl),
              InfoPanel(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(l10n.settings),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: c.tertiaryText,
                  ),
                  onTap: () => context.go(Routes.settings),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
