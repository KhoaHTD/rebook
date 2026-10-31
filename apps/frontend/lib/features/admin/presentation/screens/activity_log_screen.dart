import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Nhật ký hoạt động: mọi thao tác của Admin để tra cứu (SRS 8.1).
class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  IconData _icon(AdminAction a) => switch (a) {
    AdminAction.listingApproved => Icons.check_circle_outline_rounded,
    AdminAction.listingRejected => Icons.cancel_outlined,
    AdminAction.userLocked => Icons.lock_outline_rounded,
    AdminAction.userUnlocked => Icons.lock_open_rounded,
    AdminAction.roleChanged => Icons.manage_accounts_outlined,
    AdminAction.auctionBanLifted => Icons.gavel_rounded,
    AdminAction.shopMarkedTrusted => Icons.verified_outlined,
    AdminAction.withdrawalCompleted => Icons.account_balance_outlined,
    AdminAction.configChanged => Icons.tune_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final logs = ref.watch(adminActivityLogsProvider);
    return AppPage(
      title: l10n.admActivityTitle,
      showBack: false,
      onRefresh: () => ref.refresh(adminActivityLogsProvider.future),
      children: [
        AsyncValueView(
          value: logs,
          onRetry: () => ref.invalidate(adminActivityLogsProvider),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.history_rounded,
                  title: l10n.admActivityEmpty,
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: InfoPanel(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      children: [
                        for (final (i, e) in items.indexed) ...[
                          if (i > 0)
                            Divider(height: 1, indent: 16, color: c.separator),
                          ListTile(
                            leading: Icon(_icon(e.action)),
                            title: Text(e.action.label(l10n)),
                            subtitle: Text(
                              [
                                e.adminName,
                                if (e.target != null) e.target!,
                                if (e.note != null)
                                  int.tryParse(e.note!) == null
                                      ? e.note!
                                      : formatVnd(int.parse(e.note!)),
                              ].join(' · '),
                            ),
                            trailing: Text(
                              formatDateTime(e.createdAt),
                              style: text.bodySmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
