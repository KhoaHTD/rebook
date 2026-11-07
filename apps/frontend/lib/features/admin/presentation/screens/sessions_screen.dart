import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/auth_user.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/core/utils/input_rules.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/adaptive_tile.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Danh sách phiên đấu giá (mọi trạng thái, kể cả nháp) (SRS 7.2).
class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sep = context.appColors.separator;
    final list = ref.watch(adminSessionsProvider);
    // Staff chỉ giám sát phiên đang chạy; tạo / sửa phiên là việc của Admin.
    final isAdmin = ref.watch(currentUserProvider)?.role == AuthRole.admin;
    // watch giữ notifier sống trong lúc đang gọi API (mở phiên).
    final busy = ref.watch(adminActionsProvider).isLoading;

    Future<void> cancelSession(String id) async {
      final reason = await showTextSheet(
        context,
        title: l10n.admSessionCancelTitle,
        label: l10n.decisionNote,
        lines: 3,
        rule: Rules.reason,
      );
      if (reason == null) return;
      await ref.read(adminActionsProvider.notifier).run(
        (r) => r.cancelSession(id, reason),
        [DataArea.auctions, DataArea.wallet],
      );
      if (!context.mounted) return;
      final error = ref.read(adminActionsProvider).error;
      if (error != null) {
        showErrorSnack(context, error);
      } else {
        showInfoSnack(context, l10n.admSessionCancelled);
      }
    }

    Future<void> startNow(String id) async {
      final ok = await confirmDialog(context, l10n.admSessionStartQuestion);
      if (!ok) return;
      await ref.read(adminActionsProvider.notifier).run((r) => r.startNow(id), [
        DataArea.auctions,
      ]);
      if (!context.mounted) return;
      final error = ref.read(adminActionsProvider).error;
      if (error != null) {
        showErrorSnack(context, error);
      } else {
        showInfoSnack(context, l10n.admSessionStarted);
      }
    }

    return AppPage(
      title: l10n.navSessions,
      showBack: false,
      onRefresh: () => ref.refresh(adminSessionsProvider.future),
      actions: [
        if (isAdmin)
          HeaderAction(
            icon: Icons.add_rounded,
            label: l10n.newSession,
            onPressed: () => context.go(AdminRoutes.newSession),
          ),
      ],
      children: [
        AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(adminSessionsProvider),
          data: (items) => items.isEmpty
              ? EmptyState(icon: Icons.gavel_rounded, title: l10n.noSessions)
              : InfoPanel(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    children: [
                      for (final (i, s) in items.indexed) ...[
                        if (i > 0) Divider(height: 1, indent: 16, color: sep),
                        AdaptiveTile(
                          onTap: () => context.go(AdminRoutes.session(s.id)),
                          title: Text(s.title),
                          subtitle: Text(
                            [
                              formatDateTime(s.startAt),
                              l10n.lotsCount(s.lotCount),
                              l10n.registeredCount(s.registeredCount),
                            ].join(' · '),
                          ),
                          trailing: Wrap(
                            spacing: AppSpacing.sm,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              StatusPill(
                                s.status.label(l10n),
                                tone: s.status.tone,
                              ),
                              if (s.isLive)
                                TextButton(
                                  onPressed: () =>
                                      context.go(AdminRoutes.monitor(s.id)),
                                  child: Text(l10n.monitor),
                                ),
                              if (isAdmin &&
                                  (s.status == SessionStatus.draft ||
                                      s.status == SessionStatus.published ||
                                      s.status == SessionStatus.postponed ||
                                      s.status == SessionStatus.confirmed))
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () => cancelSession(s.id),
                                  child: Text(l10n.admSessionCancel),
                                ),
                              if (isAdmin &&
                                  (s.status == SessionStatus.published ||
                                      s.status == SessionStatus.confirmed))
                                TextButton(
                                  onPressed: busy ? null : () => startNow(s.id),
                                  child: Text(l10n.admSessionStartNow),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
