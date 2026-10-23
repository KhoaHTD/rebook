import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Thông báo: đơn hàng, nhắc phiên, bị trả giá cao hơn, thắng đấu giá, ký gửi (SRS 3 — FCM + lịch sử).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(NotificationType t) => switch (t) {
    NotificationType.order => Icons.receipt_long_outlined,
    NotificationType.auctionReminder => Icons.alarm_rounded,
    NotificationType.outbid => Icons.trending_up_rounded,
    NotificationType.auctionWon => Icons.emoji_events_outlined,
    _ => Icons.notifications_none_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final list = ref.watch(notificationsProvider);
    final actions = ref.read(notificationActionsProvider.notifier);
    final hasUnread = ref.watch(unreadCountProvider) > 0;

    return AppPage(
      title: l10n.notificationsTitle,
      onRefresh: () => ref.refresh(notificationsProvider.future),
      actions: [
        if (hasUnread)
          TextButton(
            onPressed: () => actions.markRead(null),
            child: Text(l10n.markAllRead),
          ),
      ],
      children: [
        AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(notificationsProvider),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.notifications_none_rounded,
                title: l10n.noNotifications,
                message: l10n.noNotificationsHint,
              );
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  for (final n in items)
                    InkWell(
                      borderRadius: AppRadius.card,
                      onTap: () async {
                        if (!n.isRead) await actions.markRead(n.id);
                        if (n.link != null && context.mounted) {
                          context.go(n.link!);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: c.fill,
                              child: Icon(_icon(n.type), size: 18),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: context.textStyles.titleSmall
                                        ?.copyWith(
                                          fontWeight: n.isRead
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    n.body,
                                    style: context.textStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatDateTime(n.createdAt),
                                    style: context.textStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (!n.isRead)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 8),
                                child: CircleAvatar(
                                  radius: 4,
                                  backgroundColor: c.info,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
