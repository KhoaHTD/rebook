import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/staff/presentation/providers/staff_providers.dart';
import 'package:book_marketplace/features/staff/presentation/widgets/consignment_row.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Hàng đợi ký gửi: sơ duyệt (48h) và mở phiếu kiểm định cho sách đã nhận (SRS 6.1, 6.2).
class StaffConsignmentsScreen extends ConsumerStatefulWidget {
  const StaffConsignmentsScreen({super.key});

  @override
  ConsumerState<StaffConsignmentsScreen> createState() =>
      _StaffConsignmentsScreenState();
}

class _StaffConsignmentsScreenState
    extends ConsumerState<StaffConsignmentsScreen> {
  ConsignmentStatus? _status = ConsignmentStatus.submitted;

  Future<void> _preReview(String id, {required bool approve}) async {
    final l10n = context.l10n;
    String? reason;
    if (!approve) {
      reason = await showCancelSheet(
        context,
        l10n.preReviewRejectReasons,
        title: l10n.rejectReasonTitle,
      );
      if (reason == null) return;
    }
    await ref
        .read(staffActionsProvider.notifier)
        .preReview(id, approve: approve, reason: reason);
    if (!mounted) return;
    final error = ref.read(staffActionsProvider).error;
    if (error != null) showErrorSnack(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final list = ref.watch(staffConsignmentsProvider);
    final busy = ref.watch(staffActionsProvider).isLoading;

    return AppPage(
      title: l10n.navConsignments,
      showBack: false,
      onRefresh: () => ref.refresh(staffConsignmentsProvider.future),
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in [
              ConsignmentStatus.submitted,
              ConsignmentStatus.received,
              ConsignmentStatus.inspected,
              ConsignmentStatus.accepted,
              null,
            ])
              ChoiceChip(
                label: Text(s == null ? l10n.ordersAll : s.label(l10n)),
                selected: _status == s,
                onSelected: (_) => setState(() => _status = s),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(staffConsignmentsProvider),
          data: (all) {
            final items = all
                .where((c) => _status == null || c.status == _status)
                .toList();
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.task_alt_rounded,
                title: l10n.nothingToDo,
              );
            }
            return Column(
              children: [
                for (final c in items)
                  ConsignmentRow(
                    consignment: c,
                    onTap: () => context.go(AdminRoutes.consignment(c.id)),
                    trailing: [
                      if (c.status == ConsignmentStatus.submitted) ...[
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () => _preReview(c.id, approve: false),
                          child: Text(l10n.reject),
                        ),
                        FilledButton(
                          onPressed: busy
                              ? null
                              : () => _preReview(c.id, approve: true),
                          child: Text(l10n.approve),
                        ),
                      ],
                      if (c.status == ConsignmentStatus.received)
                        FilledButton(
                          onPressed: () =>
                              context.go(AdminRoutes.consignment(c.id)),
                          child: Text(l10n.inspect),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
